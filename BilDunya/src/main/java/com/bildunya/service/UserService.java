package com.bildunya.service;

import com.bildunya.dto.UpdateProfileRequest;
import com.bildunya.dto.UserDto;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    public UserDto getProfile(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return mapToUserDto(user);
    }

    public UserDto updateProfile(String username, UpdateProfileRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (request.getFullName() != null) {
            user.setFullName(request.getFullName());
        }

        if (request.getBio() != null) {
            user.setBio(request.getBio());
        }

        if (request.getPhoneNumber() != null) {
            user.setPhoneNumber(request.getPhoneNumber());
        }

        if (request.getIsAnonymous() != null) {
            user.setIsAnonymous(request.getIsAnonymous());
        }

        if (request.getLocationPreferences() != null) {
            user.setLocationPreferences(request.getLocationPreferences());
        }

        user = userRepository.save(user);
        return mapToUserDto(user);
    }

    public UserDto uploadProfilePhoto(String username, org.springframework.web.multipart.MultipartFile file) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        String storedFilename = fileStorageService.store(file, "profile_" + user.getId());
        user.setProfilePhotoUrl("/api/uploads/" + storedFilename);

        user = userRepository.save(user);
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
                .emailVerified(user.getEmailVerified())
                .role(user.getRole())
                .phoneNumber(user.getPhoneNumber())
                .locationPreferences(user.getLocationPreferences())
                .createdAt(user.getCreatedAt() != null ? user.getCreatedAt().format(formatter) : null)
                .build();
    }
}
