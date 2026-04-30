package com.bildunya.controller;

import com.bildunya.dto.ContentDto;
import com.bildunya.dto.CreateContentRequest;
import com.bildunya.security.UserPrincipal;
import com.bildunya.service.ContentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/contents")
@RequiredArgsConstructor
@Tag(name = "Content", description = "Content management endpoints")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ContentController {

    private final ContentService contentService;

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Create new content")
    public ResponseEntity<ContentDto> createContent(@Valid @RequestBody CreateContentRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();

        ContentDto content = contentService.createContent(principal.getUsername(), request);

        return new ResponseEntity<>(content, HttpStatus.CREATED);
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Create new content with file upload")
    public ResponseEntity<ContentDto> createContentWithFile(
            @Valid @RequestPart("data") CreateContentRequest request,
            @RequestPart("file") MultipartFile file) {

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();

        ContentDto content = contentService.createContentWithFile(principal.getUsername(), request, file);
        return new ResponseEntity<>(content, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get content by ID")
    public ResponseEntity<ContentDto> getContentById(@PathVariable Long id) {
        ContentDto content = contentService.getContentById(id);
        return ResponseEntity.ok(content);
    }

    @PostMapping(value = "/{id}/file", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Upload/replace content file")
    public ResponseEntity<ContentDto> uploadContentFile(
            @PathVariable Long id,
            @RequestPart("file") MultipartFile file) {

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();

        ContentDto content = contentService.uploadContentFile(id, principal.getUsername(), file);
        return ResponseEntity.ok(content);
    }

    @GetMapping("/nearby")
    @Operation(summary = "Get nearby content")
    public ResponseEntity<Page<ContentDto>> getNearbyContent(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "5") Double radiusKm,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer size,
            @RequestParam(defaultValue = "created_at") String sortBy) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).descending());
        Page<ContentDto> contents = contentService.getNearbyContent(latitude, longitude, radiusKm, pageable);

        return ResponseEntity.ok(contents);
    }

    @GetMapping("/verified")
    @Operation(summary = "Get verified content")
    public ResponseEntity<Page<ContentDto>> getVerifiedContent(
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<ContentDto> contents = contentService.getVerifiedContent(pageable);

        return ResponseEntity.ok(contents);
    }

    @GetMapping("/user/{userId}")
    @Operation(summary = "Get user's content")
    public ResponseEntity<Page<ContentDto>> getUserContent(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<ContentDto> contents = contentService.getUserContent(userId, pageable);

        return ResponseEntity.ok(contents);
    }

    @DeleteMapping("/{id}")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Delete content")
    public ResponseEntity<Void> deleteContent(@PathVariable Long id) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();

        contentService.deleteContent(id, principal.getUsername());
        return ResponseEntity.noContent().build();
    }
}
