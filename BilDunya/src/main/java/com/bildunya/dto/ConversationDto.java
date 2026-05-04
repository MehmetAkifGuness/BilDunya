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
public class ConversationDto {

    private Long id;

    @JsonProperty("user1_id")
    private Long user1Id;

    @JsonProperty("user2_id")
    private Long user2Id;

    @JsonProperty("other_user_id")
    private Long otherUserId;

    @JsonProperty("other_username")
    private String otherUsername;

    @JsonProperty("other_full_name")
    private String otherFullName;

    @JsonProperty("created_at")
    private String createdAt;

    @JsonProperty("related_content_id")
    private Long relatedContentId;

    @JsonProperty("related_content_label")
    private String relatedContentLabel;
}

