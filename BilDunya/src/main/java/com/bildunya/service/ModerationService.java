package com.bildunya.service;

import com.bildunya.dto.ContentDto;
import com.bildunya.dto.ModerateContentRequest;
import com.bildunya.dto.ModerationItemDto;
import com.bildunya.entity.Content;
import com.bildunya.entity.CustomLocation;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.exception.UnauthorizedException;
import com.bildunya.repository.ContentRepository;
import com.bildunya.repository.CustomLocationRepository;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Transactional
public class ModerationService {

    private static final String TYPE_CONTENT = "CONTENT";
    private static final String TYPE_CUSTOM_LOCATION = "CUSTOM_LOCATION";
    private static final String STATUS_PENDING = "PENDING";
    private static final String STATUS_APPROVED = "APPROVED";
    private static final String STATUS_REJECTED = "REJECTED";
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    private final ContentService contentService;
    private final ContentRepository contentRepository;
    private final CustomLocationRepository customLocationRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public Page<ModerationItemDto> getPendingItems(String requesterUsername, Pageable pageable) {
        return getItemsByStatus(requesterUsername, STATUS_PENDING, pageable);
    }

    @Transactional(readOnly = true)
    public Page<ModerationItemDto> getItemsByStatus(String requesterUsername, String status, Pageable pageable) {
        assertAdminUsername(requesterUsername);
        String normalizedStatus = normalizeStatus(status);
        Pageable sortedPageable = PageRequest.of(
                Math.max(pageable.getPageNumber(), 0),
                pageable.getPageSize(),
                Sort.by(Sort.Direction.DESC, "createdAt"));

        int fetchSize = Math.max((int) sortedPageable.getOffset() + sortedPageable.getPageSize(), sortedPageable.getPageSize());
        Pageable sourcePageable = PageRequest.of(0, fetchSize, sortedPageable.getSort());

        List<ModerationRow> rows = new ArrayList<>();
        contentRepository.findByVerificationStatusAndIsDeletedFalse(normalizedStatus, sourcePageable)
                .forEach(content -> rows.add(new ModerationRow(content.getCreatedAt(), mapContent(content))));
        customLocationRepository.findByVerificationStatusAndIsDeletedFalse(normalizedStatus, sourcePageable)
                .forEach(location -> rows.add(new ModerationRow(location.getCreatedAt(), mapCustomLocation(location))));

        rows.sort(Comparator
                .comparing(ModerationRow::createdAt, Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparing(row -> row.item().getType())
                .thenComparing(row -> row.item().getId(), Comparator.nullsLast(Comparator.reverseOrder())));

        int start = Math.min((int) sortedPageable.getOffset(), rows.size());
        int end = Math.min(start + sortedPageable.getPageSize(), rows.size());
        List<ModerationItemDto> items = rows.subList(start, end)
                .stream()
                .map(ModerationRow::item)
                .toList();

        long total = contentRepository.countByVerificationStatusAndIsDeletedFalse(normalizedStatus)
                + customLocationRepository.countByVerificationStatusAndIsDeletedFalse(normalizedStatus);
        return new PageImpl<>(items, sortedPageable, total);
    }

    public ContentDto approveContent(String requesterUsername, Long contentId) {
        return contentService.moderateContent(
                requesterUsername,
                contentId,
                ModerateContentRequest.builder()
                        .verificationStatus("APPROVED")
                        .build());
    }

    public ModerationItemDto approveItem(String requesterUsername, String type, Long id) {
        assertAdminUsername(requesterUsername);
        String normalizedType = normalizeType(type);
        if (TYPE_CONTENT.equals(normalizedType)) {
            return mapContentDto(approveContent(requesterUsername, id));
        }

        CustomLocation location = customLocationRepository.findById(id)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Custom location not found"));
        location.setVerificationStatus(STATUS_APPROVED);
        location = customLocationRepository.save(location);
        return mapCustomLocation(location);
    }

    public ContentDto rejectContent(String requesterUsername, Long contentId, ModerateContentRequest request) {
        return contentService.moderateContent(
                requesterUsername,
                contentId,
                ModerateContentRequest.builder()
                        .verificationStatus("REJECTED")
                        .rejectionReason(request != null ? request.getRejectionReason() : null)
                        .build());
    }

    public ModerationItemDto rejectItem(String requesterUsername, String type, Long id, ModerateContentRequest request) {
        assertAdminUsername(requesterUsername);
        String normalizedType = normalizeType(type);
        if (TYPE_CONTENT.equals(normalizedType)) {
            return mapContentDto(rejectContent(requesterUsername, id, request));
        }

        CustomLocation location = customLocationRepository.findById(id)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Custom location not found"));
        location.setVerificationStatus(STATUS_REJECTED);
        location = customLocationRepository.save(location);
        return mapCustomLocation(location);
    }

    private void assertAdminUsername(String requesterUsername) {
        if (requesterUsername == null || requesterUsername.isBlank()) {
            throw new UnauthorizedException("Only admins can perform this action");
        }
        User user = userRepository.findByUsernameIgnoreCase(requesterUsername.trim()).orElse(null);
        if (user == null || Boolean.TRUE.equals(user.getIsDeleted()) || !Boolean.TRUE.equals(user.getIsActive())) {
            throw new UnauthorizedException("Only admins can perform this action");
        }
        String role = user.getRole();
        String normalizedRole = role == null ? "" : role.trim().toUpperCase(Locale.ROOT);
        if (normalizedRole.startsWith("ROLE_")) {
            normalizedRole = normalizedRole.substring("ROLE_".length());
        }
        if (!"ADMIN".equals(normalizedRole)) {
            throw new UnauthorizedException("Only admins can perform this action");
        }
    }

    private static String normalizeStatus(String status) {
        if (status == null || status.isBlank()) {
            return STATUS_PENDING;
        }
        String normalized = status.trim().toUpperCase(Locale.ROOT);
        if ("VERIFIED".equals(normalized)) {
            return STATUS_APPROVED;
        }
        return switch (normalized) {
            case STATUS_PENDING, STATUS_APPROVED, STATUS_REJECTED -> normalized;
            default -> throw new IllegalArgumentException("verificationStatus must be one of: PENDING, APPROVED, REJECTED");
        };
    }

    private static String normalizeType(String type) {
        if (type == null || type.isBlank()) {
            return TYPE_CONTENT;
        }
        String normalized = type.trim().toUpperCase(Locale.ROOT).replace('-', '_');
        return switch (normalized) {
            case "CONTENT", "POST" -> TYPE_CONTENT;
            case "CUSTOM_LOCATION", "LOCATION", "PIN" -> TYPE_CUSTOM_LOCATION;
            default -> throw new IllegalArgumentException("type must be one of: CONTENT, CUSTOM_LOCATION");
        };
    }

    private static ModerationItemDto mapContent(Content content) {
        User user = content.getUser();
        return ModerationItemDto.builder()
                .id(content.getId())
                .type(TYPE_CONTENT)
                .title(firstNonBlank(content.getLocationName(), content.getDescription(), "Paylaşım"))
                .description(content.getDescription())
                .contentType(content.getContentType())
                .fileUrl(content.getFileUrl())
                .latitude(content.getLatitude())
                .longitude(content.getLongitude())
                .locationName(content.getLocationName())
                .verificationStatus(content.getVerificationStatus())
                .rejectionReason(content.getRejectionReason())
                .userId(user != null ? user.getId() : null)
                .username(user != null ? user.getUsername() : null)
                .createdAt(format(content.getCreatedAt()))
                .build();
    }

    private static ModerationItemDto mapContentDto(ContentDto content) {
        return ModerationItemDto.builder()
                .id(content.getId())
                .type(TYPE_CONTENT)
                .title(firstNonBlank(content.getLocationName(), content.getDescription(), "Paylaşım"))
                .description(content.getDescription())
                .contentType(content.getContentType())
                .fileUrl(content.getFileUrl())
                .latitude(content.getLatitude())
                .longitude(content.getLongitude())
                .locationName(content.getLocationName())
                .verificationStatus(content.getVerificationStatus())
                .rejectionReason(content.getRejectionReason())
                .userId(content.getUser() != null ? content.getUser().getId() : null)
                .username(content.getUser() != null ? content.getUser().getUsername() : null)
                .createdAt(content.getCreatedAt())
                .build();
    }

    private static ModerationItemDto mapCustomLocation(CustomLocation location) {
        User user = location.getUser();
        return ModerationItemDto.builder()
                .id(location.getId())
                .type(TYPE_CUSTOM_LOCATION)
                .title(firstNonBlank(location.getName(), location.getDescription(), "Pin"))
                .description(location.getDescription())
                .contentType("CUSTOM_LOCATION")
                .fileUrl(location.getImageUrl())
                .latitude(location.getLatitude())
                .longitude(location.getLongitude())
                .locationName(location.getName())
                .verificationStatus(location.getVerificationStatus())
                .rejectionReason(null)
                .userId(user != null ? user.getId() : null)
                .username(user != null ? user.getUsername() : null)
                .createdAt(format(location.getCreatedAt()))
                .build();
    }

    private static String firstNonBlank(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        }
        return null;
    }

    private static String format(LocalDateTime value) {
        return value != null ? value.format(DATE_FORMATTER) : null;
    }

    private record ModerationRow(LocalDateTime createdAt, ModerationItemDto item) {
    }
}
