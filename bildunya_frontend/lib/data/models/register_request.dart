/// [com.bildunya.dto.RegisterRequest]
class RegisterRequest {
  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.isAnonymous = false,
  });

  final String username;
  final String email;
  final String password;
  final String fullName;
  final bool isAnonymous;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
        'isAnonymous': isAnonymous,
      };
}
