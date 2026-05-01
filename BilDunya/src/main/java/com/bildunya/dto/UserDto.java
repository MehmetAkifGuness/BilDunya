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
public class UserDto {

    private Long id;
    private String username;
    private String email;
    private String fullName;
    private String profilePhotoUrl;
    private String bio;
    private Boolean isAnonymous;
    private Boolean isActive;
    private Boolean emailVerified;
    private String role;
    private String phoneNumber;
    private String locationPreferences;

    @JsonProperty("created_at")
    private String createdAt;
}
