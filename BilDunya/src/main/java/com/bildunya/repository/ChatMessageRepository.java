package com.bildunya.repository;

import com.bildunya.entity.ChatMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    @Query("SELECT m FROM ChatMessage m " +
            "WHERE m.isDeleted = false AND m.conversation.id = :conversationId " +
            "ORDER BY m.createdAt DESC")
    Page<ChatMessage> findByConversationId(
            @Param("conversationId") Long conversationId,
            Pageable pageable);

    @Modifying
    @Query(
            value = "UPDATE chat_messages " +
                    "SET conversation_id = :conversationId " +
                    "WHERE conversation_id IS NULL AND is_deleted = false AND " +
                    "((sender_id = :user1Id AND receiver_id = :user2Id) OR (sender_id = :user2Id AND receiver_id = :user1Id))",
            nativeQuery = true
    )
    int attachConversationIdToExistingMessages(
            @Param("conversationId") Long conversationId,
            @Param("user1Id") Long user1Id,
            @Param("user2Id") Long user2Id);

    @Modifying
    @Query("UPDATE ChatMessage m SET m.isRead = true " +
            "WHERE m.isDeleted = false AND m.receiver.id = :receiverId AND m.sender.id = :senderId AND m.isRead = false")
    int markConversationAsRead(
            @Param("receiverId") Long receiverId,
            @Param("senderId") Long senderId);

    @Modifying
    @Query("UPDATE ChatMessage m SET m.isRead = true " +
            "WHERE m.isDeleted = false AND m.conversation.id = :conversationId AND m.receiver.id = :receiverId AND m.isRead = false")
    int markConversationAsReadByConversationId(
            @Param("conversationId") Long conversationId,
            @Param("receiverId") Long receiverId);

    /**
     * Her konuşma için en son mesajın gönderen kullanıcı adı (PostgreSQL DISTINCT ON).
     */
    @Query(
            value = """
                    SELECT DISTINCT ON (m.conversation_id) m.conversation_id, u.username
                    FROM chat_messages m
                    JOIN users u ON u.id = m.sender_id
                    WHERE m.is_deleted = false AND m.conversation_id IN (:ids)
                    ORDER BY m.conversation_id, m.created_at DESC
                    """,
            nativeQuery = true
    )
    List<Object[]> findLatestSenderUsernameRowsByConversationIds(@Param("ids") Collection<Long> ids);
}
