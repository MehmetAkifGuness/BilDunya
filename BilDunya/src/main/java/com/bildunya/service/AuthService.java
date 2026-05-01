package com.bildunya.service;

import com.bildunya.dto.AuthResponse;
import com.bildunya.dto.LoginRequest;
import com.bildunya.dto.RegisterRequest;
import com.bildunya.dto.UserDto;
import com.bildunya.entity.RefreshToken;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.exception.UnauthorizedException;
import com.bildunya.repository.RefreshTokenRepository;
import com.bildunya.repository.UserRepository;
import com.bildunya.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Transactional
public class AuthService {

    private static final Pattern USERNAME_PATTERN = Pattern.compile("^[\\p{L}0-9_.-]{3,50}$");
    private static final int MIN_PASSWORD_LENGTH = 8;
    private static final int MAX_BCRYPT_PASSWORD_BYTES = 72;

    private static final String ROLE_USER = "USER";
    private static final String ROLE_MODERATOR = "MODERATOR";
    private static final String ROLE_ADMIN = "ADMIN";
    private static final Set<String> ALLOWED_ROLES = Set.of(ROLE_USER, ROLE_MODERATOR, ROLE_ADMIN);

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    @Value("${jwt.refresh-expiration:2592000000}")
    private long jwtRefreshExpiration;

    @Value("${auth.require-email-verification:false}")
    private boolean requireEmailVerification;

    @Value("${security.bootstrap-admin-usernames:admin}")
    private String bootstrapAdminUsernames;

    public AuthResponse register(RegisterRequest request) {
        String username = normalizeUsername(request.getUsername());
        String email = normalizeEmail(request.getEmail());

        validateUsername(username);
        validatePasswordStrength(request.getPassword(), username, email);

        if (userRepository.existsByUsernameIgnoreCase(username) || userRepository.existsByEmailIgnoreCase(email)) {
            throw new IllegalArgumentException("Username or email already exists");
        }

        User user = User.builder()
                .username(username)
                .email(email)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName() != null ? request.getFullName().trim() : null)
                .isAnonymous(Boolean.TRUE.equals(request.getIsAnonymous()))
                .isActive(true)
                .emailVerified(false)
                .verificationToken(generateVerificationToken())
                .role(resolveInitialRole(username))
                .tokenVersion(0L)
                .build();
        user = userRepository.save(user);

        cleanupExpiredRefreshTokens();
        return issueAuthResponse(user);
    }

    public AuthResponse login(LoginRequest request) {
        String username = normalizeUsername(request.getUsername());
        String password = request.getPassword();
        if (password == null || password.isBlank()) {
            throw new UnauthorizedException("Invalid credentials");
        }
        if (password.getBytes(StandardCharsets.UTF_8).length > MAX_BCRYPT_PASSWORD_BYTES) {
            throw new UnauthorizedException("Invalid credentials");
        }

        User user = userRepository.findByUsernameIgnoreCase(username)
                .orElseThrow(() -> new UnauthorizedException("Invalid credentials"));

        if (Boolean.TRUE.equals(user.getIsDeleted())) {
            throw new UnauthorizedException("Invalid credentials");
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid credentials");
        }
        if (!Boolean.TRUE.equals(user.getIsActive())) {
            throw new UnauthorizedException("User account is inactive");
        }
        if (requireEmailVerification && !Boolean.TRUE.equals(user.getEmailVerified())) {
            throw new UnauthorizedException("Email address is not verified");
        }

        user = ensureRoleAndTokenVersion(user);

        cleanupExpiredRefreshTokens();
        return issueAuthResponse(user);
    }

    public AuthResponse refresh(String rawRefreshToken) {
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            throw new UnauthorizedException("Invalid refresh token");
        }

        cleanupExpiredRefreshTokens();

        String tokenHash = hashToken(rawRefreshToken.trim());
        RefreshToken refreshToken = refreshTokenRepository
                .findByTokenHashAndRevokedFalseAndIsDeletedFalse(tokenHash)
                .orElseThrow(() -> new UnauthorizedException("Invalid refresh token"));

        if (refreshToken.getExpiresAt() == null || refreshToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            refreshToken.setRevoked(true);
            refreshTokenRepository.save(refreshToken);
            throw new UnauthorizedException("Refresh token expired");
        }

        User user = refreshToken.getUser();
        if (user == null || Boolean.TRUE.equals(user.getIsDeleted()) || !Boolean.TRUE.equals(user.getIsActive())) {
            throw new UnauthorizedException("Invalid refresh token");
        }

        refreshToken.setRevoked(true); // rotation
        refreshTokenRepository.save(refreshToken);

        user = ensureRoleAndTokenVersion(user);
        return issueAuthResponse(user);
    }

    public void logout(String username, String rawRefreshToken) {
        User user = userRepository.findByUsernameIgnoreCase(normalizeUsername(username))
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        user = ensureRoleAndTokenVersion(user);

        if (rawRefreshToken != null && !rawRefreshToken.isBlank()) {
            revokeRefreshTokenIfOwnedByUser(user, rawRefreshToken.trim());
        } else {
            revokeAllActiveRefreshTokens(user);
        }

        long currentVersion = user.getTokenVersion() == null ? 0L : user.getTokenVersion();
        user.setTokenVersion(currentVersion + 1L); // invalidate existing access tokens
        userRepository.save(user);
    }

    public UserDto getUserByUsername(String username) {
        User user = userRepository.findByUsernameIgnoreCase(normalizeUsername(username))
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return mapToPublicUserDto(user);
    }

    public UserDto getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return mapToPublicUserDto(user);
    }

    public UserDto verifyEmail(String verificationToken) {
        if (verificationToken == null || verificationToken.isBlank()) {
            throw new IllegalArgumentException("Verification token is required");
        }

        User user = userRepository.findByVerificationToken(verificationToken.trim())
                .orElseThrow(() -> new UnauthorizedException("Invalid verification token"));

        user.setEmailVerified(true);
        user.setVerificationToken(null);
        user = userRepository.save(user);
        return mapToPrivateUserDto(user);
    }

    public void regenerateVerificationToken(String email) {
        String normalizedEmail = normalizeEmail(email);
        if (normalizedEmail.isBlank()) {
            throw new IllegalArgumentException("Email is required");
        }

        User user = userRepository.findByEmailIgnoreCase(normalizedEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (Boolean.TRUE.equals(user.getEmailVerified())) {
            return;
        }
        user.setVerificationToken(generateVerificationToken());
        userRepository.save(user);
    }

    private AuthResponse issueAuthResponse(User user) {
        User normalizedUser = ensureRoleAndTokenVersion(user);
        String normalizedRole = normalizeRole(normalizedUser.getRole());
        long tokenVersion = normalizedUser.getTokenVersion() == null ? 0L : normalizedUser.getTokenVersion();

        String accessToken = tokenProvider.generateToken(
                normalizedUser.getUsername(),
                normalizedRole,
                tokenVersion);

        String refreshTokenValue = generateOpaqueToken();
        RefreshToken refreshToken = RefreshToken.builder()
                .user(normalizedUser)
                .tokenHash(hashToken(refreshTokenValue))
                .expiresAt(LocalDateTime.now().plusSeconds(jwtRefreshExpiration / 1000))
                .revoked(false)
                .build();
        refreshToken.setIsDeleted(false);
        refreshTokenRepository.save(refreshToken);

        UserDto userDto = mapToPrivateUserDto(normalizedUser);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .tokenType("Bearer")
                .expiresIn(jwtExpiration / 1000)
                .refreshToken(refreshTokenValue)
                .refreshExpiresIn(jwtRefreshExpiration / 1000)
                .user(userDto)
                .build();
    }

    private void revokeRefreshTokenIfOwnedByUser(User user, String rawRefreshToken) {
        String hash = hashToken(rawRefreshToken);
        refreshTokenRepository.findByTokenHashAndRevokedFalseAndIsDeletedFalse(hash)
                .ifPresent(token -> {
                    if (token.getUser() != null && token.getUser().getId() != null &&
                            token.getUser().getId().equals(user.getId())) {
                        token.setRevoked(true);
                        refreshTokenRepository.save(token);
                    }
                });
    }

    private void revokeAllActiveRefreshTokens(User user) {
        List<RefreshToken> tokens = refreshTokenRepository
                .findAllByUserIdAndRevokedFalseAndIsDeletedFalse(user.getId());
        if (tokens.isEmpty()) {
            return;
        }
        for (RefreshToken token : tokens) {
            token.setRevoked(true);
        }
        refreshTokenRepository.saveAll(tokens);
    }

    private User ensureRoleAndTokenVersion(User user) {
        boolean changed = false;
        if (user.getRole() == null || user.getRole().isBlank()) {
            user.setRole(resolveInitialRole(user.getUsername()));
            changed = true;
        } else {
            String normalizedRole = normalizeRole(user.getRole());
            if (!normalizedRole.equals(user.getRole())) {
                user.setRole(normalizedRole);
                changed = true;
            }
        }
        if (user.getTokenVersion() == null) {
            user.setTokenVersion(0L);
            changed = true;
        }
        if (changed) {
            return userRepository.save(user);
        }
        return user;
    }

    private static String normalizeUsername(String username) {
        if (username == null) {
            return "";
        }
        return username.trim();
    }

    private static String normalizeEmail(String email) {
        if (email == null) {
            return "";
        }
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static void validateUsername(String username) {
        if (username.isBlank()) {
            throw new IllegalArgumentException("Username is required");
        }
        if (!USERNAME_PATTERN.matcher(username).matches()) {
            throw new IllegalArgumentException("Username contains invalid characters");
        }
    }

    private static void validatePasswordStrength(String password, String username, String email) {
        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }
        if (password.length() < MIN_PASSWORD_LENGTH) {
            throw new IllegalArgumentException("Password must be at least " + MIN_PASSWORD_LENGTH + " characters");
        }
        if (password.getBytes(StandardCharsets.UTF_8).length > MAX_BCRYPT_PASSWORD_BYTES) {
            throw new IllegalArgumentException("Password is too long");
        }

        if (!username.isBlank() && password.toLowerCase(Locale.ROOT).contains(username.toLowerCase(Locale.ROOT))) {
            throw new IllegalArgumentException("Password must not contain the username");
        }
        if (!email.isBlank()) {
            String localPart = email.split("@", 2)[0];
            if (!localPart.isBlank() && password.toLowerCase(Locale.ROOT).contains(localPart.toLowerCase(Locale.ROOT))) {
                throw new IllegalArgumentException("Password must not contain the email");
            }
        }

        boolean hasLower = false;
        boolean hasUpper = false;
        boolean hasDigit = false;
        for (int i = 0; i < password.length(); i++) {
            char c = password.charAt(i);
            if (Character.isLowerCase(c)) {
                hasLower = true;
            } else if (Character.isUpperCase(c)) {
                hasUpper = true;
            } else if (Character.isDigit(c)) {
                hasDigit = true;
            }
        }
        if (!hasLower || !hasUpper || !hasDigit) {
            throw new IllegalArgumentException("Password must include uppercase, lowercase, and a number");
        }
    }

    private static String generateVerificationToken() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String generateOpaqueToken() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        String randomPart = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        return UUID.randomUUID() + "." + randomPart;
    }

    private static String hashToken(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(hashed);
        } catch (Exception e) {
            throw new IllegalStateException("Unable to hash refresh token", e);
        }
    }

    private String resolveInitialRole(String username) {
        if (isBootstrapAdminUsername(username)) {
            return ROLE_ADMIN;
        }
        return ROLE_USER;
    }

    private boolean isBootstrapAdminUsername(String username) {
        if (username == null || username.isBlank()) {
            return false;
        }
        String csv = bootstrapAdminUsernames;
        if (csv == null || csv.isBlank()) {
            return false;
        }

        String normalized = username.trim().toLowerCase(Locale.ROOT);
        String[] entries = csv.split(",");
        for (String entry : entries) {
            if (entry != null && entry.trim().toLowerCase(Locale.ROOT).equals(normalized)) {
                return true;
            }
        }
        return false;
    }

    private static String normalizeRole(String role) {
        if (role == null || role.isBlank()) {
            return ROLE_USER;
        }
        String normalized = role.trim().toUpperCase(Locale.ROOT);
        if (!ALLOWED_ROLES.contains(normalized)) {
            return ROLE_USER;
        }
        return normalized;
    }

    private void cleanupExpiredRefreshTokens() {
        refreshTokenRepository.deleteByExpiresAtBefore(LocalDateTime.now().minusDays(1));
    }

    private UserDto mapToPrivateUserDto(User user) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

        return UserDto.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .profilePhotoUrl(user.getProfilePhotoUrl())
                .bio(user.getBio())
                .isAnonymous(user.getIsAnonymous())
                .isActive(user.getIsActive())
                .emailVerified(user.getEmailVerified())
                .role(normalizeRole(user.getRole()))
                .phoneNumber(user.getPhoneNumber())
                .locationPreferences(user.getLocationPreferences())
                .createdAt(user.getCreatedAt() != null ? user.getCreatedAt().format(formatter) : null)
                .build();
    }

    private UserDto mapToPublicUserDto(User user) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

        return UserDto.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(null)
                .fullName(user.getFullName())
                .profilePhotoUrl(user.getProfilePhotoUrl())
                .bio(user.getBio())
                .isAnonymous(user.getIsAnonymous())
                .isActive(user.getIsActive())
                .emailVerified(user.getEmailVerified())
                .role(null)
                .phoneNumber(null)
                .locationPreferences(null)
                .createdAt(user.getCreatedAt() != null ? user.getCreatedAt().format(formatter) : null)
                .build();
    }
}
