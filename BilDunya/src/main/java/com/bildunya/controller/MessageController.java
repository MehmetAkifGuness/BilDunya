package com.bildunya.controller;

import com.bildunya.dto.ChatMessageDto;
import com.bildunya.dto.SendMessageRequest;
import com.bildunya.security.UserPrincipal;
import com.bildunya.service.ChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/messages")
@RequiredArgsConstructor
@Tag(name = "Messages", description = "Chat message endpoints")
@CrossOrigin(origins = "*", maxAge = 3600)
public class MessageController {

    private final ChatService chatService;

    @PostMapping
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Send a message in a conversation")
    public ResponseEntity<ChatMessageDto> sendMessage(
            Authentication authentication,
            @Valid @RequestBody SendMessageRequest request) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        ChatMessageDto dto = chatService.sendMessageToConversation(principal.getUsername(), request);
        return new ResponseEntity<>(dto, HttpStatus.CREATED);
    }
}

