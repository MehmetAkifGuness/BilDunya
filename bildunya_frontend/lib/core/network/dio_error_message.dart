import 'package:dio/dio.dart';

String dioErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'] ?? data['error'] ?? data['detail'];
    if (msg is String && msg.isNotEmpty) return msg;
    if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
      return (data['errors'] as List).first.toString();
    }
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
