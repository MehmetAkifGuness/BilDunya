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
public class ConversationSummaryDto {

    private Long id;

    @JsonProperty("other_user_id")
    private Long otherUserId;

    @JsonProperty("other_username")
    private String otherUsername;

    @JsonProperty("other_full_name")
    private String otherFullName;

    @JsonProperty("last_message")
    private String lastMessage;

    @JsonProperty("last_message_at")
    private String lastMessageAt;

    @JsonProperty("unread_count")
    private Long unreadCount;

    @JsonProperty("related_content_id")
    private Long relatedContentId;

    @JsonProperty("related_content_label")
    private String relatedContentLabel;
}

