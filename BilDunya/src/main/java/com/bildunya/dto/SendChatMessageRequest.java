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
public class SendChatMessageRequest {

    @NotBlank(message = "Receiver username is required")
    private String receiverUsername;

    @NotBlank(message = "Text is required")
    @Size(max = 2000, message = "Text must be at most 2000 characters")
    private String text;
}

