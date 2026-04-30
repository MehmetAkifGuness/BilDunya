import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// Three-dot pager matching splash artboard (first segment wider).
class SplashPageIndicator extends StatelessWidget {
  const SplashPageIndicator({super.key, this.activeIndex = 0});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 6,
            width: active ? 40 : 12,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryContainer
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
          ),
        );
      }),
    );
  }
}
