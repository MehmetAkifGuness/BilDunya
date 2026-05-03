package com.bildunya.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomLocationDto {

    private Long id;

    @JsonProperty("user_id")
    private Long userId;

    private String name;
    private String description;
    private Double latitude;
    private Double longitude;

    @JsonProperty("image_url")
    private String imageUrl;

    private List<String> tags;

    @JsonProperty("created_at")
    private String createdAt;
}

