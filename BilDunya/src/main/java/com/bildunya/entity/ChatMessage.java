package com.bildunya.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "chat_messages", indexes = {
        @Index(name = "idx_chat_conversation_created_at", columnList = "conversation_id,created_at"),
        @Index(name = "idx_chat_sender_receiver_created_at", columnList = "sender_id,receiver_id,created_at"),
        @Index(name = "idx_chat_receiver_created_at", columnList = "receiver_id,created_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = true)
public class ChatMessage extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id")
    private ChatConversation conversation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id", nullable = false)
    private User receiver;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String text;

    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;
}
