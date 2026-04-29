package com.bildunya.service;

import org.apache.commons.io.FilenameUtils;
import com.bildunya.exception.ResourceNotFoundException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class FileStorageService {

    @Value("${file.upload.directory:uploads}")
    private String uploadDirectory;

    @Value("${file.upload.allowed-types:}")
    private String allowedTypes;

    public String store(MultipartFile file, String namePrefix) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is required");
        }

        String contentType = file.getContentType();
        if (contentType != null && !contentType.isBlank()) {
            Set<String> allowed = parseAllowedTypes(allowedTypes);
            if (!allowed.isEmpty() && !allowed.contains(contentType)) {
                throw new IllegalArgumentException("File type is not allowed: " + contentType);
            }
        }

        String originalName = file.getOriginalFilename();
        String extension = originalName != null ? FilenameUtils.getExtension(originalName) : "";

        String safePrefix = namePrefix == null ? "file" : namePrefix.replaceAll("[^a-zA-Z0-9_-]", "_");
        String filename = safePrefix + "_" + UUID.randomUUID() + (extension.isBlank() ? "" : "." + extension);

        Path uploadsPath = getUploadsPath();
        try {
            Files.createDirectories(uploadsPath);

            Path targetPath = uploadsPath.resolve(filename).normalize();
            if (!targetPath.startsWith(uploadsPath)) {
                throw new IllegalArgumentException("Invalid file name");
            }

            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, targetPath, StandardCopyOption.REPLACE_EXISTING);
            }

            return filename;
        } catch (IOException e) {
            throw new RuntimeException("Failed to store file", e);
        }
    }

    public Resource loadAsResource(String filename) {
        try {
            Path filePath = resolvePath(filename);
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists() && resource.isReadable()) {
                return resource;
            }
            throw new ResourceNotFoundException("File not found");
        } catch (MalformedURLException e) {
            throw new ResourceNotFoundException("File not found");
        }
    }

    public Path resolvePath(String filename) {
        Path uploadsPath = getUploadsPath();
        Path filePath = uploadsPath.resolve(filename).normalize();
        if (!filePath.startsWith(uploadsPath)) {
            throw new IllegalArgumentException("Invalid file name");
        }
        return filePath;
    }

    private Path getUploadsPath() {
        return Paths.get(uploadDirectory).toAbsolutePath().normalize();
    }

    private static Set<String> parseAllowedTypes(String csv) {
        if (csv == null || csv.isBlank()) {
            return Set.of();
        }
        return Arrays.stream(csv.split(","))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .collect(Collectors.toSet());
    }
}
