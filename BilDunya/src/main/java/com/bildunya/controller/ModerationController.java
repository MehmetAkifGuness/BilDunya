package com.bildunya.controller;

import com.bildunya.dto.ContentDto;
import com.bildunya.dto.ModerateContentRequest;
import com.bildunya.security.UserPrincipal;
import com.bildunya.service.ModerationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/moderation")
@RequiredArgsConstructor
@Tag(name = "Moderation", description = "Admin moderation endpoints")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ModerationController {

    private final ModerationService moderationService;

    @GetMapping("/pending")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Get pending content queue")
    public ResponseEntity<Page<ContentDto>> getPendingContent(
            Authentication authentication,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        return ResponseEntity.ok(moderationService.getPendingContent(principal.getUsername(), pageable));
    }

    @PostMapping("/{id}/approve")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Approve pending content")
    public ResponseEntity<ContentDto> approveContent(
            Authentication authentication,
            @PathVariable Long id) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        return ResponseEntity.ok(moderationService.approveContent(principal.getUsername(), id));
    }

    @PostMapping("/{id}/reject")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Reject pending content")
    public ResponseEntity<ContentDto> rejectContent(
            Authentication authentication,
            @PathVariable Long id,
            @RequestBody(required = false) ModerateContentRequest request) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        return ResponseEntity.ok(moderationService.rejectContent(principal.getUsername(), id, request));
    }
}
