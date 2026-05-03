package com.bildunya.controller;

import com.bildunya.dto.CreateCustomLocationRequest;
import com.bildunya.dto.CustomLocationDto;
import com.bildunya.security.UserPrincipal;
import com.bildunya.service.CustomLocationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/custom-locations")
@RequiredArgsConstructor
@Tag(name = "Custom Locations", description = "User-created map pins")
@CrossOrigin(origins = "*", maxAge = 3600)
public class CustomLocationController {

    private final CustomLocationService customLocationService;

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Create new custom location")
    public ResponseEntity<CustomLocationDto> create(@Valid @RequestBody CreateCustomLocationRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        CustomLocationDto created = customLocationService.createCustomLocation(principal.getUsername(), request);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Create new custom location with image upload")
    public ResponseEntity<CustomLocationDto> createWithImage(
            @Valid @RequestPart("data") CreateCustomLocationRequest request,
            @RequestPart(value = "file", required = false) MultipartFile file) {

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        CustomLocationDto created = customLocationService.createCustomLocationWithImage(principal.getUsername(), request, file);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get custom location by ID")
    public ResponseEntity<CustomLocationDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(customLocationService.getById(id));
    }

    @GetMapping("/nearby")
    @Operation(summary = "Get nearby custom locations")
    public ResponseEntity<Page<CustomLocationDto>> getNearby(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "5") Double radiusKm,
            @RequestParam(defaultValue = "false") boolean mineOnly,
            Authentication authentication,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "100") Integer size,
            @RequestParam(defaultValue = "created_at") String sortBy) {

        String username = null;
        if (mineOnly && authentication != null && authentication.getPrincipal() instanceof UserPrincipal principal) {
            username = principal.getUsername();
        }

        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).descending());
        Page<CustomLocationDto> locations = customLocationService.getNearby(
                latitude,
                longitude,
                radiusKm,
                mineOnly,
                username,
                pageable);
        return ResponseEntity.ok(locations);
    }

    @DeleteMapping("/{id}")
    @SecurityRequirement(name = "Bearer Authentication")
    @Operation(summary = "Delete custom location (owner only)")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        customLocationService.delete(id, principal.getUsername());
        return ResponseEntity.noContent().build();
    }
}

