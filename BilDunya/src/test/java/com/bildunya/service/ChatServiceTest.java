package com.bildunya.service;

import com.bildunya.dto.SendChatMessageRequest;
import com.bildunya.dto.ConversationSummaryDto;
import com.bildunya.entity.ChatConversation;
import com.bildunya.entity.ChatMessage;
import com.bildunya.entity.User;
import com.bildunya.repository.ChatConversationRepository;
import com.bildunya.repository.ChatMessageRepository;
import com.bildunya.repository.ContentRepository;
import com.bildunya.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigInteger;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class ChatServiceTest {

    @Test
    void sendMessage_createsConversation_normalizesUsers_andSavesMessageWithConversation() {
        ChatMessageRepository chatMessageRepository = mock(ChatMessageRepository.class);
        ChatConversationRepository chatConversationRepository = mock(ChatConversationRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        ContentRepository contentRepository = mock(ContentRepository.class);
        SimpMessagingTemplate messagingTemplate = mock(SimpMessagingTemplate.class);

        ChatService service = new ChatService(
                chatMessageRepository,
                chatConversationRepository,
                userRepository,
                contentRepository,
                messagingTemplate
        );

        User sender = User.builder().username("A").build();
        sender.setId(42L);
        User receiver = User.builder().username("B").build();
        receiver.setId(7L);

        when(userRepository.findByUsername("A")).thenReturn(Optional.of(sender));
        when(userRepository.findByUsername("B")).thenReturn(Optional.of(receiver));

        when(chatConversationRepository.findByUser1_IdAndUser2_IdAndIsDeletedFalse(7L, 42L))
                .thenReturn(Optional.empty());

        ChatConversation created = ChatConversation.builder().user1(receiver).user2(sender).build();
        created.setId(100L);
        when(chatConversationRepository.saveAndFlush(any(ChatConversation.class))).thenReturn(created);

        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(inv -> {
            ChatMessage m = inv.getArgument(0, ChatMessage.class);
            m.setId(1L);
            return m;
        });

        SendChatMessageRequest req = new SendChatMessageRequest("B", "hello");
        service.sendMessage("A", req);

        verify(chatConversationRepository).findByUser1_IdAndUser2_IdAndIsDeletedFalse(7L, 42L);
        verify(chatConversationRepository).saveAndFlush(any(ChatConversation.class));
        verify(chatMessageRepository).attachConversationIdToExistingMessages(100L, 7L, 42L);

        ArgumentCaptor<ChatMessage> messageCaptor = ArgumentCaptor.forClass(ChatMessage.class);
        verify(chatMessageRepository).save(messageCaptor.capture());

        ChatMessage saved = messageCaptor.getValue();
        assertNotNull(saved.getConversation());
        assertEquals(100L, saved.getConversation().getId());
        assertEquals("A", saved.getSender().getUsername());
        assertEquals("B", saved.getReceiver().getUsername());
        assertEquals("hello", saved.getText());

        verify(messagingTemplate).convertAndSend(eq("/topic/chat/B"), any(Object.class));
        verify(messagingTemplate).convertAndSend(eq("/topic/chat/A"), any(Object.class));
    }

    @Test
    void getConversation_backfillsConversationIdAndFetchesByConversationId() {
        ChatMessageRepository chatMessageRepository = mock(ChatMessageRepository.class);
        ChatConversationRepository chatConversationRepository = mock(ChatConversationRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        ContentRepository contentRepository = mock(ContentRepository.class);
        SimpMessagingTemplate messagingTemplate = mock(SimpMessagingTemplate.class);

        ChatService service = new ChatService(
                chatMessageRepository,
                chatConversationRepository,
                userRepository,
                contentRepository,
                messagingTemplate
        );

        User me = User.builder().username("me").build();
        me.setId(2L);
        User other = User.builder().username("other").build();
        other.setId(9L);

        when(userRepository.findByUsername("me")).thenReturn(Optional.of(me));
        when(userRepository.findByUsername("other")).thenReturn(Optional.of(other));

        ChatConversation conv = ChatConversation.builder().user1(me).user2(other).build();
        conv.setId(555L);
        when(chatConversationRepository.findByUser1_IdAndUser2_IdAndIsDeletedFalse(2L, 9L)).thenReturn(Optional.of(conv));

        PageRequest pageable = PageRequest.of(0, 50);
        when(chatMessageRepository.findByConversationId(555L, pageable)).thenReturn(new PageImpl<>(List.of(), pageable, 0));

        Page<?> page = service.getConversation("me", "other", pageable);

        assertEquals(0, page.getTotalElements());
        verify(chatMessageRepository).attachConversationIdToExistingMessages(555L, 2L, 9L);
        verify(chatMessageRepository).findByConversationId(555L, pageable);
        verifyNoInteractions(messagingTemplate);
    }

    @Test
    void sendMessage_reusesExistingConversation_withoutCreatingDuplicates() {
        ChatMessageRepository chatMessageRepository = mock(ChatMessageRepository.class);
        ChatConversationRepository chatConversationRepository = mock(ChatConversationRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        ContentRepository contentRepository = mock(ContentRepository.class);
        SimpMessagingTemplate messagingTemplate = mock(SimpMessagingTemplate.class);

        ChatService service = new ChatService(
                chatMessageRepository,
                chatConversationRepository,
                userRepository,
                contentRepository,
                messagingTemplate
        );

        User sender = User.builder().username("A").build();
        sender.setId(1L);
        User receiver = User.builder().username("B").build();
        receiver.setId(2L);

        when(userRepository.findByUsername("A")).thenReturn(Optional.of(sender));
        when(userRepository.findByUsername("B")).thenReturn(Optional.of(receiver));

        ChatConversation existing = ChatConversation.builder().user1(sender).user2(receiver).build();
        existing.setId(77L);
        when(chatConversationRepository.findByUser1_IdAndUser2_IdAndIsDeletedFalse(1L, 2L))
                .thenReturn(Optional.of(existing));

        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(inv -> inv.getArgument(0, ChatMessage.class));

        service.sendMessage("A", new SendChatMessageRequest("B", "hi"));

        verify(chatConversationRepository).findByUser1_IdAndUser2_IdAndIsDeletedFalse(1L, 2L);
        verify(chatConversationRepository, never()).saveAndFlush(any(ChatConversation.class));
        verify(chatMessageRepository).attachConversationIdToExistingMessages(77L, 1L, 2L);
    }

    @Test
    void getConversations_handlesNumericProjectionTypes() {
        ChatMessageRepository chatMessageRepository = mock(ChatMessageRepository.class);
        ChatConversationRepository chatConversationRepository = mock(ChatConversationRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        ContentRepository contentRepository = mock(ContentRepository.class);
        SimpMessagingTemplate messagingTemplate = mock(SimpMessagingTemplate.class);

        ChatService service = new ChatService(
                chatMessageRepository,
                chatConversationRepository,
                userRepository,
                contentRepository,
                messagingTemplate
        );

        User me = User.builder().username("me").build();
        me.setId(9L);
        when(userRepository.findByUsername("me")).thenReturn(Optional.of(me));

        LocalDateTime lastAt = LocalDateTime.of(2026, 5, 4, 12, 30, 15);
        ChatConversationRepository.ConversationSummaryProjection proj =
                new ChatConversationRepository.ConversationSummaryProjection() {
                    @Override
                    public Number getConversationId() {
                        return BigInteger.valueOf(100);
                    }

                    @Override
                    public Number getOtherUserId() {
                        return BigInteger.valueOf(200);
                    }

                    @Override
                    public String getOtherUsername() {
                        return "other";
                    }

                    @Override
                    public String getOtherFullName() {
                        return "Other User";
                    }

                    @Override
                    public String getLastMessageText() {
                        return "hi";
                    }

                    @Override
                    public Object getLastMessageCreatedAt() {
                        return lastAt;
                    }

                    @Override
                    public Number getUnreadCount() {
                        return BigInteger.valueOf(3);
                    }

                    @Override
                    public Number getRelatedContentId() {
                        return BigInteger.valueOf(500);
                    }

                    @Override
                    public String getRelatedContentLabel() {
                        return "Kapadokya";
                    }

                    @Override
                    public String getLastMessageSenderUsername() {
                        return "other";
                    }
                };

        PageRequest pageable = PageRequest.of(0, 50);
        when(chatConversationRepository.findConversationSummaries(9L, pageable))
                .thenReturn(new PageImpl<>(List.of(proj), pageable, 1));

        Page<ConversationSummaryDto> page = service.getConversations("me", pageable);

        assertEquals(1, page.getTotalElements());
        ConversationSummaryDto dto = page.getContent().getFirst();
        assertEquals(100L, dto.getId());
        assertEquals(200L, dto.getOtherUserId());
        assertEquals("other", dto.getOtherUsername());
        assertEquals("Other User", dto.getOtherFullName());
        assertEquals("hi", dto.getLastMessage());
        assertEquals("2026-05-04T12:30:15", dto.getLastMessageAt());
        assertEquals(3L, dto.getUnreadCount());
        assertEquals(500L, dto.getRelatedContentId());
        assertEquals("Kapadokya", dto.getRelatedContentLabel());

        verifyNoInteractions(messagingTemplate);
    }
}
