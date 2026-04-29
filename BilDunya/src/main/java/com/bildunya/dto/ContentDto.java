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
public class ContentDto {

    private Long id;
    private String description;
    
    @JsonProperty("content_type")
    private String contentType;
    
    @JsonProperty("file_url")
    private String fileUrl;

    private Double latitude;
    private Double longitude;

    @JsonProperty("location_name")
    private String locationName;

    @JsonProperty("is_verified")
    private Boolean isVerified;

    @JsonProperty("verification_status")
    private String verificationStatus;

    @JsonProperty("view_count")
    private Long viewCount;

    @JsonProperty("share_type")
    private String shareType;

    private String tags;

    @JsonProperty("user")
    private UserDto user;

    @JsonProperty("created_at")
    private String createdAt;
}
