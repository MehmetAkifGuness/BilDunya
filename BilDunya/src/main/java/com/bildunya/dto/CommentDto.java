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
public class CommentDto {

    private Long id;

    @JsonProperty("content_id")
    private Long contentId;

    @JsonProperty("parent_comment_id")
    private Long parentCommentId;

    private String text;

    @JsonProperty("is_anonymous")
    private Boolean isAnonymous;

    @JsonProperty("like_count")
    private Long likeCount;

    private UserDto user;

    @JsonProperty("created_at")
    private String createdAt;
}

