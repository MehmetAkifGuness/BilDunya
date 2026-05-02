/// Spring Boot `server.servlet.context-path=/api` + Android emülatör/fiziksel cihaz bağlantısı.
abstract final class ApiConfig {
  /// Tam API kökü (Dio `baseUrl`).

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // BURAYI GÜNCELLEDİK: Emülatörün bilgisayarındaki 8080'e erişmesi için 10.0.2.2 şart.
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

  /// STOMP native WebSocket URL (`server.servlet.context-path` + `/ws`).
  static String get stompWsUrl {
    const fromEnv = String.fromEnvironment('API_WS_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    final u = Uri.parse(baseUrl);
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    var path = u.path;
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final wsPath = path.isEmpty ? '/ws' : '$path/ws';
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: wsPath,
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
