package com.bildunya.repository;

import com.bildunya.entity.ChatConversation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ChatConversationRepository extends JpaRepository<ChatConversation, Long> {

    interface ConversationSummaryProjection {
        Number getConversationId();

        Number getOtherUserId();

        String getOtherUsername();

        String getOtherFullName();

        String getLastMessageText();

        Object getLastMessageCreatedAt();

        Number getUnreadCount();

        Number getRelatedContentId();

        String getRelatedContentLabel();
    }

    Optional<ChatConversation> findByUser1_IdAndUser2_IdAndIsDeletedFalse(Long user1Id, Long user2Id);

    @Modifying
    @Query("UPDATE ChatConversation c SET c.updatedAt = CURRENT_TIMESTAMP WHERE c.id = :conversationId")
    int touchConversation(@Param("conversationId") Long conversationId);

    @Query(
            value = """
                    SELECT
                        c.id                                                            AS "conversationId",
                        CASE WHEN c.user1_id = :userId THEN u2.id   ELSE u1.id   END  AS "otherUserId",
                        CASE WHEN c.user1_id = :userId THEN u2.username ELSE u1.username END AS "otherUsername",
                        CASE WHEN c.user1_id = :userId THEN u2.full_name ELSE u1.full_name END AS "otherFullName",
                        NULL AS "lastMessageText",
                        NULL AS "lastMessageCreatedAt",
                        0 AS "unreadCount",
                        c.related_content_id AS "relatedContentId",
                        COALESCE(NULLIF(TRIM(ct.location_name), ''), LEFT(ct.description, 100)) AS "relatedContentLabel"
                    FROM chat_conversations c
                    JOIN users u1 ON u1.id = c.user1_id
                    JOIN users u2 ON u2.id = c.user2_id
                    LEFT JOIN contents ct ON ct.id = c.related_content_id AND ct.is_deleted = false
                    WHERE c.is_deleted = false
                      AND (c.user1_id = :userId OR c.user2_id = :userId)
                    ORDER BY c.updated_at DESC NULLS LAST, c.created_at DESC
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

