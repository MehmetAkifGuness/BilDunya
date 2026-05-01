package com.bildunya.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ModerateContentRequest {

    @NotBlank(message = "verificationStatus is required")
    private String verificationStatus; // VERIFIED, REJECTED

    @Size(max = 500, message = "rejectionReason must be at most 500 characters")
    private String rejectionReason;
}
