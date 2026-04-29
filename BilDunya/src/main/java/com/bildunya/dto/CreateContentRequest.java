package com.bildunya.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateContentRequest {

    @NotBlank(message = "Description is required")
    private String description;

    @NotNull(message = "Content type is required")
    private String contentType;

    @NotNull(message = "Latitude is required")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    private Double longitude;

    private String locationName;
    private String shareType; // PUBLIC, PRIVATE, ANONYMOUS
    private String tags;
}
