package com.bildunya.controller;

import com.bildunya.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@RestController
@RequestMapping("/uploads")
@RequiredArgsConstructor
@Tag(name = "Uploads", description = "Serve uploaded files")
@CrossOrigin(origins = "*", maxAge = 3600)
public class UploadController {

    private final FileStorageService fileStorageService;

    @GetMapping("/{filename:.+}")
    @Operation(summary = "Get an uploaded file")
    public ResponseEntity<Resource> getFile(@PathVariable String filename) throws IOException {
        Resource resource = fileStorageService.loadAsResource(filename);

        Path filePath = fileStorageService.resolvePath(filename);
        String contentType = Files.probeContentType(filePath);
        if (contentType == null || contentType.isBlank()) {
            contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
        }

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                .body(resource);
    }
}

