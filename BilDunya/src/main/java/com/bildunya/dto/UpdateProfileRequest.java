package com.bildunya.dto;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateProfileRequest {

    @Size(min = 2, max = 100, message = "Full name must be between 2 and 100 characters")
    private String fullName;

    @Size(max = 500, message = "Bio must be at most 500 characters")
    private String bio;

    @Size(max = 20, message = "Phone number must be at most 20 characters")
    private String phoneNumber;

    private Boolean isAnonymous;

    private String locationPreferences;
}

