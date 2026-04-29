package com.bildunya.service;

import com.bildunya.dto.ChatMessageDto;
import com.bildunya.dto.SendChatMessageRequest;
import com.bildunya.entity.ChatMessage;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.repository.ChatMessageRepository;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
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
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatMessageDto sendMessage(String senderUsername, SendChatMessageRequest request) {
        User sender = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));

        User receiver = userRepository.findByUsername(request.getReceiverUsername())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver not found"));

        ChatMessage message = ChatMessage.builder()
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

    @Transactional(readOnly = true)
    public Page<ChatMessageDto> getConversation(String username, String otherUsername, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User other = userRepository.findByUsername(otherUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return chatMessageRepository.findConversation(user.getId(), other.getId(), pageable)
                .map(this::mapToDto);
    }

    public int markConversationAsRead(String username, String otherUsername) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User other = userRepository.findByUsername(otherUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return chatMessageRepository.markConversationAsRead(user.getId(), other.getId());
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

