package com.bildunya.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateConversationRequest {

    @NotBlank(message = "Other username is required")
    private String otherUsername;

    /** İsteğe bağlı: sohbetin bağlandığı içerik (gönderi) kimliği. */
    private Long relatedContentId;
}

