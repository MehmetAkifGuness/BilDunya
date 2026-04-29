package com.bildunya.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "contents", indexes = {
        @Index(name = "idx_user_id", columnList = "user_id"),
        @Index(name = "idx_latitude_longitude", columnList = "latitude,longitude"),
        @Index(name = "idx_created_at", columnList = "created_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = true)
public class Content extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "content_type", nullable = false)
    private String contentType; // IMAGE, VIDEO, TEXT

    @Column(name = "file_url")
    private String fileUrl;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(name = "location_name")
    private String locationName;

    @Column(name = "exif_data", columnDefinition = "jsonb")
    private String exifData;

    @Column(name = "is_verified", nullable = false)
    private Boolean isVerified = false;

    @Column(name = "verification_status")
    private String verificationStatus; // PENDING, VERIFIED, REJECTED

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "view_count", nullable = false)
    private Long viewCount = 0L;

    @Column(name = "share_type", nullable = false)
    private String shareType; // PUBLIC, PRIVATE, ANONYMOUS

    @Column(name = "tags", columnDefinition = "TEXT")
    private String tags; // Comma-separated
}
