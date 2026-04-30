package com.bildunya.service;

import com.bildunya.dto.ContentDto;
import com.bildunya.dto.CreateContentRequest;
import com.bildunya.entity.Content;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.exception.UnauthorizedException;
import com.bildunya.repository.ContentRepository;
import com.bildunya.repository.UserRepository;
import com.drew.imaging.ImageMetadataReader;
import com.drew.lang.GeoLocation;
import com.drew.metadata.Metadata;
import com.drew.metadata.exif.GpsDirectory;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.time.format.DateTimeFormatter;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional
public class ContentService {

    private static final double AUTO_VERIFY_DISTANCE_KM = 0.5;
    private static final double KM_PER_DEGREE_LATITUDE = 111.0;

    private final ContentRepository contentRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;
    private final ObjectMapper objectMapper;

    public ContentDto createContent(String username, CreateContentRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Content content = Content.builder()
                .user(user)
                .description(request.getDescription())
                .contentType(request.getContentType())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .locationName(request.getLocationName())
                .shareType(request.getShareType() != null ? request.getShareType() : "PUBLIC")
                .tags(request.getTags())
                .isVerified(false)
                .verificationStatus("PENDING")
                .viewCount(0L)
                .build();
        content.setIsDeleted(false);

        content = contentRepository.save(content);
        return mapToContentDto(content);
    }

    public ContentDto createContentWithFile(String username, CreateContentRequest request, MultipartFile file) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        ExifGps exifGps = extractExifGps(file);

        Content content = Content.builder()
                .user(user)
                .description(request.getDescription())
                .contentType(request.getContentType())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .locationName(request.getLocationName())
                .shareType(request.getShareType() != null ? request.getShareType() : "PUBLIC")
                .tags(request.getTags())
                .exifData(exifGps != null ? exifGps.json() : null)
                .isVerified(false)
                .verificationStatus("PENDING")
                .viewCount(0L)
                .build();
        content.setIsDeleted(false);

        if (exifGps != null && isWithinDistanceKm(
                exifGps.latitude(),
                exifGps.longitude(),
                request.getLatitude(),
                request.getLongitude(),
                AUTO_VERIFY_DISTANCE_KM)) {
            content.setIsVerified(true);
            content.setVerificationStatus("VERIFIED");
        }

        content = contentRepository.save(content);

        String storedFilename = fileStorageService.store(file, "content_" + content.getId());
        content.setFileUrl("/api/uploads/" + storedFilename);

        content = contentRepository.save(content);
        return mapToContentDto(content);
    }

    public ContentDto getContentById(Long id) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        content.setViewCount(content.getViewCount() + 1);
        contentRepository.save(content);

        return mapToContentDto(content);
    }

    public ContentDto uploadContentFile(Long contentId, String username, MultipartFile file) {
        Content content = contentRepository.findById(contentId)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        if (content.getUser() == null || content.getUser().getUsername() == null ||
                !content.getUser().getUsername().equals(username)) {
            throw new UnauthorizedException("You are not allowed to update this content");
        }

        ExifGps exifGps = extractExifGps(file);
        content.setExifData(exifGps != null ? exifGps.json() : null);

        content.setIsVerified(false);
        content.setVerificationStatus("PENDING");
        if (exifGps != null && content.getLatitude() != null && content.getLongitude() != null &&
                isWithinDistanceKm(
                        exifGps.latitude(),
                        exifGps.longitude(),
                        content.getLatitude(),
                        content.getLongitude(),
                        AUTO_VERIFY_DISTANCE_KM)) {
            content.setIsVerified(true);
            content.setVerificationStatus("VERIFIED");
        }

        String storedFilename = fileStorageService.store(file, "content_" + content.getId());
        content.setFileUrl("/api/uploads/" + storedFilename);

        content = contentRepository.save(content);
        return mapToContentDto(content);
    }

    public Page<ContentDto> getNearbyContent(Double latitude, Double longitude, Double radiusKm, Pageable pageable) {
        if (latitude == null || longitude == null || radiusKm == null) {
            throw new IllegalArgumentException("Latitude, longitude and radiusKm are required");
        }
        if (radiusKm <= 0) {
            throw new IllegalArgumentException("radiusKm must be greater than 0");
        }

        BoundingBox box = computeBoundingBox(latitude, longitude, radiusKm);
        return contentRepository.findNearbyContent(
                        latitude,
                        longitude,
                        radiusKm,
                        box.minLat(),
                        box.maxLat(),
                        box.minLon(),
                        box.maxLon(),
                        box.wrapsLon(),
                        pageable)
                .map(this::mapToContentDto);
    }

    public Page<ContentDto> getVerifiedContent(Pageable pageable) {
        return contentRepository.findVerifiedContent(pageable)
                .map(this::mapToContentDto);
    }

    public Page<ContentDto> getUserContent(Long userId, Pageable pageable) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return contentRepository.findByUser(user, pageable)
                .map(this::mapToContentDto);
    }

    public void deleteContent(Long id) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        content.setIsDeleted(true);
        contentRepository.save(content);
    }

    public void deleteContent(Long id, String username) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        if (content.getUser() == null || content.getUser().getUsername() == null ||
                !content.getUser().getUsername().equals(username)) {
            throw new UnauthorizedException("You are not allowed to delete this content");
        }

        content.setIsDeleted(true);
        contentRepository.save(content);
    }

    private ContentDto mapToContentDto(Content content) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

        return ContentDto.builder()
                .id(content.getId())
                .description(content.getDescription())
                .contentType(content.getContentType())
                .fileUrl(content.getFileUrl())
                .latitude(content.getLatitude())
                .longitude(content.getLongitude())
                .locationName(content.getLocationName())
                .isVerified(content.getIsVerified())
                .verificationStatus(content.getVerificationStatus())
                .viewCount(content.getViewCount())
                .shareType(content.getShareType())
                .tags(content.getTags())
                .user(new com.bildunya.dto.UserDto(
                        content.getUser().getId(),
                        content.getUser().getUsername(),
                        content.getUser().getEmail(),
                        content.getUser().getFullName(),
                        content.getUser().getProfilePhotoUrl(),
                        content.getUser().getBio(),
                        content.getUser().getIsAnonymous(),
                        content.getUser().getIsActive(),
                        content.getUser().getPhoneNumber(),
                        content.getUser().getCreatedAt() != null ? content.getUser().getCreatedAt().format(formatter) : null
                ))
                .createdAt(content.getCreatedAt() != null ? content.getCreatedAt().format(formatter) : null)
                .build();
    }

    private record ExifGps(double latitude, double longitude, String json) {
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

    private ExifGps extractExifGps(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return null;
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            return null;
        }

        try (InputStream inputStream = file.getInputStream()) {
            Metadata metadata = ImageMetadataReader.readMetadata(inputStream);
            GpsDirectory gpsDirectory = metadata.getFirstDirectoryOfType(GpsDirectory.class);
            if (gpsDirectory == null) {
                return null;
            }

            GeoLocation geoLocation = gpsDirectory.getGeoLocation();
            if (geoLocation == null) {
                return null;
            }

            double lat = geoLocation.getLatitude();
            double lon = geoLocation.getLongitude();
            String json = objectMapper.writeValueAsString(Map.of(
                    "gpsLatitude", lat,
                    "gpsLongitude", lon
            ));
            return new ExifGps(lat, lon, json);
        } catch (Exception ignored) {
            return null;
        }
    }

    private static boolean isWithinDistanceKm(
            double latitude1,
            double longitude1,
            double latitude2,
            double longitude2,
            double thresholdKm) {

        return haversineKm(latitude1, longitude1, latitude2, longitude2) <= thresholdKm;
    }

    private static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        lat1 = Math.toRadians(lat1);
        lat2 = Math.toRadians(lat2);

        double a = Math.pow(Math.sin(dLat / 2), 2)
                + Math.pow(Math.sin(dLon / 2), 2) * Math.cos(lat1) * Math.cos(lat2);

        double c = 2 * Math.asin(Math.sqrt(a));
        return 6371.0 * c;
    }
}
