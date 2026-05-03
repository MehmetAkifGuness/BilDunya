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
public class ChatMessageDto {

    private Long id;

    @JsonProperty("conversation_id")
    private Long conversationId;

    @JsonProperty("sender_username")
    private String senderUsername;

    @JsonProperty("receiver_username")
    private String receiverUsername;

    private String text;

    @JsonProperty("is_read")
    private Boolean isRead;

    @JsonProperty("created_at")
    private String createdAt;
}
