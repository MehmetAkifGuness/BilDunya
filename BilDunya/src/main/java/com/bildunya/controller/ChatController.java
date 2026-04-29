package com.bildunya.controller;

import com.bildunya.dto.ChatMessageDto;
import com.bildunya.dto.SendChatMessageRequest;
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
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
@Tag(name = "Chat", description = "Chat endpoints")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ChatController {

    private final ChatService chatService;

    @PostMapping("/messages")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Send a chat message")
    public ResponseEntity<ChatMessageDto> sendMessage(
            Authentication authentication,
            @Valid @RequestBody SendChatMessageRequest request) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        ChatMessageDto dto = chatService.sendMessage(principal.getUsername(), request);
        return new ResponseEntity<>(dto, HttpStatus.CREATED);
    }

    @GetMapping("/conversations/{username}")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Get conversation with a user")
    public ResponseEntity<Page<ChatMessageDto>> getConversation(
            Authentication authentication,
            @PathVariable String username,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "50") Integer size) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        return ResponseEntity.ok(chatService.getConversation(principal.getUsername(), username, pageable));
    }

    @PostMapping("/conversations/{username}/read")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Mark conversation as read")
    public ResponseEntity<Void> markConversationAsRead(
            Authentication authentication,
            @PathVariable String username) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        chatService.markConversationAsRead(principal.getUsername(), username);
        return ResponseEntity.noContent().build();
    }
}

