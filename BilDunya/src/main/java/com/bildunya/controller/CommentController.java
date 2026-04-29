package com.bildunya.controller;

import com.bildunya.dto.CommentDto;
import com.bildunya.dto.CreateCommentRequest;
import com.bildunya.security.UserPrincipal;
import com.bildunya.service.CommentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@Tag(name = "Comments", description = "Comment endpoints")
@CrossOrigin(origins = "*", maxAge = 3600)
public class CommentController {

    private final CommentService commentService;

    @PostMapping("/contents/{contentId}/comments")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Create comment for a content")
    public ResponseEntity<CommentDto> createComment(
            Authentication authentication,
            @PathVariable Long contentId,
            @Valid @RequestBody CreateCommentRequest request) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        CommentDto dto = commentService.createComment(principal.getUsername(), contentId, request);
        return new ResponseEntity<>(dto, HttpStatus.CREATED);
    }

    @GetMapping("/contents/{contentId}/comments")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "List comments for a content")
    public ResponseEntity<Page<CommentDto>> listComments(
            @PathVariable Long contentId,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        return ResponseEntity.ok(commentService.getCommentsForContent(contentId, pageable));
    }

    @GetMapping("/comments/{id}")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Get comment by ID")
    public ResponseEntity<CommentDto> getCommentById(@PathVariable Long id) {
        return ResponseEntity.ok(commentService.getCommentById(id));
    }

    @DeleteMapping("/comments/{id}")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Delete own comment")
    public ResponseEntity<Void> deleteComment(Authentication authentication, @PathVariable Long id) {
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        commentService.deleteComment(id, principal.getUsername());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/comments/{id}/like")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Like a comment")
    public ResponseEntity<CommentDto> likeComment(@PathVariable Long id) {
        return ResponseEntity.ok(commentService.likeComment(id));
    }
}

