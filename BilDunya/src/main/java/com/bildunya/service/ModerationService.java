package com.bildunya.service;

import com.bildunya.dto.ContentDto;
import com.bildunya.dto.ModerateContentRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ModerationService {

    private final ContentService contentService;

    public Page<ContentDto> getPendingContent(String requesterUsername, Pageable pageable) {
        return contentService.getContentByVerificationStatusForModeration(
                requesterUsername,
                "PENDING",
                pageable);
    }

    public ContentDto approveContent(String requesterUsername, Long contentId) {
        return contentService.moderateContent(
                requesterUsername,
                contentId,
                ModerateContentRequest.builder()
                        .verificationStatus("APPROVED")
                        .build());
    }

    public ContentDto rejectContent(String requesterUsername, Long contentId, ModerateContentRequest request) {
        return contentService.moderateContent(
                requesterUsername,
                contentId,
                ModerateContentRequest.builder()
                        .verificationStatus("REJECTED")
                        .rejectionReason(request != null ? request.getRejectionReason() : null)
                        .build());
    }
}
