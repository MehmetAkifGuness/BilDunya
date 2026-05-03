package com.bildunya.service;

import com.bildunya.dto.CreateCustomLocationRequest;
import com.bildunya.dto.CustomLocationDto;
import com.bildunya.entity.CustomLocation;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.exception.UnauthorizedException;
import com.bildunya.repository.CustomLocationRepository;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Transactional
public class CustomLocationService {

    private static final double KM_PER_DEGREE_LATITUDE = 111.0;
    private static final int MAX_NAME_LENGTH = 200;
    private static final int MAX_DESCRIPTION_LENGTH = 2000;
    private static final int MAX_TAGS = 25;

    private final CustomLocationRepository customLocationRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    public CustomLocationDto createCustomLocation(String username, CreateCustomLocationRequest request) {
        return createCustomLocationWithOptionalImage(username, request, null);
    }

    public CustomLocationDto createCustomLocationWithImage(String username, CreateCustomLocationRequest request, MultipartFile image) {
        return createCustomLocationWithOptionalImage(username, request, image);
    }

    public CustomLocationDto getById(Long id) {
        CustomLocation loc = customLocationRepository.findById(id)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Custom location not found"));
        return mapToDto(loc);
    }

    public Page<CustomLocationDto> getNearby(Double latitude,
                                            Double longitude,
                                            Double radiusKm,
                                            boolean mineOnly,
                                            String username,
                                            Pageable pageable) {
        if (latitude == null || longitude == null || radiusKm == null) {
            throw new IllegalArgumentException("Latitude, longitude and radiusKm are required");
        }
        if (radiusKm <= 0) {
            throw new IllegalArgumentException("radiusKm must be greater than 0");
        }
        validateLatitudeLongitude(latitude, longitude);

        BoundingBox box = computeBoundingBox(latitude, longitude, radiusKm);
        Page<CustomLocation> page;
        if (mineOnly) {
            if (username == null || username.isBlank()) {
                throw new UnauthorizedException("Authentication required");
            }
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new ResourceNotFoundException("User not found"));
            page = customLocationRepository.findNearbyCustomLocationsForUser(
                    user.getId(),
                    latitude,
                    longitude,
                    radiusKm,
                    box.minLat(),
                    box.maxLat(),
                    box.minLon(),
                    box.maxLon(),
                    box.wrapsLon(),
                    pageable);
        } else {
            page = customLocationRepository.findNearbyCustomLocations(
                    latitude,
                    longitude,
                    radiusKm,
                    box.minLat(),
                    box.maxLat(),
                    box.minLon(),
                    box.maxLon(),
                    box.wrapsLon(),
                    pageable);
        }
        return page.map(this::mapToDto);
    }

    public void delete(Long id, String username) {
        CustomLocation loc = customLocationRepository.findById(id)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Custom location not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (loc.getUser() == null || loc.getUser().getId() == null || !loc.getUser().getId().equals(user.getId())) {
            throw new UnauthorizedException("You can only delete your own custom locations");
        }

        loc.setIsDeleted(true);
        customLocationRepository.save(loc);
    }

    private CustomLocationDto createCustomLocationWithOptionalImage(String username,
                                                                   CreateCustomLocationRequest request,
                                                                   MultipartFile image) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        normalizeAndValidateRequest(request, image);

        String imageUrl = null;
        if (image != null && !image.isEmpty()) {
            imageUrl = fileStorageService.store(image, "custom_location_" + user.getId());
        }

        CustomLocation loc = CustomLocation.builder()
                .user(user)
                .name(request.getName().trim())
                .description(trimToNull(request.getDescription()))
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .imageUrl(trimToNull(imageUrl))
                .tags(normalizeTags(request.getTags()))
                .build();
        loc.setIsDeleted(false);

        loc = customLocationRepository.save(loc);
        return mapToDto(loc);
    }

    private void normalizeAndValidateRequest(CreateCustomLocationRequest request, MultipartFile image) {
        if (request == null) {
            throw new IllegalArgumentException("Request body is required");
        }
        if (request.getName() == null || request.getName().isBlank()) {
            throw new IllegalArgumentException("Name is required");
        }
        if (request.getName().length() > MAX_NAME_LENGTH) {
            throw new IllegalArgumentException("Name is too long (max " + MAX_NAME_LENGTH + " characters)");
        }
        if (request.getDescription() != null && request.getDescription().length() > MAX_DESCRIPTION_LENGTH) {
            throw new IllegalArgumentException("Description is too long (max " + MAX_DESCRIPTION_LENGTH + " characters)");
        }
        if (request.getLatitude() == null || request.getLongitude() == null) {
            throw new IllegalArgumentException("Latitude and longitude are required");
        }
        validateLatitudeLongitude(request.getLatitude(), request.getLongitude());

        List<String> tags = request.getTags();
        if (tags != null && tags.size() > MAX_TAGS) {
            throw new IllegalArgumentException("Too many tags (max " + MAX_TAGS + ")");
        }

        if (image != null && !image.isEmpty()) {
            String contentType = image.getContentType() != null ? image.getContentType().toLowerCase(Locale.ROOT) : "";
            if (!contentType.startsWith("image/")) {
                throw new IllegalArgumentException("Only image uploads are supported");
            }
        }
    }

    private CustomLocationDto mapToDto(CustomLocation loc) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss", Locale.getDefault());
        return CustomLocationDto.builder()
                .id(loc.getId())
                .userId(loc.getUser() != null ? loc.getUser().getId() : null)
                .name(loc.getName())
                .description(loc.getDescription())
                .latitude(loc.getLatitude())
                .longitude(loc.getLongitude())
                .imageUrl(loc.getImageUrl())
                .tags(loc.getTags() != null ? loc.getTags() : List.of())
                .createdAt(loc.getCreatedAt() != null ? loc.getCreatedAt().format(formatter) : null)
                .build();
    }

    private static void validateLatitudeLongitude(double latitude, double longitude) {
        if (latitude < -90.0 || latitude > 90.0) {
            throw new IllegalArgumentException("Latitude must be between -90 and 90");
        }
        if (longitude < -180.0 || longitude > 180.0) {
            throw new IllegalArgumentException("Longitude must be between -180 and 180");
        }
    }

    private static String trimToNull(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static List<String> normalizeTags(List<String> tags) {
        if (tags == null || tags.isEmpty()) return new ArrayList<>();
        Set<String> uniq = new LinkedHashSet<>();
        for (String raw : tags) {
            if (raw == null) continue;
            String t = raw.trim();
            if (t.isEmpty()) continue;
            if (t.length() > 50) {
                t = t.substring(0, 50);
            }
            uniq.add(t);
            if (uniq.size() >= MAX_TAGS) break;
        }
        return new ArrayList<>(uniq);
    }

    private record BoundingBox(double minLat, double maxLat, double minLon, double maxLon, boolean wrapsLon) {
    }

    private static BoundingBox computeBoundingBox(double latitude, double longitude, double radiusKm) {
        double deltaLat = radiusKm / KM_PER_DEGREE_LATITUDE;
        double minLat = Math.max(latitude - deltaLat, -90.0);
        double maxLat = Math.min(latitude + deltaLat, 90.0);

        double cosLat = Math.cos(Math.toRadians(latitude));
        if (Math.abs(cosLat) < 1e-6) {
            return new BoundingBox(minLat, maxLat, -180.0, 180.0, false);
        }

        double deltaLon = radiusKm / (KM_PER_DEGREE_LATITUDE * cosLat);
        if (deltaLon >= 180.0) {
            return new BoundingBox(minLat, maxLat, -180.0, 180.0, false);
        }
        double minLon = longitude - deltaLon;
        double maxLon = longitude + deltaLon;

        boolean wrapsLon = false;
        if (minLon < -180.0) {
            minLon += 360.0;
            wrapsLon = true;
        }
        if (maxLon > 180.0) {
            maxLon -= 360.0;
            wrapsLon = true;
        }

        if (minLon < -180.0) {
            minLon = -180.0;
        }
        if (maxLon > 180.0) {
            maxLon = 180.0;
        }

        return new BoundingBox(minLat, maxLat, minLon, maxLon, wrapsLon);
    }
}

