package com.bildunya.service;

import com.bildunya.dto.ChatMessageDto;
import com.bildunya.dto.SendChatMessageRequest;
import com.bildunya.entity.ChatConversation;
import com.bildunya.entity.ChatMessage;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.repository.ChatConversationRepository;
import com.bildunya.repository.ChatMessageRepository;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
@Transactional
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final ChatConversationRepository chatConversationRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatMessageDto sendMessage(String senderUsername, SendChatMessageRequest request) {
        User sender = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));

        User receiver = userRepository.findByUsername(request.getReceiverUsername())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver not found"));

        if (sender.getId() != null && sender.getId().equals(receiver.getId())) {
            throw new IllegalArgumentException("Cannot send message to yourself");
        }

        ChatConversation conversation = getOrCreateConversation(sender, receiver);

        ChatMessage message = ChatMessage.builder()
                .conversation(conversation)
                .sender(sender)
                .receiver(receiver)
                .text(request.getText())
                .isRead(false)
                .build();

        message = chatMessageRepository.save(message);
        ChatMessageDto dto = mapToDto(message);

        messagingTemplate.convertAndSend("/topic/chat/" + receiver.getUsername(), dto);
        messagingTemplate.convertAndSend("/topic/chat/" + sender.getUsername(), dto);

        return dto;
    }

    public Page<ChatMessageDto> getConversation(String username, String otherUsername, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User other = userRepository.findByUsername(otherUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (user.getId() != null && user.getId().equals(other.getId())) {
            return Page.empty(pageable);
        }

        ChatConversation conversation = getOrCreateConversation(user, other);

        return chatMessageRepository.findByConversationId(conversation.getId(), pageable)
                .map(this::mapToDto);
    }

    public int markConversationAsRead(String username, String otherUsername) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User other = userRepository.findByUsername(otherUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (user.getId() != null && user.getId().equals(other.getId())) {
            return 0;
        }

        return chatMessageRepository.markConversationAsRead(user.getId(), other.getId());
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

    private ChatMessageDto mapToDto(ChatMessage message) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

        return ChatMessageDto.builder()
                .id(message.getId())
                .senderUsername(message.getSender() != null ? message.getSender().getUsername() : null)
                .receiverUsername(message.getReceiver() != null ? message.getReceiver().getUsername() : null)
                .text(message.getText())
                .isRead(message.getIsRead())
                .createdAt(message.getCreatedAt() != null ? message.getCreatedAt().format(formatter) : null)
                .build();
    }
}
