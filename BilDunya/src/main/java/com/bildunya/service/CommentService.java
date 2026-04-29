package com.bildunya.service;

import com.bildunya.dto.CommentDto;
import com.bildunya.dto.CreateCommentRequest;
import com.bildunya.dto.UserDto;
import com.bildunya.entity.Comment;
import com.bildunya.entity.Content;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.exception.UnauthorizedException;
import com.bildunya.repository.CommentRepository;
import com.bildunya.repository.ContentRepository;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
@Transactional
public class CommentService {

    private final CommentRepository commentRepository;
    private final ContentRepository contentRepository;
    private final UserRepository userRepository;

    public CommentDto createComment(String username, Long contentId, CreateCommentRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Content content = contentRepository.findById(contentId)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        Comment parent = null;
        if (request.getParentCommentId() != null) {
            parent = commentRepository.findById(request.getParentCommentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent comment not found"));

            if (parent.getContent() == null || !parent.getContent().getId().equals(contentId)) {
                throw new IllegalArgumentException("Parent comment does not belong to this content");
            }
        }

        Comment comment = Comment.builder()
                .content(content)
                .user(user)
                .parentComment(parent)
                .text(request.getText())
                .isAnonymous(request.getIsAnonymous() != null ? request.getIsAnonymous() : false)
                .likeCount(0L)
                .build();

        comment = commentRepository.save(comment);
        return mapToDto(comment);
    }

    @Transactional(readOnly = true)
    public Page<CommentDto> getCommentsForContent(Long contentId, Pageable pageable) {
        Content content = contentRepository.findById(contentId)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        return commentRepository.findByContentAndIsDeletedFalse(content, pageable)
                .map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public CommentDto getCommentById(Long id) {
        Comment comment = commentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found"));

        if (Boolean.TRUE.equals(comment.getIsDeleted())) {
            throw new ResourceNotFoundException("Comment not found");
        }

        return mapToDto(comment);
    }

    public void deleteComment(Long id, String username) {
        Comment comment = commentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found"));

        if (comment.getUser() == null || comment.getUser().getUsername() == null ||
                !comment.getUser().getUsername().equals(username)) {
            throw new UnauthorizedException("You are not allowed to delete this comment");
        }

        comment.setIsDeleted(true);
        commentRepository.save(comment);
    }

    public CommentDto likeComment(Long id) {
        Comment comment = commentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found"));

        if (Boolean.TRUE.equals(comment.getIsDeleted())) {
            throw new ResourceNotFoundException("Comment not found");
        }

        comment.setLikeCount(comment.getLikeCount() + 1);
        comment = commentRepository.save(comment);
        return mapToDto(comment);
    }

    private CommentDto mapToDto(Comment comment) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

        UserDto userDto = null;
        if (!Boolean.TRUE.equals(comment.getIsAnonymous()) && comment.getUser() != null) {
            User user = comment.getUser();
            userDto = UserDto.builder()
                    .id(user.getId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .fullName(user.getFullName())
                    .profilePhotoUrl(user.getProfilePhotoUrl())
                    .bio(user.getBio())
                    .isAnonymous(user.getIsAnonymous())
                    .isActive(user.getIsActive())
                    .phoneNumber(user.getPhoneNumber())
                    .createdAt(user.getCreatedAt() != null ? user.getCreatedAt().format(formatter) : null)
                    .build();
        }

        return CommentDto.builder()
                .id(comment.getId())
                .contentId(comment.getContent() != null ? comment.getContent().getId() : null)
                .parentCommentId(comment.getParentComment() != null ? comment.getParentComment().getId() : null)
                .text(comment.getText())
                .isAnonymous(comment.getIsAnonymous())
                .likeCount(comment.getLikeCount())
                .user(userDto)
                .createdAt(comment.getCreatedAt() != null ? comment.getCreatedAt().format(formatter) : null)
                .build();
    }
}

