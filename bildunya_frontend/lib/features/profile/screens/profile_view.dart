import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/content_dto.dart';
import '../../../data/models/user_dto.dart';
import '../../../data/models/user_gamification_dto.dart';
import '../../../data/repositories/content_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../content/screens/content_detail_view.dart';
import '../../moderation/providers/moderation_provider.dart';
import '../../moderation/screens/moderation_queue_view.dart';
import '../providers/profile_provider.dart';
import 'achievements_view.dart';
import 'profile_edit_view.dart';

/// Varsayılan unvan (code.html — bio boşken).
const String kDefaultProfileTagline = 'Kaşif & Tarih Meraklısı';

/// Profil: kapak, bilgi, istatistikler, Paylaşımlar / Beğeniler (code.html Screen 1).
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _auth = context.read<AuthProvider>();
    _auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_auth.isAuthenticated) {
        context.read<ProfileProvider>().load();
      }
    });
  }

  void _onAuthChanged() {
    if (!mounted || !_auth.isAuthenticated) return;
    context.read<ProfileProvider>().load();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surfaceContainerLowest,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profilini görmek için giriş yap.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryContainer],
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(LoginScreen.routeName),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        child: Text(
                          'Giriş yap',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w800,
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
      );
    }

    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        if (profile.loading && profile.user == null) {
          return const Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profile.error != null && profile.user == null) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            appBar: AppBar(title: const Text('Profil')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: profile.load,
                      child: const Text('Yeniden dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final user = profile.user;
        if (user == null) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            appBar: AppBar(title: const Text('Profil')),
            body: const Center(child: Text('Profil yüklenemedi.')),
          );
        }
        final role = (user.role ?? '').trim().toUpperCase();
        final isModerator = role == 'ADMIN' || role == 'MODERATOR';

        return Scaffold(
          backgroundColor: AppColors.surfaceContainerLowest,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(
                user: user,
                gamification: profile.gamification,
                fallbackPostCount: profile.myContents.length,
                isAnonymous: user.isAnonymous == true,
                updatingAnonymous: profile.updatingAnonymous,
                onAnonymousChanged: (value) async {
                  final err = await context
                      .read<ProfileProvider>()
                      .setAnonymous(value);
                  if (!context.mounted || err == null) return;
                  showAppSnackBar(context, err, isError: true);
                },
                onEditProfile: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileEditView(),
                    ),
                  );
                },
                onModerationQueue: isModerator
                    ? () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (ctx) => ChangeNotifierProvider(
                              create: (_) => ModerationProvider(
                                ctx.read<ContentRepository>(),
                              ),
                              child: const ModerationQueueView(),
                            ),
                          ),
                        );
                      }
                    : null,
                onAchievements: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const AchievementsView(),
                    ),
                  );
                },
              ),
              Material(
                color: AppColors.surfaceContainerLowest,
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.secondary.withValues(
                    alpha: 0.45,
                  ),
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  labelStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                  tabs: const [
                    Tab(text: 'Paylaşımlar'),
                    Tab(text: 'Beğeniler'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    RefreshIndicator(
                      color: AppColors.primaryContainer,
                      onRefresh: profile.load,
                      child: _PostsGrid(contents: profile.myContents),
                    ),
                    RefreshIndicator(
                      color: AppColors.primaryContainer,
                      onRefresh: profile.load,
                      child: _LikesPlaceholder(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.gamification,
    required this.fallbackPostCount,
    required this.isAnonymous,
    required this.updatingAnonymous,
    required this.onAnonymousChanged,
    required this.onEditProfile,
    required this.onModerationQueue,
    required this.onAchievements,
  });

  final UserDto user;
  final UserGamificationDto? gamification;
  final int fallbackPostCount;
  final bool isAnonymous;
  final bool updatingAnonymous;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onEditProfile;
  final VoidCallback? onModerationQueue;
  final VoidCallback onAchievements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posts = gamification?.totalPosts ?? fallbackPostCount;
    final verified = gamification?.verifiedContentCount ?? 0;
    final locs = gamification?.distinctLocationCount ?? 0;
    final coverUrl = ApiConfig.resolveFileUrl(user.profilePhotoUrl);
    final name = user.displayName;
    final bioRaw = user.bio;
    final tagline = (bioRaw != null && bioRaw.trim().isNotEmpty)
        ? bioRaw.trim()
        : kDefaultProfileTagline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceContainer,
                    backgroundImage: coverUrl.isNotEmpty
                        ? CachedNetworkImageProvider(coverUrl)
                        : null,
                    child: coverUrl.isEmpty
                        ? const Icon(
                            Symbols.person,
                            size: 20,
                            color: AppColors.secondary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'BilDünya',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onEditProfile,
                icon: const Icon(Symbols.edit),
                color: AppColors.primaryContainer,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const ColoredBox(color: AppColors.surfaceContainer),
                  errorWidget: (context, url, error) =>
                      const ColoredBox(color: AppColors.surfaceContainer),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.surfaceContainerHigh,
                        AppColors.surfaceContainerLow,
                      ],
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.surfaceContainerLowest,
                    ],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tagline.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatBlock(value: '$posts', label: 'Paylaşım'),
                        const SizedBox(width: 28),
                        _StatBlock(value: '$verified', label: 'Onaylı'),
                        const SizedBox(width: 28),
                        _StatBlock(value: '$locs', label: 'Konum'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                color: AppColors.surfaceContainer.withValues(alpha: 0.82),
                child: InkWell(
                  onTap: onAchievements,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.workspace_premium,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Başarılar ve Rozetler',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const Icon(
                          Symbols.chevron_right,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onModerationQueue != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Material(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: InkWell(
                onTap: onModerationQueue,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.admin_panel_settings,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Moderasyon Kuyruğu',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const Icon(
                        Symbols.chevron_right,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Material(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: SwitchListTile.adaptive(
              value: isAnonymous,
              onChanged: updatingAnonymous ? null : onAnonymousChanged,
              title: Text(
                'Anonim profil modu',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                'Açıkken adın ve profilin içeriklerde gizlenir.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              activeThumbColor: AppColors.primaryContainer,
              activeTrackColor: AppColors.primaryContainer.withValues(
                alpha: 0.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.secondary.withValues(alpha: 0.55),
            fontSize: 8,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _PostsGrid extends StatelessWidget {
  const _PostsGrid({required this.contents});

  final List<ContentDto> contents;

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
          Center(
            child: Text(
              'Henüz paylaşım yok.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: contents.length,
      itemBuilder: (context, i) {
        final c = contents[i];
        final id = c.id;
        final url = ApiConfig.resolveFileUrl(c.fileUrl);
        return Material(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: id == null
                ? null
                : () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ContentDetailView(
                          args: ContentDetailArgs(contentId: id, preview: c),
                        ),
                      ),
                    );
                  },
            child: url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ColoredBox(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Symbols.broken_image,
                      color: AppColors.secondary,
                    ),
                  )
                : const Icon(Symbols.image, color: AppColors.secondary),
          ),
        );
      },
    );
  }
}

class _LikesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Center(
          child: Text(
            'Beğeniler yakında.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}
