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
public class BadgeDto {

    /** Material Symbols adı: public, castle, photo_camera, lock */
    private String icon;

    private String title;

    private String subtitle;

    @JsonProperty("unlocked")
    private boolean unlocked;
}
