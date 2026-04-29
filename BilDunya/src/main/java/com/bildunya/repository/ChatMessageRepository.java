package com.bildunya.repository;

import com.bildunya.entity.ChatMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    @Query("SELECT m FROM ChatMessage m " +
            "WHERE m.isDeleted = false AND " +
            "((m.sender.id = :user1Id AND m.receiver.id = :user2Id) OR (m.sender.id = :user2Id AND m.receiver.id = :user1Id)) " +
            "ORDER BY m.createdAt DESC")
    Page<ChatMessage> findConversation(
            @Param("user1Id") Long user1Id,
            @Param("user2Id") Long user2Id,
            Pageable pageable);

    @Modifying
    @Query("UPDATE ChatMessage m SET m.isRead = true " +
            "WHERE m.isDeleted = false AND m.receiver.id = :receiverId AND m.sender.id = :senderId AND m.isRead = false")
    int markConversationAsRead(
            @Param("receiverId") Long receiverId,
            @Param("senderId") Long senderId);
}
