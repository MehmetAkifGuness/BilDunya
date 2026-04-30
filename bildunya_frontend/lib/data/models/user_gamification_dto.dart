import 'badge_dto.dart';

/// [com.bildunya.dto.UserGamificationDto] — Jackson `@JsonProperty` alanları.
class UserGamificationDto {
  const UserGamificationDto({
    required this.badges,
    this.currentGoalTitle,
    this.currentProgress = 0,
    this.currentGoalDetail,
    this.totalPosts = 0,
    this.distinctLocationCount = 0,
    this.verifiedContentCount = 0,
    this.mediaPostCount = 0,
    this.historicThemedCount = 0,
  });

  final List<BadgeDto> badges;
  final String? currentGoalTitle;
  final double currentProgress;
  final String? currentGoalDetail;
  final int totalPosts;
  final int distinctLocationCount;
  final int verifiedContentCount;
  final int mediaPostCount;
  final int historicThemedCount;

  factory UserGamificationDto.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'];
    final badges = <BadgeDto>[];
    if (rawBadges is List) {
      for (final e in rawBadges) {
        if (e is Map<String, dynamic>) {
          badges.add(BadgeDto.fromJson(e));
        }
      }
    }
    return UserGamificationDto(
      badges: badges,
      currentGoalTitle: json['current_goal_title'] as String? ??
          json['currentGoalTitle'] as String?,
      currentProgress: (json['current_progress'] as num?)?.toDouble() ??
          (json['currentProgress'] as num?)?.toDouble() ??
          0,
      currentGoalDetail: json['current_goal_detail'] as String? ??
          json['currentGoalDetail'] as String?,
      totalPosts: (json['total_posts'] as num?)?.toInt() ??
          (json['totalPosts'] as num?)?.toInt() ??
          0,
      distinctLocationCount:
          (json['distinct_location_count'] as num?)?.toInt() ??
              (json['distinctLocationCount'] as num?)?.toInt() ??
              0,
      verifiedContentCount:
          (json['verified_content_count'] as num?)?.toInt() ??
              (json['verifiedContentCount'] as num?)?.toInt() ??
              0,
      mediaPostCount: (json['media_post_count'] as num?)?.toInt() ??
          (json['mediaPostCount'] as num?)?.toInt() ??
          0,
      historicThemedCount:
          (json['historic_themed_count'] as num?)?.toInt() ??
              (json['historicThemedCount'] as num?)?.toInt() ??
              0,
    );
  }
}
