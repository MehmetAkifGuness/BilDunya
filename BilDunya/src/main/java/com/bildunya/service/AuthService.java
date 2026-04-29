package com.bildunya.service;

import com.bildunya.dto.UserDto;
import com.bildunya.dto.LoginRequest;
import com.bildunya.dto.RegisterRequest;
import com.bildunya.dto.AuthResponse;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.exception.UnauthorizedException;
import com.bildunya.repository.UserRepository;
import com.bildunya.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
@Transactional
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("Username already exists");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already registered");
        }

        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .isAnonymous(request.getIsAnonymous())
                .isActive(true)
                .emailVerified(false)
                .build();

        user = userRepository.save(user);

        String token = tokenProvider.generateToken(user.getUsername());

        UserDto userDto = mapToUserDto(user);

        return AuthResponse.builder()
                .accessToken(token)
                .tokenType("Bearer")
                .expiresIn(jwtExpiration / 1000)
                .user(userDto)
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new UnauthorizedException("Invalid credentials"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid credentials");
        }

        if (!user.getIsActive()) {
            throw new UnauthorizedException("User account is inactive");
        }

        String token = tokenProvider.generateToken(user.getUsername());
        UserDto userDto = mapToUserDto(user);

        return AuthResponse.builder()
                .accessToken(token)
                .tokenType("Bearer")
                .expiresIn(jwtExpiration / 1000)
                .user(userDto)
                .build();
    }

    public UserDto getUserByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return mapToUserDto(user);
    }

    public UserDto getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return mapToUserDto(user);
    }

    private UserDto mapToUserDto(User user) {
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
                .phoneNumber(user.getPhoneNumber())
                .createdAt(user.getCreatedAt() != null ? user.getCreatedAt().format(formatter) : null)
                .build();
    }
}
