package com.bildunya.repository;

import com.bildunya.entity.CustomLocation;
import com.bildunya.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomLocationRepository extends JpaRepository<CustomLocation, Long> {

    @Query(value = "SELECT * FROM custom_locations l " +
            "WHERE l.is_deleted = false AND " +
            "l.latitude BETWEEN :minLat AND :maxLat AND " +
            "( " +
            "(:wrapsLon = false AND l.longitude BETWEEN :minLon AND :maxLon) OR " +
            "(:wrapsLon = true AND (l.longitude >= :minLon OR l.longitude <= :maxLon)) " +
            ") AND " +
            "(6371 * acos(least(greatest(" +
            "cos(radians(:latitude)) * cos(radians(l.latitude)) * cos(radians(l.longitude) - radians(:longitude)) + " +
            "sin(radians(:latitude)) * sin(radians(l.latitude))" +
            ", -1), 1))) <= :radiusKm",
            countQuery = "SELECT count(*) FROM custom_locations l " +
                    "WHERE l.is_deleted = false AND " +
                    "l.latitude BETWEEN :minLat AND :maxLat AND " +
                    "( " +
                    "(:wrapsLon = false AND l.longitude BETWEEN :minLon AND :maxLon) OR " +
                    "(:wrapsLon = true AND (l.longitude >= :minLon OR l.longitude <= :maxLon)) " +
                    ") AND " +
                    "(6371 * acos(least(greatest(" +
                    "cos(radians(:latitude)) * cos(radians(l.latitude)) * cos(radians(l.longitude) - radians(:longitude)) + " +
                    "sin(radians(:latitude)) * sin(radians(l.latitude))" +
                    ", -1), 1))) <= :radiusKm",
            nativeQuery = true)
    Page<CustomLocation> findNearbyCustomLocations(@Param("latitude") Double latitude,
                                                  @Param("longitude") Double longitude,
                                                  @Param("radiusKm") Double radiusKm,
                                                  @Param("minLat") Double minLat,
                                                  @Param("maxLat") Double maxLat,
                                                  @Param("minLon") Double minLon,
                                                  @Param("maxLon") Double maxLon,
                                                  @Param("wrapsLon") Boolean wrapsLon,
                                                  Pageable pageable);

    @Query(value = "SELECT * FROM custom_locations l " +
            "WHERE l.is_deleted = false AND l.user_id = :userId AND " +
            "l.latitude BETWEEN :minLat AND :maxLat AND " +
            "( " +
            "(:wrapsLon = false AND l.longitude BETWEEN :minLon AND :maxLon) OR " +
            "(:wrapsLon = true AND (l.longitude >= :minLon OR l.longitude <= :maxLon)) " +
            ") AND " +
            "(6371 * acos(least(greatest(" +
            "cos(radians(:latitude)) * cos(radians(l.latitude)) * cos(radians(l.longitude) - radians(:longitude)) + " +
            "sin(radians(:latitude)) * sin(radians(l.latitude))" +
            ", -1), 1))) <= :radiusKm",
            countQuery = "SELECT count(*) FROM custom_locations l " +
                    "WHERE l.is_deleted = false AND l.user_id = :userId AND " +
                    "l.latitude BETWEEN :minLat AND :maxLat AND " +
                    "( " +
                    "(:wrapsLon = false AND l.longitude BETWEEN :minLon AND :maxLon) OR " +
                    "(:wrapsLon = true AND (l.longitude >= :minLon OR l.longitude <= :maxLon)) " +
                    ") AND " +
                    "(6371 * acos(least(greatest(" +
                    "cos(radians(:latitude)) * cos(radians(l.latitude)) * cos(radians(l.longitude) - radians(:longitude)) + " +
                    "sin(radians(:latitude)) * sin(radians(l.latitude))" +
                    ", -1), 1))) <= :radiusKm",
            nativeQuery = true)
    Page<CustomLocation> findNearbyCustomLocationsForUser(@Param("userId") Long userId,
                                                         @Param("latitude") Double latitude,
                                                         @Param("longitude") Double longitude,
                                                         @Param("radiusKm") Double radiusKm,
                                                         @Param("minLat") Double minLat,
                                                         @Param("maxLat") Double maxLat,
                                                         @Param("minLon") Double minLon,
                                                         @Param("maxLon") Double maxLon,
                                                         @Param("wrapsLon") Boolean wrapsLon,
                                                         Pageable pageable);

    Page<CustomLocation> findByUserAndIsDeletedFalse(User user, Pageable pageable);
}

