package com.bildunya.repository;

import com.bildunya.entity.Comment;
import com.bildunya.entity.Content;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {

    Page<Comment> findByContent(Content content, Pageable pageable);

    Page<Comment> findByContentAndIsDeletedFalse(Content content, Pageable pageable);

    Page<Comment> findByParentComment(Comment parentComment, Pageable pageable);

    Page<Comment> findByParentCommentAndIsDeletedFalse(Comment parentComment, Pageable pageable);
}
