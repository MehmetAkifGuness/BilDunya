import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/widgets/content_verification_badge.dart';
import '../../data/models/content_dto.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/screens/login_screen.dart';
import '../content/providers/contents_provider.dart';
import '../content/screens/content_detail_view.dart';

/// Ana sayfa: karşılama + önerilen / yakın içerikler.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    final provider = context.read<ContentsProvider>();
    await provider.loadRecommended();
    await provider.loadNearby(
      latitude: 38.6431,
      longitude: 34.8282,
      radiusKm: 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final contents = context.watch<ContentsProvider>();

    final recommendedEmpty = contents.recommended.isEmpty;
    final listToShow = recommendedEmpty
        ? contents.nearby
        : contents.recommended;
    final loading = contents.loadingRecommended || contents.loadingNearby;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'BilDünya',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName,
                (route) => false,
              );
            },
            icon: const Icon(Symbols.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryContainer,
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Hoş Geldin Gezgin',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              auth.user?.displayName != null
                  ? '${auth.user!.displayName}, keşfe hazır mısın?'
                  : 'Kapadokya ve ötesinde yeni rotalar seni bekliyor.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.secondary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 28),
            if ((auth.user?.locationPreferences ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Tercihlerin: ${auth.user!.locationPreferences}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  recommendedEmpty
                      ? 'Yakınındaki içerikler'
                      : 'Sana önerilen içerikler',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendedEmpty && contents.recommendedError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  contents.recommendedError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            if (contents.nearbyError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  contents.nearbyError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ...listToShow.map((c) => _NearbyTile(content: c)),
            if (!loading && listToShow.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Öneri bulunamadı; tercihlerini profilden güncelleyebilirsin.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({required this.content});

  final ContentDto content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = content.locationName?.trim().isNotEmpty == true
        ? content.locationName!
        : (content.description ?? 'İçerik').split('\n').first;
    final thumb = ApiConfig.resolveFileUrl(content.fileUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: thumb.isNotEmpty
                ? Image.network(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: AppColors.surfaceVariant,
                          child: Icon(
                            Symbols.image,
                            color: AppColors.secondary,
                          ),
                        ),
                  )
                : const ColoredBox(
                    color: AppColors.surfaceVariant,
                    child: Icon(Symbols.explore, color: AppColors.secondary),
                  ),
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          content.user?.displayName.trim().isNotEmpty == true
              ? content.user!.displayName
              : '-',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.secondary,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ContentVerificationBadge(
              verificationStatus: content.verificationStatus,
              isVerified: content.isVerified,
              rejectionReason: content.rejectionReason,
              compact: true,
            ),
            const SizedBox(height: 4),
            const Icon(Symbols.chevron_right, color: AppColors.secondary),
          ],
        ),
        minVerticalPadding: 8,
        onTap: () {
          final id = content.id;
          if (id == null) return;
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => ContentDetailView(
                args: ContentDetailArgs(contentId: id, preview: content),
              ),
            ),
          );
        },
      ),
    );
  }
}
