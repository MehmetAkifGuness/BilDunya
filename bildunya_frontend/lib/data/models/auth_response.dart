import 'user_dto.dart';

/// [com.bildunya.dto.AuthResponse] ile uyumlu JSON.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.user,
  });

  final String accessToken;
  final String? tokenType;
  final int? expiresIn;
  final UserDto? user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
