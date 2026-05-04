package com.bildunya.controller;

import com.bildunya.dto.ChatMessageDto;
import com.bildunya.dto.ConversationDto;
import com.bildunya.dto.ConversationSummaryDto;
import com.bildunya.dto.CreateConversationRequest;
import com.bildunya.security.UserPrincipal;
import com.bildunya.service.ChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/conversations")
@RequiredArgsConstructor
@Tag(name = "Conversations", description = "Private chat conversations")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ConversationController {

    private final ChatService chatService;

    @GetMapping
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Get user's chat list")
    public ResponseEntity<Page<ConversationSummaryDto>> getMyConversations(
            Authentication authentication,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "50") Integer size) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(chatService.getConversations(principal.getUsername(), pageable));
    }

    @PostMapping
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Create or get conversation with a user")
    public ResponseEntity<ConversationDto> createOrGetConversation(
            Authentication authentication,
            @Valid @RequestBody CreateConversationRequest request) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        ConversationDto dto = chatService.openConversation(principal.getUsername(), request);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/{id}/messages")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Get conversation messages by conversation ID")
    public ResponseEntity<Page<ChatMessageDto>> getMessages(
            Authentication authentication,
            @PathVariable("id") Long conversationId,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "50") Integer size) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(chatService.getConversationMessages(principal.getUsername(), conversationId, pageable));
    }

    @PostMapping("/{id}/read")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Mark conversation as read by conversation ID")
    public ResponseEntity<Void> markAsRead(
            Authentication authentication,
            @PathVariable("id") Long conversationId) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        chatService.markConversationAsRead(principal.getUsername(), conversationId);
        return ResponseEntity.noContent().build();
    }
}

