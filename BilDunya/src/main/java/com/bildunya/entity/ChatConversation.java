package com.bildunya.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "chat_conversations",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_chat_conversation_users", columnNames = {"user1_id", "user2_id"})
        },
        indexes = {
                @Index(name = "idx_chat_conversation_user1", columnList = "user1_id"),
                @Index(name = "idx_chat_conversation_user2", columnList = "user2_id")
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = true)
public class ChatConversation extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user1_id", nullable = false)
    private User user1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user2_id", nullable = false)
    private User user2;

    /**
     * Son / aktif bağlam: kullanıcı bu sohbeti hangi içerik (gönderi) üzerinden açtı.
     */
    @Column(name = "related_content_id")
    private Long relatedContentId;
}

