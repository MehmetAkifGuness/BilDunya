package com.bildunya.service;

import com.bildunya.dto.ContentDto;
import com.bildunya.dto.CreateContentRequest;
import com.bildunya.dto.ModerateContentRequest;
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
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Transactional
public class ContentService {

    private static final double AUTO_VERIFY_DISTANCE_KM = 0.5;
    private static final String VERIFICATION_PENDING = "PENDING";
    private static final String VERIFICATION_APPROVED = "APPROVED";
    private static final String VERIFICATION_REJECTED = "REJECTED";
    private static final String REJECTION_EXIF_LOCATION_MISMATCH = "EXIF_LOCATION_MISMATCH";
    private static final String REJECTION_MANUAL_MODERATOR = "MANUAL_MODERATOR_REJECTION";
    private static final double KM_PER_DEGREE_LATITUDE = 111.0;
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of("IMAGE", "VIDEO", "TEXT");
    private static final Set<String> ALLOWED_SHARE_TYPES = Set.of("PUBLIC", "PRIVATE", "ANONYMOUS");
    private static final Set<String> ALLOWED_VERIFICATION_STATUSES =
            Set.of(VERIFICATION_PENDING, VERIFICATION_APPROVED, VERIFICATION_REJECTED);
    private static final Set<String> ALLOWED_MODERATION_DECISIONS =
            Set.of(VERIFICATION_APPROVED, VERIFICATION_REJECTED);
    private static final Set<String> MODERATOR_ROLES = Set.of("ADMIN", "MODERATOR");

    private static final int MAX_DESCRIPTION_LENGTH = 2000;
    private static final int MAX_LOCATION_NAME_LENGTH = 200;
    private static final int MAX_TAGS_LENGTH = 300;
    private static final int MAX_PREF_KEYWORDS = 8;

    private final ContentRepository contentRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;
    private final ObjectMapper objectMapper;

    @CacheEvict(value = {"verifiedContent", "recommendedContent", "nearbyContent"}, allEntries = true)
    public ContentDto createContent(String username, CreateContentRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        normalizeAndValidateCreateRequest(request, user, null);

        Content content = Content.builder()
                .user(user)
                .description(request.getDescription().trim())
                .contentType(request.getContentType())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .locationName(trimToNull(request.getLocationName()))
                .shareType(request.getShareType())
                .tags(trimToNull(request.getTags()))
                .isVerified(false)
                .verificationStatus(VERIFICATION_PENDING)
                .rejectionReason(null)
                .viewCount(0L)
                .build();
        content.setIsDeleted(false);

        content = contentRepository.save(content);
        return mapToContentDto(content);
    }

    @CacheEvict(value = {"verifiedContent", "recommendedContent", "nearbyContent"}, allEntries = true)
    public ContentDto createContentWithFile(String username, CreateContentRequest request, MultipartFile file) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        normalizeAndValidateCreateRequest(request, user, file);

        ExifMatch exifMatch = analyzeExifGps(file, request.getLatitude(), request.getLongitude());

        Content content = Content.builder()
                .user(user)
                .description(request.getDescription().trim())
                .contentType(request.getContentType())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .locationName(trimToNull(request.getLocationName()))
                .shareType(request.getShareType())
                .tags(trimToNull(request.getTags()))
                .exifData(exifMatch.json())
                .isVerified(false)
                .verificationStatus(VERIFICATION_PENDING)
                .rejectionReason(null)
                .viewCount(0L)
                .build();
        content.setIsDeleted(false);
        applyVerificationDecision(content, exifMatch);

        content = contentRepository.save(content);

        String fileUrl = fileStorageService.store(file, "content_" + content.getId());
        content.setFileUrl(fileUrl);

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

    @CacheEvict(value = {"verifiedContent", "recommendedContent", "nearbyContent"}, allEntries = true)
    public ContentDto uploadContentFile(Long contentId, String username, MultipartFile file) {
        Content content = contentRepository.findById(contentId)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        if (content.getUser() == null || content.getUser().getUsername() == null ||
                !content.getUser().getUsername().equals(username)) {
            throw new UnauthorizedException("You are not allowed to update this content");
        }

        validateUploadedFileMatchesContentType(content.getContentType(), file);

        ExifMatch exifMatch = analyzeExifGps(file, content.getLatitude(), content.getLongitude());
        content.setExifData(exifMatch.json());
        applyVerificationDecision(content, exifMatch);

        String fileUrl = fileStorageService.store(file, "content_" + content.getId());
        content.setFileUrl(fileUrl);

        content = contentRepository.save(content);
        return mapToContentDto(content);
    }

    @Cacheable(
            value = "nearbyContent",
            key = "'n:' + #latitude + ':' + #longitude + ':' + #radiusKm + ':' + #pageable.pageNumber + ':' + #pageable.pageSize + ':' + #pageable.sort.toString()")
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

    @Cacheable(
            value = "verifiedContent",
            key = "'v:' + #pageable.pageNumber + ':' + #pageable.pageSize + ':' + #pageable.sort.toString()")
    public Page<ContentDto> getVerifiedContent(Pageable pageable) {
        return contentRepository.findApprovedContent(pageable)
                .map(this::mapToContentDto);
    }

    @Transactional(readOnly = true)
    @Cacheable(
            value = "recommendedContent",
            key = "'r:' + #username + ':' + #pageable.pageNumber + ':' + #pageable.pageSize + ':' + #pageable.sort.toString()")
    public Page<ContentDto> getRecommendedForUser(String username, Pageable pageable) {
        String normalizedUsername = trimToNull(username);
        if (normalizedUsername == null) {
            throw new IllegalArgumentException("username is required");
        }
        User user = userRepository.findByUsernameIgnoreCase(normalizedUsername)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        List<String> keywords = parsePreferenceKeywords(user.getLocationPreferences());
        if (keywords.isEmpty()) {
            return contentRepository
                    .findByIsDeletedFalseAndVerificationStatus(VERIFICATION_APPROVED, pageable)
                    .map(this::mapToContentDto);
        }

        Sort sort = pageable.getSort().isSorted()
                ? pageable.getSort()
                : Sort.by(Sort.Direction.DESC, "createdAt");
        int expandedSize = Math.max(pageable.getPageSize() * 4, 40);
        Pageable expandedPageable = PageRequest.of(pageable.getPageNumber(), expandedSize, sort);

        Page<Content> source = contentRepository
                .findByIsDeletedFalseAndVerificationStatus(VERIFICATION_APPROVED, expandedPageable);

        List<ScoredContent> scored = new ArrayList<>();
        for (Content content : source.getContent()) {
            int score = scoreByPreferences(content, keywords);
            if (score > 0) {
                scored.add(new ScoredContent(content, score));
            }
        }

        scored.sort(Comparator
                .comparingInt(ScoredContent::score).reversed()
                .thenComparing(item -> item.content().getCreatedAt(), Comparator.nullsLast(Comparator.reverseOrder())));

        List<ContentDto> mapped = new ArrayList<>();
        List<ScoredContent> scoredSource = scored.isEmpty()
                ? source.getContent().stream().map(content -> new ScoredContent(content, 0)).toList()
                : scored;
        for (ScoredContent item : scoredSource) {
            mapped.add(mapToContentDto(item.content()));
            if (mapped.size() >= pageable.getPageSize()) {
                break;
            }
        }

        return new PageImpl<>(mapped, pageable, source.getTotalElements());
    }

    @Transactional(readOnly = true)
    public Page<ContentDto> getContentByVerificationStatusForModeration(
            String requesterUsername,
            String verificationStatus,
            Pageable pageable) {

        assertModeratorUsername(requesterUsername);
        String normalizedStatus;
        if (verificationStatus == null || verificationStatus.isBlank()) {
            normalizedStatus = VERIFICATION_PENDING;
        } else {
            normalizedStatus = normalizeEnumOrThrow(
                    verificationStatus,
                    "verificationStatus",
                    ALLOWED_VERIFICATION_STATUSES);
        }

        return contentRepository
                .findByVerificationStatusAndIsDeletedFalse(normalizedStatus, pageable)
                .map(this::mapToContentDto);
    }

    @CacheEvict(value = {"verifiedContent", "recommendedContent", "nearbyContent"}, allEntries = true)
    public ContentDto moderateContent(
            String requesterUsername,
            Long contentId,
            ModerateContentRequest request) {

        assertModeratorUsername(requesterUsername);

        if (request == null) {
            throw new IllegalArgumentException("Request body is required");
        }

        String decision = normalizeEnumOrThrow(
                request.getVerificationStatus(),
                "verificationStatus",
                ALLOWED_MODERATION_DECISIONS);

        Content content = contentRepository.findById(contentId)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        if (Boolean.TRUE.equals(content.getIsDeleted())) {
            throw new ResourceNotFoundException("Content not found");
        }

        if (VERIFICATION_APPROVED.equals(decision)) {
            content.setIsVerified(true);
            content.setVerificationStatus(VERIFICATION_APPROVED);
            content.setRejectionReason(null);
        } else {
            content.setIsVerified(false);
            content.setVerificationStatus(VERIFICATION_REJECTED);
            String rejectionReason = trimToNull(request.getRejectionReason());
            content.setRejectionReason(
                    rejectionReason != null ? rejectionReason : REJECTION_MANUAL_MODERATOR);
        }

        content = contentRepository.save(content);
        return mapToContentDto(content);
    }

    public Page<ContentDto> getUserContent(Long userId, Pageable pageable) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return contentRepository.findByUser(user, pageable)
                .map(this::mapToContentDto);
    }

    @CacheEvict(value = {"verifiedContent", "recommendedContent", "nearbyContent"}, allEntries = true)
    public void deleteContent(Long id) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Content not found"));

        content.setIsDeleted(true);
        contentRepository.save(content);
    }

    @CacheEvict(value = {"verifiedContent", "recommendedContent", "nearbyContent"}, allEntries = true)
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
                .rejectionReason(content.getRejectionReason())
                .exifData(content.getExifData())
                .viewCount(content.getViewCount())
                .shareType(content.getShareType())
                .tags(content.getTags())
                .user(mapAuthorForContent(content, formatter))
                .createdAt(content.getCreatedAt() != null ? content.getCreatedAt().format(formatter) : null)
                .build();
    }

    private static com.bildunya.dto.UserDto mapAuthorForContent(Content content, DateTimeFormatter formatter) {
        if (content == null || content.getUser() == null) {
            return null;
        }

        String shareType = content.getShareType() == null ? "" : content.getShareType().trim().toUpperCase();
        if ("ANONYMOUS".equals(shareType)) {
            return com.bildunya.dto.UserDto.builder()
                    .id(null)
                    .username("anonymous")
                    .email(null)
                    .fullName("Anonim")
                    .profilePhotoUrl(null)
                    .bio(null)
                    .isAnonymous(true)
                    .isActive(true)
                    .phoneNumber(null)
                    .createdAt(null)
                    .build();
        }

        return com.bildunya.dto.UserDto.builder()
                .id(content.getUser().getId())
                .username(content.getUser().getUsername())
                .email(null) // avoid leaking private info in content feeds
                .fullName(content.getUser().getFullName())
                .profilePhotoUrl(content.getUser().getProfilePhotoUrl())
                .bio(content.getUser().getBio())
                .isAnonymous(content.getUser().getIsAnonymous())
                .isActive(content.getUser().getIsActive())
                .phoneNumber(null) // avoid leaking private info in content feeds
                .createdAt(content.getUser().getCreatedAt() != null ? content.getUser().getCreatedAt().format(formatter) : null)
                .build();
    }

    private record ExifGps(double latitude, double longitude) {
    }

    private record ExifMatch(
            boolean exifGpsFound,
            Double latitude,
            Double longitude,
            Double distanceKm,
            boolean locationMatch,
            String decisionNote,
            String json) {
    }

    private record BoundingBox(double minLat, double maxLat, double minLon, double maxLon, boolean wrapsLon) {
    }

    private record ScoredContent(Content content, int score) {
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

    private void normalizeAndValidateCreateRequest(CreateContentRequest request, User user, MultipartFile file) {
        if (request == null) {
            throw new IllegalArgumentException("Request body is required");
        }

        String description = request.getDescription();
        if (description == null || description.isBlank()) {
            throw new IllegalArgumentException("Description is required");
        }
        if (description.length() > MAX_DESCRIPTION_LENGTH) {
            throw new IllegalArgumentException("Description is too long (max " + MAX_DESCRIPTION_LENGTH + " characters)");
        }

        request.setContentType(normalizeEnumOrThrow(request.getContentType(), "contentType", ALLOWED_CONTENT_TYPES));

        if (request.getLatitude() == null || request.getLongitude() == null) {
            throw new IllegalArgumentException("Latitude and longitude are required");
        }
        validateLatitudeLongitude(request.getLatitude(), request.getLongitude());

        if (request.getLocationName() != null && request.getLocationName().length() > MAX_LOCATION_NAME_LENGTH) {
            throw new IllegalArgumentException("Location name is too long (max " + MAX_LOCATION_NAME_LENGTH + " characters)");
        }

        if (request.getTags() != null && request.getTags().length() > MAX_TAGS_LENGTH) {
            throw new IllegalArgumentException("Tags is too long (max " + MAX_TAGS_LENGTH + " characters)");
        }

        String defaultShareType = (user != null && Boolean.TRUE.equals(user.getIsAnonymous())) ? "ANONYMOUS" : "PUBLIC";
        String shareTypeRaw = request.getShareType();
        if (shareTypeRaw == null || shareTypeRaw.isBlank()) {
            request.setShareType(defaultShareType);
        } else {
            request.setShareType(normalizeEnumOrThrow(shareTypeRaw, "shareType", ALLOWED_SHARE_TYPES));
        }

        if (file != null && !file.isEmpty()) {
            validateUploadedFileMatchesContentType(request.getContentType(), file);
        }
    }

    private static void validateLatitudeLongitude(double latitude, double longitude) {
        if (latitude < -90.0 || latitude > 90.0) {
            throw new IllegalArgumentException("Latitude must be between -90 and 90");
        }
        if (longitude < -180.0 || longitude > 180.0) {
            throw new IllegalArgumentException("Longitude must be between -180 and 180");
        }
    }

    private static String normalizeEnumOrThrow(String raw, String fieldName, Set<String> allowedValues) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException(fieldName + " is required");
        }
        String normalized = raw.trim().toUpperCase();
        if ("verificationStatus".equals(fieldName) && "VERIFIED".equals(normalized)) {
            normalized = VERIFICATION_APPROVED;
        }
        if (!allowedValues.contains(normalized)) {
            throw new IllegalArgumentException(fieldName + " must be one of: " + String.join(", ", allowedValues));
        }
        return normalized;
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isBlank() ? null : trimmed;
    }

    private static List<String> parsePreferenceKeywords(String locationPreferences) {
        String normalized = trimToNull(locationPreferences);
        if (normalized == null) {
            return List.of();
        }

        String[] raw = normalized.split("[,;|\\n]");
        List<String> keywords = new ArrayList<>();
        for (String token : raw) {
            if (token == null) {
                continue;
            }
            String value = token.trim().toLowerCase(Locale.ROOT);
            if (value.length() < 2) {
                continue;
            }
            keywords.add(value);
            if (keywords.size() >= MAX_PREF_KEYWORDS) {
                break;
            }
        }
        return keywords;
    }

    private static int scoreByPreferences(Content content, List<String> keywords) {
        if (content == null || keywords == null || keywords.isEmpty()) {
            return 0;
        }

        String location = stringLower(content.getLocationName());
        String tags = stringLower(content.getTags());
        String description = stringLower(content.getDescription());
        String contentType = stringLower(content.getContentType());

        int score = 0;
        for (String keyword : keywords) {
            if (location.contains(keyword)) {
                score += 4;
            }
            if (tags.contains(keyword)) {
                score += 3;
            }
            if (description.contains(keyword)) {
                score += 2;
            }
            if (contentType.contains(keyword)) {
                score += 1;
            }
        }
        return score;
    }

    private static String stringLower(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT);
    }

    private static void validateUploadedFileMatchesContentType(String contentType, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is required");
        }

        String fileContentType = file.getContentType();
        if (fileContentType == null || fileContentType.isBlank()) {
            return; // FileStorageService will still enforce allowed types if configured
        }

        String normalized = contentType == null ? "" : contentType.trim().toUpperCase();
        if ("IMAGE".equals(normalized) && !fileContentType.startsWith("image/")) {
            throw new IllegalArgumentException("Uploaded file must be an image for contentType=IMAGE");
        }
        if ("VIDEO".equals(normalized) && !fileContentType.startsWith("video/")) {
            throw new IllegalArgumentException("Uploaded file must be a video for contentType=VIDEO");
        }
        if ("TEXT".equals(normalized)) {
            throw new IllegalArgumentException("Text content cannot have an uploaded file");
        }
    }

    private ExifMatch analyzeExifGps(MultipartFile file, Double providedLatitude, Double providedLongitude) {
        String mediaType = file == null ? null : trimToNull(file.getContentType());
        ExifGps exifGps = extractExifGps(file);
        if (exifGps == null) {
            String note = (mediaType != null && mediaType.startsWith("video/"))
                    ? "EXIF_GPS_NOT_FOUND_VIDEO"
                    : "EXIF_GPS_NOT_FOUND";
            return buildExifMatch(
                    false,
                    null,
                    null,
                    null,
                    false,
                    note,
                    providedLatitude,
                    providedLongitude,
                    mediaType);
        }

        double computedDistanceKm = haversineKm(
                exifGps.latitude(),
                exifGps.longitude(),
                providedLatitude,
                providedLongitude);
        Double distanceKm = Double.isFinite(computedDistanceKm) ? computedDistanceKm : null;
        boolean locationMatch = distanceKm != null && distanceKm <= AUTO_VERIFY_DISTANCE_KM;

        return buildExifMatch(
                true,
                exifGps.latitude(),
                exifGps.longitude(),
                distanceKm,
                locationMatch,
                locationMatch ? "EXIF_GPS_MATCH" : "EXIF_GPS_MISMATCH",
                providedLatitude,
                providedLongitude,
                mediaType);
    }

    private ExifMatch buildExifMatch(
            boolean exifGpsFound,
            Double exifLatitude,
            Double exifLongitude,
            Double distanceKm,
            boolean locationMatch,
            String decisionNote,
            Double providedLatitude,
            Double providedLongitude,
            String mediaType) {

        Map<String, Object> json = new LinkedHashMap<>();
        json.put("analysisVersion", 2);
        json.put("decisionNote", decisionNote);
        json.put("exifGpsFound", exifGpsFound);
        if (mediaType != null) {
            json.put("mediaType", mediaType);
        }
        if (exifLatitude != null) {
            json.put("gpsLatitude", exifLatitude);
        }
        if (exifLongitude != null) {
            json.put("gpsLongitude", exifLongitude);
        }
        if (providedLatitude != null) {
            json.put("providedLatitude", providedLatitude);
        }
        if (providedLongitude != null) {
            json.put("providedLongitude", providedLongitude);
        }
        if (distanceKm != null) {
            json.put("distanceKm", distanceKm);
        }
        json.put("thresholdKm", AUTO_VERIFY_DISTANCE_KM);
        json.put("locationMatch", locationMatch);

        try {
            return new ExifMatch(
                    exifGpsFound,
                    exifLatitude,
                    exifLongitude,
                    distanceKm,
                    locationMatch,
                    decisionNote,
                    objectMapper.writeValueAsString(json));
        } catch (Exception ignored) {
            return new ExifMatch(
                    exifGpsFound,
                    exifLatitude,
                    exifLongitude,
                    distanceKm,
                    locationMatch,
                    decisionNote,
                    "{\"analysisVersion\":2,\"serializationError\":true}");
        }
    }

    private ExifGps extractExifGps(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return null;
        }

        String contentType = file.getContentType();
        if (contentType != null &&
                !contentType.startsWith("image/") &&
                !contentType.startsWith("video/")) {
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

            return new ExifGps(geoLocation.getLatitude(), geoLocation.getLongitude());
        } catch (Exception ignored) {
            return null;
        }
    }

    private static void applyVerificationDecision(Content content, ExifMatch exifMatch) {
        content.setIsVerified(false);
        content.setVerificationStatus(VERIFICATION_PENDING);
        content.setRejectionReason(null);

        if (exifMatch == null || !exifMatch.exifGpsFound()) {
            return;
        }

        if (exifMatch.locationMatch()) {
            content.setIsVerified(true);
            content.setVerificationStatus(VERIFICATION_APPROVED);
            content.setRejectionReason(null);
            return;
        }

        content.setIsVerified(false);
        content.setVerificationStatus(VERIFICATION_REJECTED);
        content.setRejectionReason(REJECTION_EXIF_LOCATION_MISMATCH);
    }

    private static double haversineKm(double lat1, double lon1, Double lat2, Double lon2) {
        if (lat2 == null || lon2 == null) {
            return Double.POSITIVE_INFINITY;
        }
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        lat1 = Math.toRadians(lat1);
        double lat2Rad = Math.toRadians(lat2);

        double a = Math.pow(Math.sin(dLat / 2), 2)
                + Math.pow(Math.sin(dLon / 2), 2) * Math.cos(lat1) * Math.cos(lat2Rad);

        double c = 2 * Math.asin(Math.sqrt(a));
        return 6371.0 * c;
    }

    private void assertModeratorUsername(String requesterUsername) {
        if (!isModeratorUsername(requesterUsername)) {
            throw new UnauthorizedException("Only moderators can perform this action");
        }
    }

    private boolean isModeratorUsername(String requesterUsername) {
        if (requesterUsername == null || requesterUsername.isBlank()) {
            return false;
        }

        User user = userRepository.findByUsernameIgnoreCase(requesterUsername.trim()).orElse(null);
        if (user == null || Boolean.TRUE.equals(user.getIsDeleted()) || !Boolean.TRUE.equals(user.getIsActive())) {
            return false;
        }
        String role = user.getRole();
        if (role == null || role.isBlank()) {
            return false;
        }
        return MODERATOR_ROLES.contains(role.trim().toUpperCase(Locale.ROOT));
    }
}
