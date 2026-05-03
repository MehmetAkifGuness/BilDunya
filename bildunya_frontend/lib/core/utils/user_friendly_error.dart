String userFriendlyErrorMessage(Object error) {
  final raw = error.toString().trim();
  if (raw.isEmpty) return 'Beklenmeyen bir hata oluştu.';

  var message = raw;
  final match = RegExp(r'^[A-Za-z0-9_]+(\s*\[[^\]]+\])?:\s*(.*)$')
      .firstMatch(raw);
  if (match != null) {
    final candidate = (match.group(2) ?? '').trim();
    if (candidate.isNotEmpty) message = candidate;
  }

  final platformMatch = RegExp(r'^PlatformException\([^,]*,\s*([^,]*?)\s*,')
      .firstMatch(message);
  if (platformMatch != null) {
    final extracted = (platformMatch.group(1) ?? '').trim();
    if (extracted.isNotEmpty && extracted.toLowerCase() != 'null') {
      message = extracted;
    }
  }

  final lower = message.toLowerCase().trim();
  if (lower.contains('permission') && lower.contains('denied')) {
    return 'İzin reddedildi. Ayarlardan izin verip tekrar deneyin.';
  }
  if (lower.contains('not authorized') || lower.contains('unauthorized')) {
    return 'Bu işlem için yetkiniz yok. Lütfen tekrar giriş yapın.';
  }
  if (lower == 'an unexpected error occurred') {
    return 'Sunucuda bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
  }

  return message.isNotEmpty ? message : 'Beklenmeyen bir hata oluştu.';
}
