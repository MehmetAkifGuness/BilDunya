import 'package:dio/dio.dart';

String dioErrorMessage(DioException e) {
  final statusCode = e.response?.statusCode;
  final data = e.response?.data;

  String? extractedMessage;
  if (data is Map<String, dynamic>) {
    final msg = data['message'] ?? data['error'] ?? data['detail'];
    if (msg is String && msg.isNotEmpty) extractedMessage = msg;
    if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
      extractedMessage = (data['errors'] as List).first.toString();
    }
  }

  if (statusCode == 401 || statusCode == 403) {
    final m = (extractedMessage ?? '').trim();
    if (m.isNotEmpty &&
        m.toLowerCase() != 'forbidden' &&
        m.toLowerCase() != 'unauthorized') {
      return m;
    }
    return 'Oturum bulunamadı / süresi dolmuş olabilir. Lütfen tekrar giriş yap.';
  }

  if (extractedMessage != null && extractedMessage.isNotEmpty) {
    return extractedMessage;
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'Bağlantı zaman aşımı. Sunucuyu kontrol edin.';
  }
  if (e.type == DioExceptionType.connectionError) {
    return 'Sunucuya bağlanılamadı. Ağ veya API adresini kontrol edin.';
  }
  return e.message ?? 'Beklenmeyen bir hata oluştu.';
}
