package com.bildunya.repository;

import com.bildunya.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByTokenHashAndRevokedFalseAndIsDeletedFalse(String tokenHash);

    List<RefreshToken> findAllByUserIdAndRevokedFalseAndIsDeletedFalse(Long userId);

    long countByUserIdAndRevokedFalseAndIsDeletedFalse(Long userId);

    void deleteByExpiresAtBefore(LocalDateTime cutoff);
}
