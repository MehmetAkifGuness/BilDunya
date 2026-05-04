package com.bildunya.service;

import com.bildunya.exception.FileUploadException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
public class FileStorageService {

    private final Cloudinary cloudinary;

    public FileStorageService(@Value("${cloudinary.url}") String cloudinaryUrl) {
        this.cloudinary = new Cloudinary(cloudinaryUrl);
    }

    public String store(MultipartFile file, String namePrefix) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("Dosya boş olamaz.");
        }

        try {
            Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "folder", "bildunya_uploads",
                    "resource_type", "auto"
            ));

            return uploadResult.get("secure_url").toString();

        } catch (IOException e) {
            throw new FileUploadException("Dosya yüklenemedi. Lütfen daha sonra tekrar deneyin.", e);
        } catch (Exception e) {
            throw new FileUploadException("Dosya yüklenemedi. Lütfen daha sonra tekrar deneyin.", e);
        }
    }
}
