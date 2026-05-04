import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// Geçici story yanıtı bağlamında, composer üstünde hızlı mesaj önerileri.
class ChatIcebreakersBar extends StatelessWidget {
  const ChatIcebreakersBar({
    super.key,
    required this.onPick,
    this.enabled = true,
  });

  final ValueChanged<String> onPick;
  final bool enabled;

  static const List<String> suggestions = [
    'Burası kalabalık mı?',
    'Otopark var mı?',
    'Fotoğrafı hangi kamerayla çektin?',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (var i = 0; i < suggestions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            OutlinedButton(
              onPressed: enabled ? () => onPick(suggestions[i]) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                backgroundColor: AppColors.surfaceContainerLow.withValues(
                  alpha: 0.6,
                ),
              ),
              child: Text(
                suggestions[i],
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
