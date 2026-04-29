package com.bildunya.controller;

import com.bildunya.dto.UpdateProfileRequest;
import com.bildunya.dto.UserDto;
import com.bildunya.security.UserPrincipal;
import com.bildunya.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Tag(name = "Users", description = "User profile endpoints")
@CrossOrigin(origins = "*", maxAge = 3600)
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Get current user profile")
    public ResponseEntity<UserDto> me(Authentication authentication) {
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        return ResponseEntity.ok(userService.getProfile(principal.getUsername()));
    }

    @PatchMapping("/me")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Update current user profile")
    public ResponseEntity<UserDto> updateMe(
            Authentication authentication,
            @Valid @RequestBody UpdateProfileRequest request) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        return ResponseEntity.ok(userService.updateProfile(principal.getUsername(), request));
    }

    @PostMapping(value = "/me/profile-photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Upload current user's profile photo")
    public ResponseEntity<UserDto> uploadProfilePhoto(
            Authentication authentication,
            @RequestPart("file") MultipartFile file) {

        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        return ResponseEntity.ok(userService.uploadProfilePhoto(principal.getUsername(), file));
    }
}
