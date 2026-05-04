/// Sunucudan gelen ISO benzeri zamanı, DM listesi / balonunda kısa gösterime çevirir.
String formatDmTime(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '';
  try {
    final dt = DateTime.parse(s);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    if (d == today) return '$h:$min';
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == yesterday) return 'Dün';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  } catch (_) {
    return s;
  }
}
