package com.bildunya.controller;

import com.bildunya.dto.LoginRequest;
import com.bildunya.dto.RegisterRequest;
import com.bildunya.dto.AuthResponse;
import com.bildunya.dto.LogoutRequest;
import com.bildunya.dto.RefreshTokenRequest;
import com.bildunya.dto.ResendVerificationRequest;
import com.bildunya.dto.UserDto;
import com.bildunya.security.UserPrincipal;
import com.bildunya.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "User authentication endpoints")
@CrossOrigin(origins = "*", maxAge = 3600)
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "Register a new user")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PostMapping("/login")
    @Operation(summary = "Login user")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refresh(request.getRefreshToken());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Logout current user and invalidate session")
    public ResponseEntity<Map<String, String>> logout(
            Authentication authentication,
            @RequestBody(required = false) LogoutRequest request) {

        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal principal)) {
            return new ResponseEntity<>(Map.of("message", "Unauthorized"), HttpStatus.UNAUTHORIZED);
        }

        authService.logout(
                principal.getUsername(),
                request != null ? request.getRefreshToken() : null);
        return ResponseEntity.ok(Map.of("message", "Logged out"));
    }

    @GetMapping("/verify-email")
    @Operation(summary = "Verify email by token")
    public ResponseEntity<UserDto> verifyEmail(@RequestParam("token") String token) {
        UserDto dto = authService.verifyEmail(token);
        return ResponseEntity.ok(dto);
    }

    @PostMapping("/resend-verification")
    @Operation(summary = "Regenerate email verification token")
    public ResponseEntity<Map<String, String>> resendVerification(
            @Valid @RequestBody ResendVerificationRequest request) {
        authService.regenerateVerificationToken(request.getEmail());
        return ResponseEntity.ok(Map.of("message", "Verification token regenerated"));
    }

    @GetMapping("/user/{username}")
    @Operation(summary = "Get user by username")
    public ResponseEntity<UserDto> getUserByUsername(@PathVariable String username) {
        UserDto user = authService.getUserByUsername(username);
        return ResponseEntity.ok(user);
    }

    @GetMapping("/user/id/{id}")
    @Operation(summary = "Get user by ID")
    public ResponseEntity<UserDto> getUserById(@PathVariable Long id) {
        UserDto user = authService.getUserById(id);
        return ResponseEntity.ok(user);
    }

    @GetMapping("/health")
    @Operation(summary = "Health check")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("OK");
    }
}
