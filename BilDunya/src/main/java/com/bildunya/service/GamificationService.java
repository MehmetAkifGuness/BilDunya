package com.bildunya.service;

import com.bildunya.dto.BadgeDto;
import com.bildunya.dto.UserGamificationDto;
import com.bildunya.entity.User;
import com.bildunya.exception.ResourceNotFoundException;
import com.bildunya.repository.ContentRepository;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GamificationService {

    private final UserRepository userRepository;
    private final ContentRepository contentRepository;

    public UserGamificationDto buildForUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        long totalPosts = contentRepository.countByUserAndIsDeletedFalse(user);
        long distinctLocations = contentRepository.countDistinctLocationNames(user);
        long mediaPosts = contentRepository.countWithUploadedMedia(user);
        long historicThemed = contentRepository.countHistoricThemed(user);
        long verified = contentRepository.countVerifiedByUser(user);

        List<BadgeDto> badges = new ArrayList<>();
        badges.add(BadgeDto.builder()
                .icon("public")
                .title("Dünya Gezgini")
                .subtitle(distinctLocations + " farklı konum")
                .unlocked(distinctLocations >= 3)
                .build());
        badges.add(BadgeDto.builder()
                .icon("castle")
                .title("Şehir Tarihçisi")
                .subtitle(historicThemed + " tarih temalı paylaşım")
                .unlocked(historicThemed >= 5)
                .build());
        badges.add(BadgeDto.builder()
                .icon("photo_camera")
                .title("Görsel Anlatıcı")
                .subtitle(mediaPosts + " medyalı paylaşım")
                .unlocked(mediaPosts >= 10)
                .build());
        badges.add(BadgeDto.builder()
                .icon(totalPosts >= 30 ? "landscape" : "lock")
                .title("Zirve Fatihi")
                .subtitle(totalPosts >= 30 ? "30+ paylaşım" : "Kilitli (" + totalPosts + "/30)")
                .unlocked(totalPosts >= 30)
                .build());

        String goalTitle;
        String goalDetail;
        double progress;

        if (distinctLocations < 5) {
            goalTitle = "Daha çok lokasyon keşfet";
            goalDetail = distinctLocations + "/5 farklı konum";
            progress = Math.min(1.0, distinctLocations / 5.0);
        } else if (totalPosts < 20) {
            goalTitle = "Paylaşımlarını çoğalt";
            goalDetail = totalPosts + "/20 paylaşım";
            progress = Math.min(1.0, totalPosts / 20.0);
        } else if (verified < 5) {
            goalTitle = "Doğrulanmış içerik kazan";
            goalDetail = verified + "/5 onaylı paylaşım";
            progress = Math.min(1.0, verified / 5.0);
        } else {
            goalTitle = "BilDünya yolculuğuna devam";
            goalDetail = totalPosts + " paylaşım · " + distinctLocations + " konum";
            progress = 1.0;
        }

        return UserGamificationDto.builder()
                .badges(badges)
                .currentGoalTitle(goalTitle)
                .currentProgress(progress)
                .currentGoalDetail(goalDetail)
                .totalPosts(totalPosts)
                .distinctLocationCount(distinctLocations)
                .verifiedContentCount(verified)
                .mediaPostCount(mediaPosts)
                .historicThemedCount(historicThemed)
                .build();
    }
}
