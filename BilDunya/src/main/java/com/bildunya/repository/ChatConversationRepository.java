package com.bildunya.repository;

import com.bildunya.entity.ChatConversation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ChatConversationRepository extends JpaRepository<ChatConversation, Long> {

    interface ConversationSummaryProjection {
        Long getConversationId();

        Long getOtherUserId();

        String getOtherUsername();

        String getOtherFullName();

        String getLastMessageText();

        java.time.LocalDateTime getLastMessageCreatedAt();

        Long getUnreadCount();
    }

    Optional<ChatConversation> findByUser1_IdAndUser2_IdAndIsDeletedFalse(Long user1Id, Long user2Id);

    @Query(
            value = """
                    SELECT
                        c.id AS "conversationId",
                        CASE WHEN c.user1_id = :userId THEN u2.id ELSE u1.id END AS "otherUserId",
                        CASE WHEN c.user1_id = :userId THEN u2.username ELSE u1.username END AS "otherUsername",
                        CASE WHEN c.user1_id = :userId THEN u2.full_name ELSE u1.full_name END AS "otherFullName",
                        (
                            SELECT m.text
                            FROM chat_messages m
                            WHERE m.is_deleted = false AND m.conversation_id = c.id
                            ORDER BY m.created_at DESC
                            LIMIT 1
                        ) AS "lastMessageText",
                        (
                            SELECT m.created_at
                            FROM chat_messages m
                            WHERE m.is_deleted = false AND m.conversation_id = c.id
                            ORDER BY m.created_at DESC
                            LIMIT 1
                        ) AS "lastMessageCreatedAt",
                        (
                            SELECT COUNT(*)
                            FROM chat_messages m
                            WHERE m.is_deleted = false
                              AND m.conversation_id = c.id
                              AND m.receiver_id = :userId
                              AND m.is_read = false
                        ) AS "unreadCount"
                    FROM chat_conversations c
                    JOIN users u1 ON u1.id = c.user1_id
                    JOIN users u2 ON u2.id = c.user2_id
                    WHERE c.is_deleted = false
                      AND (c.user1_id = :userId OR c.user2_id = :userId)
                    ORDER BY "lastMessageCreatedAt" DESC NULLS LAST, c.created_at DESC
                    """,
            countQuery = """
                    SELECT COUNT(*)
                    FROM chat_conversations c
                    WHERE c.is_deleted = false
                      AND (c.user1_id = :userId OR c.user2_id = :userId)
                    """,
            nativeQuery = true
    )
    Page<ConversationSummaryProjection> findConversationSummaries(@Param("userId") Long userId, Pageable pageable);
}

