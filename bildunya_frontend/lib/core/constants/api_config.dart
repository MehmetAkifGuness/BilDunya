/// Spring Boot `server.servlet.context-path=/api` + Android emülatör loopback.
abstract final class ApiConfig {
  /// Tam API kökü (Dio `baseUrl`).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  /// `fileUrl` gibi `/api/uploads/...` path'leri için şema + host (context'siz kök).
  static String get mediaOrigin {
    final u = Uri.parse(baseUrl);
    return Uri(
      scheme: u.scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
    ).toString();
  }

  static String resolveFileUrl(String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) return '';
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    if (fileUrl.startsWith('/')) {
      return '$mediaOrigin$fileUrl';
    }
    return '$mediaOrigin/$fileUrl';
  }
}
