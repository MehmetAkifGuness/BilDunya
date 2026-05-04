package com.bildunya.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ModerationItemDto {

    private Long id;
    private String type;
    private String title;
    private String description;

    @JsonProperty("content_type")
    private String contentType;

    @JsonProperty("file_url")
    private String fileUrl;

    private Double latitude;
    private Double longitude;

    @JsonProperty("location_name")
    private String locationName;

    @JsonProperty("verification_status")
    private String verificationStatus;

    @JsonProperty("rejection_reason")
    private String rejectionReason;

    @JsonProperty("user_id")
    private Long userId;

    @JsonProperty("username")
    private String username;

    @JsonProperty("created_at")
    private String createdAt;
}
