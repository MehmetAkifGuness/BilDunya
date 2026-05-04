import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ContentVerificationBadge extends StatelessWidget {
  const ContentVerificationBadge({
    super.key,
    required this.verificationStatus,
    this.isVerified,
    this.rejectionReason,
    this.compact = false,
  });

  final String? verificationStatus;
  final bool? isVerified;
  final String? rejectionReason;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = (verificationStatus ?? '').trim().toUpperCase();
    final verified =
        isVerified == true ||
        normalizedStatus == 'APPROVED' ||
        normalizedStatus == 'VERIFIED';

    if (verified) {
      return _BadgePill(
        label: compact ? 'Onay' : 'Doğrulandı',
        textColor: AppColors.primaryContainer,
        backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.2),
      );
    }

    if (normalizedStatus == 'REJECTED') {
      return Tooltip(
        message: _mapRejectionReason(rejectionReason),
        child: _BadgePill(
          label: compact ? 'Hatalı' : 'Doğrulama hatalı',
          textColor: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.18),
        ),
      );
    }

    if (normalizedStatus == 'PENDING') {
      return _BadgePill(
        label: compact ? 'Beklemede' : 'Doğrulama bekliyor',
        textColor: AppColors.secondary,
        backgroundColor: AppColors.surfaceContainerHigh,
      );
    }

    return const SizedBox.shrink();
  }

  static String _mapRejectionReason(String? rawReason) {
    final reason = (rawReason ?? '').trim().toUpperCase();
    if (reason == 'EXIF_LOCATION_MISMATCH') {
      return 'EXIF GPS konumu, seçilen konum ile uyuşmuyor.';
    }
    if (reason == 'MANUAL_MODERATOR_REJECTION') {
      return 'İçerik moderatör tarafından reddedildi.';
    }
    return 'İçerik doğrulaması başarısız.';
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
