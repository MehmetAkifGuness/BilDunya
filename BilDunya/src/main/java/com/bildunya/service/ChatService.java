package com.bildunya.service;

import com.bildunya.dto.ChatMessageDto;
import com.bildunya.dto.ConversationDto;
import com.bildunya.dto.ConversationSummaryDto;
import com.bildunya.dto.CreateConversationRequest;
import com.bildunya.dto.SendChatMessageRequest;
import com.bildunya.dto.SendMessageRequest;
import com.bildunya.entity.ChatConversation;
import com.bildunya.entity.ChatMessage;
import com.bildunya.entity.Content;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.exception.UnauthorizedException;
import com.bildunya.repository.ChatConversationRepository;
import com.bildunya.repository.ChatMessageRepository;
import com.bildunya.repository.ContentRepository;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.sql.Timestamp;
import java.util.Objects;

@Service
@RequiredArgsConstructor
@Transactional
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final ChatConversationRepository chatConversationRepository;
    private final UserRepository userRepository;
    private final ContentRepository contentRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatMessageDto sendMessage(String senderUsername, SendChatMessageRequest request) {
        User sender = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));

        User receiver = userRepository.findByUsername(request.getReceiverUsername())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver not found"));

        ChatConversation conversation = getOrCreateConversation(sender, receiver);

        boolean isRead = sender.getId() != null && sender.getId().equals(receiver.getId());
        ChatMessage message = ChatMessage.builder()
                .conversation(conversation)
                .sender(sender)
                .receiver(receiver)
                .text(request.getText())
                .isRead(isRead)
                .build();

        message = chatMessageRepository.save(message);
        ChatMessageDto dto = mapToDto(message);

        messagingTemplate.convertAndSend("/topic/chat/" + receiver.getUsername(), dto);
        if (!Objects.equals(sender.getUsername(), receiver.getUsername())) {
            messagingTemplate.convertAndSend("/topic/chat/" + sender.getUsername(), dto);
        }

        return dto;
    }

    public Page<ChatMessageDto> getConversation(String username, String otherUsername, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User other = userRepository.findByUsername(otherUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        ChatConversation conversation = getOrCreateConversation(user, other);

        return chatMessageRepository.findByConversationId(conversation.getId(), pageable)
                .map(this::mapToDto);
    }

    public int markConversationAsRead(String username, String otherUsername) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User other = userRepository.findByUsername(otherUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return chatMessageRepository.markConversationAsRead(user.getId(), other.getId());
    }

    public Page<ConversationSummaryDto> getConversations(String username, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
        Page<ConversationSummaryDto> page = chatConversationRepository.findConversationSummaries(user.getId(), pageable)
                .map(p -> ConversationSummaryDto.builder()
                        .id(toLongOrNull(p.getConversationId()))
                        .otherUserId(toLongOrNull(p.getOtherUserId()))
                        .otherUsername(p.getOtherUsername())
                        .otherFullName(p.getOtherFullName())
                        .lastMessage(p.getLastMessageText())
                        .lastMessageAt(formatTemporalOrNull(p.getLastMessageCreatedAt(), formatter))
                        .unreadCount(toLongOrDefault(p.getUnreadCount(), 0L))
                        .relatedContentId(toLongOrNull(p.getRelatedContentId()))
                        .relatedContentLabel(trimToNull(p.getRelatedContentLabel()))
                        .build());
        return page;
    }

    public ConversationDto openConversation(String username, CreateConversationRequest request) {
        String otherUsername = request.getOtherUsername();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User other = userRepository.findByUsername(otherUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        ChatConversation conversation = getOrCreateConversation(user, other);

        Long relatedContentId = request.getRelatedContentId();
        if (relatedContentId != null && relatedContentId > 0) {
            contentRepository.findById(relatedContentId)
                    .filter(c -> !Boolean.TRUE.equals(c.getIsDeleted()))
                    .ifPresent(ignored -> {
                        conversation.setRelatedContentId(relatedContentId);
                        chatConversationRepository.save(conversation);
                    });
        }

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

        User otherSide = resolveOtherSide(conversation, user);
        Long rcId = conversation.getRelatedContentId();
        String rcLabel = resolveRelatedContentLabel(rcId);
        return ConversationDto.builder()
                .id(conversation.getId())
                .user1Id(conversation.getUser1() != null ? conversation.getUser1().getId() : null)
                .user2Id(conversation.getUser2() != null ? conversation.getUser2().getId() : null)
                .otherUserId(otherSide != null ? otherSide.getId() : null)
                .otherUsername(otherSide != null ? otherSide.getUsername() : null)
                .otherFullName(otherSide != null ? otherSide.getFullName() : null)
                .createdAt(formatOrNull(conversation.getCreatedAt(), formatter))
                .relatedContentId(rcId)
                .relatedContentLabel(rcLabel)
                .build();
    }

    public Page<ChatMessageDto> getConversationMessages(String username, Long conversationId, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        ChatConversation conversation = chatConversationRepository.findById(conversationId)
                .filter(c -> !Boolean.TRUE.equals(c.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        requireParticipant(conversation, user);

        return chatMessageRepository.findByConversationId(conversation.getId(), pageable)
                .map(this::mapToDto);
    }

    public ChatMessageDto sendMessageToConversation(String senderUsername, SendMessageRequest request) {
        User sender = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));

        ChatConversation conversation = chatConversationRepository.findById(request.getConversationId())
                .filter(c -> !Boolean.TRUE.equals(c.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        requireParticipant(conversation, sender);

        User receiver = resolveOtherSide(conversation, sender);
        if (receiver == null) {
            throw new IllegalStateException("Conversation participant missing");
        }

        boolean isRead = sender.getId() != null && sender.getId().equals(receiver.getId());
        ChatMessage message = ChatMessage.builder()
                .conversation(conversation)
                .sender(sender)
                .receiver(receiver)
                .text(request.getContent())
                .isRead(isRead)
                .build();

        message = chatMessageRepository.save(message);
        ChatMessageDto dto = mapToDto(message);

        messagingTemplate.convertAndSend("/topic/chat/" + receiver.getUsername(), dto);
        if (!Objects.equals(sender.getUsername(), receiver.getUsername())) {
            messagingTemplate.convertAndSend("/topic/chat/" + sender.getUsername(), dto);
        }
        return dto;
    }

    public int markConversationAsRead(String username, Long conversationId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        ChatConversation conversation = chatConversationRepository.findById(conversationId)
                .filter(c -> !Boolean.TRUE.equals(c.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        requireParticipant(conversation, user);
        if (user.getId() == null) return 0;
        return chatMessageRepository.markConversationAsReadByConversationId(conversationId, user.getId());
    }

    private ChatConversation getOrCreateConversation(User a, User b) {
        if (a.getId() == null || b.getId() == null) {
            throw new IllegalStateException("Users must be persisted before starting a conversation");
        }

        User user1 = a.getId() < b.getId() ? a : b;
        User user2 = a.getId() < b.getId() ? b : a;

        ChatConversation conversation = chatConversationRepository
                .findByUser1_IdAndUser2_IdAndIsDeletedFalse(user1.getId(), user2.getId())
                .orElseGet(() -> {
                    try {
                        return chatConversationRepository.saveAndFlush(
                                ChatConversation.builder()
                                        .user1(user1)
                                        .user2(user2)
                                        .build()
                        );
                    } catch (DataIntegrityViolationException e) {
                        return chatConversationRepository
                                .findByUser1_IdAndUser2_IdAndIsDeletedFalse(user1.getId(), user2.getId())
                                .orElseThrow(() -> e);
                    }
                });

        chatMessageRepository.attachConversationIdToExistingMessages(conversation.getId(), user1.getId(), user2.getId());
        return conversation;
    }

    private void requireParticipant(ChatConversation conversation, User user) {
        Long uid = user.getId();
        if (uid == null) {
            throw new IllegalStateException("User must be persisted");
        }
        Long user1Id = conversation.getUser1() != null ? conversation.getUser1().getId() : null;
        Long user2Id = conversation.getUser2() != null ? conversation.getUser2().getId() : null;
        if (!uid.equals(user1Id) && !uid.equals(user2Id)) {
            throw new UnauthorizedException("You are not a participant in this conversation");
        }
    }

    private User resolveOtherSide(ChatConversation conversation, User me) {
        if (me.getId() == null) return null;
        User u1 = conversation.getUser1();
        User u2 = conversation.getUser2();
        if (u1 != null && me.getId().equals(u1.getId())) return u2 != null ? u2 : u1;
        if (u2 != null && me.getId().equals(u2.getId())) return u1 != null ? u1 : u2;
        return null;
    }

    private static String formatOrNull(LocalDateTime dt, DateTimeFormatter formatter) {
        return dt != null ? dt.format(formatter) : null;
    }

    private static String formatTemporalOrNull(Object temporal, DateTimeFormatter formatter) {
        if (temporal == null) return null;
        if (temporal instanceof LocalDateTime dt) {
            return dt.format(formatter);
        }
        if (temporal instanceof Instant instant) {
            return LocalDateTime.ofInstant(instant, ZoneId.systemDefault()).format(formatter);
        }
        if (temporal instanceof OffsetDateTime odt) {
            return odt.toLocalDateTime().format(formatter);
        }
        if (temporal instanceof ZonedDateTime zdt) {
            return zdt.toLocalDateTime().format(formatter);
        }
        if (temporal instanceof Timestamp ts) {
            LocalDateTime dt = ts.toLocalDateTime();
            return dt != null ? dt.format(formatter) : null;
        }
        if (temporal instanceof java.util.Date d) {
            LocalDateTime dt = new Timestamp(d.getTime()).toLocalDateTime();
            return dt != null ? dt.format(formatter) : null;
        }
        return null;
    }

    private static Long toLongOrNull(Number value) {
        return value != null ? value.longValue() : null;
    }

    private static Long toLongOrDefault(Number value, long defaultValue) {
        return value != null ? value.longValue() : defaultValue;
    }

    private String resolveRelatedContentLabel(Long contentId) {
        if (contentId == null || contentId <= 0) {
            return null;
        }
        return contentRepository.findById(contentId)
                .filter(c -> !Boolean.TRUE.equals(c.getIsDeleted()))
                .map(ChatService::buildRelatedContentLabel)
                .orElse(null);
    }

    private static String buildRelatedContentLabel(Content c) {
        String loc = c.getLocationName();
        if (loc != null && !loc.isBlank()) {
            return loc.trim();
        }
        if (c.getDescription() == null) {
            return null;
        }
        String d = c.getDescription().trim();
        if (d.isEmpty()) {
            return null;
        }
        return d.length() > 100 ? d.substring(0, 100) : d;
    }

    private static String trimToNull(String s) {
        if (s == null) {
            return null;
        }
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    private ChatMessageDto mapToDto(ChatMessage message) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

        return ChatMessageDto.builder()
                .id(message.getId())
                .conversationId(message.getConversation() != null ? message.getConversation().getId() : null)
                .senderUsername(message.getSender() != null ? message.getSender().getUsername() : null)
                .receiverUsername(message.getReceiver() != null ? message.getReceiver().getUsername() : null)
                .text(message.getText())
                .isRead(message.getIsRead())
                .createdAt(message.getCreatedAt() != null ? message.getCreatedAt().format(formatter) : null)
                .build();
    }
}
