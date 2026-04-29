package com.bildunya.repository;

import com.bildunya.entity.Content;
import com.bildunya.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContentRepository extends JpaRepository<Content, Long> {

    Page<Content> findByUser(User user, Pageable pageable);

    Page<Content> findByIsDeletedFalse(Pageable pageable);

    @Query(value = "SELECT * FROM contents c " +
            "WHERE c.is_deleted = false AND " +
            "c.latitude BETWEEN :minLat AND :maxLat AND " +
            "( " +
            "(:wrapsLon = false AND c.longitude BETWEEN :minLon AND :maxLon) OR " +
            "(:wrapsLon = true AND (c.longitude >= :minLon OR c.longitude <= :maxLon)) " +
            ") AND " +
            "(6371 * acos(least(greatest(" +
            "cos(radians(:latitude)) * cos(radians(c.latitude)) * cos(radians(c.longitude) - radians(:longitude)) + " +
            "sin(radians(:latitude)) * sin(radians(c.latitude))" +
            ", -1), 1))) <= :radiusKm",
            countQuery = "SELECT count(*) FROM contents c " +
                    "WHERE c.is_deleted = false AND " +
                    "c.latitude BETWEEN :minLat AND :maxLat AND " +
                    "( " +
                    "(:wrapsLon = false AND c.longitude BETWEEN :minLon AND :maxLon) OR " +
                    "(:wrapsLon = true AND (c.longitude >= :minLon OR c.longitude <= :maxLon)) " +
                    ") AND " +
                    "(6371 * acos(least(greatest(" +
                    "cos(radians(:latitude)) * cos(radians(c.latitude)) * cos(radians(c.longitude) - radians(:longitude)) + " +
                    "sin(radians(:latitude)) * sin(radians(c.latitude))" +
                    ", -1), 1))) <= :radiusKm",
            nativeQuery = true)
    Page<Content> findNearbyContent(@Param("latitude") Double latitude,
                                     @Param("longitude") Double longitude,
                                     @Param("radiusKm") Double radiusKm,
                                     @Param("minLat") Double minLat,
                                     @Param("maxLat") Double maxLat,
                                     @Param("minLon") Double minLon,
                                     @Param("maxLon") Double maxLon,
                                     @Param("wrapsLon") Boolean wrapsLon,
                                     Pageable pageable);

    @Query("SELECT c FROM Content c WHERE c.isDeleted = false AND c.verificationStatus = 'VERIFIED'")
    Page<Content> findVerifiedContent(Pageable pageable);

    List<Content> findByVerificationStatus(String verificationStatus);
}
