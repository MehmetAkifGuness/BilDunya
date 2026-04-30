import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

class GradientAuthButton extends StatelessWidget {
  const GradientAuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 56,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Alignment begin;
  final Alignment end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: const [AppColors.primary, AppColors.primaryContainer],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
