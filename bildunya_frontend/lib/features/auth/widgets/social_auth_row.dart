import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
/// Circular OAuth-style actions (HTML uses Material Symbols google/apple;
/// brand glyphs are not in [Symbols], so we match layout with G + Apple).
class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({
    super.key,
    this.onGoogle,
    this.onApple,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialCircle(
          onTap: onGoogle,
          child: Text(
            'G',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 20),
        _SocialCircle(
          onTap: onApple,
          child: Icon(
            Icons.apple,
            size: 28,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      shape: const CircleBorder(
        side: BorderSide(
          color: Color(0x33504532),
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(child: child),
        ),
      ),
    );
  }
}
