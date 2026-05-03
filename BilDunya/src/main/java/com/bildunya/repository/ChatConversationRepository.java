package com.bildunya.repository;

import com.bildunya.entity.ChatConversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ChatConversationRepository extends JpaRepository<ChatConversation, Long> {

    Optional<ChatConversation> findByUser1_IdAndUser2_IdAndIsDeletedFalse(Long user1Id, Long user2Id);
}

