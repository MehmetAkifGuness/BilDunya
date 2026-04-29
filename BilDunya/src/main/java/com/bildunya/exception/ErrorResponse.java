package com.bildunya.exception;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ErrorResponse {

    private int status;
    private String message;
    private String error;
    private LocalDateTime timestamp;
    private String path;
}
