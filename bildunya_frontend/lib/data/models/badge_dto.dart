/// [com.bildunya.dto.BadgeDto]
class BadgeDto {
  const BadgeDto({
    this.icon,
    this.title,
    this.subtitle,
    this.unlocked = false,
  });

  final String? icon;
  final String? title;
  final String? subtitle;
  final bool unlocked;

  factory BadgeDto.fromJson(Map<String, dynamic> json) {
    return BadgeDto(
      icon: json['icon'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }
}
