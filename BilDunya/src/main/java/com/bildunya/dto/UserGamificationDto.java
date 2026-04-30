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
public class UserGamificationDto {

    private List<BadgeDto> badges;

    @JsonProperty("current_goal_title")
    private String currentGoalTitle;

    /** 0.0 – 1.0 */
    @JsonProperty("current_progress")
    private double currentProgress;

    @JsonProperty("current_goal_detail")
    private String currentGoalDetail;

    @JsonProperty("total_posts")
    private long totalPosts;

    @JsonProperty("distinct_location_count")
    private long distinctLocationCount;

    @JsonProperty("verified_content_count")
    private long verifiedContentCount;

    @JsonProperty("media_post_count")
    private long mediaPostCount;

    @JsonProperty("historic_themed_count")
    private long historicThemedCount;
}
