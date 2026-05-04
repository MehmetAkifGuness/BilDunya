package com.bildunya.repository;

import com.bildunya.entity.ContentLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ContentLikeRepository extends JpaRepository<ContentLike, Long> {

    Optional<ContentLike> findByContent_IdAndUser_IdAndIsDeletedFalse(Long contentId, Long userId);

    boolean existsByContent_IdAndUser_UsernameIgnoreCaseAndIsDeletedFalse(Long contentId, String username);

    long countByContent_IdAndIsDeletedFalse(Long contentId);
}
