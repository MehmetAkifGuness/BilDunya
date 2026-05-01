import 'user_dto.dart';

/// [com.bildunya.dto.AuthResponse] ile uyumlu JSON.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.refreshToken,
    this.refreshExpiresIn,
    this.user,
  });

  final String accessToken;
  final String? tokenType;
  final int? expiresIn;
  final String? refreshToken;
  final int? refreshExpiresIn;
  final UserDto? user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      refreshToken: json['refresh_token'] as String?,
      refreshExpiresIn: (json['refresh_expires_in'] as num?)?.toInt(),
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
