/// [com.bildunya.dto.UserDto] ile uyumlu JSON.
class UserDto {
  const UserDto({
    this.id,
    this.username,
    this.email,
    this.fullName,
    this.profilePhotoUrl,
    this.bio,
    this.isAnonymous,
    this.isActive,
    this.phoneNumber,
    this.createdAt,
  });

  final int? id;
  final String? username;
  final String? email;
  final String? fullName;
  final String? profilePhotoUrl;
  final String? bio;
  final bool? isAnonymous;
  final bool? isActive;
  final String? phoneNumber;
  final String? createdAt;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: (json['id'] as num?)?.toInt(),
      username: json['username'] as String?,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      bio: json['bio'] as String?,
      isAnonymous: json['isAnonymous'] as bool?,
      isActive: json['isActive'] as bool?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'profilePhotoUrl': profilePhotoUrl,
        'bio': bio,
        'isAnonymous': isAnonymous,
        'isActive': isActive,
        'phoneNumber': phoneNumber,
        'created_at': createdAt,
      };

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!.trim();
    if (username != null && username!.trim().isNotEmpty) return username!.trim();
    return 'Gezgin';
  }
}
