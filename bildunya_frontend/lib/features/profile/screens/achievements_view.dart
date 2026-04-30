import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../map/map_view.dart';
import '../providers/profile_provider.dart';

/// Başarılar: backend `GET /users/me/gamification` verisi.
class AchievementsView extends StatelessWidget {
  const AchievementsView({super.key});

  static const _mapPreviewUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBZ8F1cOrKa1MbHVLBmtSILdtQEP4TBYLdL6qdpjGsQ0rhNrjnVJuUa88uu5IehiigPykOTY4Ew3UyNN4lY3hKTxWZszR_D-PH0j9ZeriiaHP5cxGUe3fII8d8T-eDTRKVA14V3NBjycHB7zenDbKzzelXdnWoanXxqCXEiAtKbGNtrWMWCZtEfDG-knkdegZoIfNwxq2McgTBdU83TWL1JLxYAYzlTuQPMVVKS2md0RestacV61fhWhv_D2Rc4ZjQZCXEjCXkjszQ';

  static IconData _iconForBadge(String? key) {
    switch (key) {
      case 'castle':
        return Symbols.castle;
      case 'photo_camera':
        return Symbols.photo_camera;
      case 'lock':
        return Symbols.lock;
      case 'landscape':
        return Symbols.landscape;
      case 'public':
      default:
        return Symbols.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Başarılar ve Rozetler',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Symbols.workspace_premium, color: AppColors.primaryContainer),
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          if (profile.loading && profile.gamification == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final g = profile.gamification;
          if (g == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.error ?? 'Başarı verisi yüklenemedi.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => profile.load(),
                      child: const Text('Yenile'),
                    ),
                  ],
                ),
              ),
            );
          }

          final progress = g.currentProgress.clamp(0.0, 1.0);
          final badges = g.badges;

          return RefreshIndicator(
            color: AppColors.primaryContainer,
            onRefresh: profile.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, i) {
                    final b = badges[i];
                    return _BadgeCard(
                      icon: _iconForBadge(b.icon),
                      title: b.title ?? '',
                      subtitle: b.subtitle ?? '',
                      locked: !b.unlocked,
                    );
                  },
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryContainer.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        ),
                        color: AppColors.surfaceContainer.withValues(alpha: 0.55),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEVCUT HEDEF',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            g.currentGoalTitle ?? '',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceContainerHigh,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            g.currentGoalDetail ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _mapPreviewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                            color: AppColors.surfaceContainer,
                            child: Center(
                              child: Icon(
                                Symbols.map,
                                size: 48,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryContainer,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => Scaffold(
                                        backgroundColor:
                                            AppColors.surfaceContainerLowest,
                                        body: const SafeArea(child: MapView()),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Harita Detaylarını Gör',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.locked,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: locked ? 0.4 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.surfaceContainer
                    : AppColors.primaryContainer.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: locked ? AppColors.secondary : AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
