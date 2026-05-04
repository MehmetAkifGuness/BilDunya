import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/moderation_item_dto.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/moderation_provider.dart';

class ModerationQueueView extends StatefulWidget {
  const ModerationQueueView({super.key});

  static const String routeName = '/moderation';

  @override
  State<ModerationQueueView> createState() => _ModerationQueueViewState();
}

class _ModerationQueueViewState extends State<ModerationQueueView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<AuthProvider>().isAdmin) return;
      context.read<ModerationProvider>().loadQueue();
    });
  }

  Future<void> _approve(ModerationItemDto item) async {
    final err = await context.read<ModerationProvider>().approve(item);
    if (!mounted) return;
    if (err != null) {
      showAppSnackBar(context, err, isError: true);
      return;
    }
    showAppSnackBar(context, 'Paylaşım onaylandı.');
  }

  Future<void> _reject(ModerationItemDto item) async {
    final reason = await _askRejectReason();
    if (!mounted) return;
    if (reason == null) return;

    final err = await context.read<ModerationProvider>().reject(
      item,
      rejectionReason: reason.trim().isEmpty ? null : reason.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      showAppSnackBar(context, err, isError: true);
      return;
    }
    showAppSnackBar(context, 'Paylaşım reddedildi.');
  }

  Future<String?> _askRejectReason() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reddetme sebebi'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Sebep yaz (opsiyonel)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Reddet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moderasyon')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bu alana erişim yetkin yok.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Symbols.arrow_back),
                  label: const Text('Geri dön'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<ModerationProvider>(
      builder: (context, moderation, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Moderasyon Kuyruğu'),
            actions: [
              IconButton(
                onPressed: moderation.loading
                    ? null
                    : () => moderation.loadQueue(
                        status: moderation.selectedStatus,
                      ),
                icon: const Icon(Symbols.refresh),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: DropdownButtonFormField<String>(
                  initialValue: moderation.selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Durum filtresi',
                    filled: true,
                    fillColor: AppColors.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  items: ModerationProvider.supportedStatuses
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    moderation.loadQueue(status: value);
                  },
                ),
              ),
              Expanded(child: _buildBody(context, moderation)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ModerationProvider moderation) {
    if (moderation.loading && moderation.queue.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (moderation.error != null && moderation.queue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                moderation.error!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    moderation.loadQueue(status: moderation.selectedStatus),
                child: const Text('Yeniden dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (moderation.queue.isEmpty) {
      final emptyText = moderation.selectedStatus == 'PENDING'
          ? 'Bekleyen paylaşım yok.'
          : 'Bu filtrede paylaşım yok.';
      return RefreshIndicator(
        onRefresh: () =>
            moderation.loadQueue(status: moderation.selectedStatus),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 200),
            Center(child: Text(emptyText)),
          ],
        ),
      );
    }

    final pendingView = moderation.selectedStatus == 'PENDING';
    return RefreshIndicator(
      onRefresh: () => moderation.loadQueue(status: moderation.selectedStatus),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: moderation.queue.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = moderation.queue[index];
          final imageUrl = ApiConfig.resolveFileUrl(item.fileUrl);
          final isBusy = moderation.isActingOn(item);
          final typeLabel = item.normalizedType == 'CUSTOM_LOCATION'
              ? 'Pin'
              : (item.contentType ?? 'Paylaşım');
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const ColoredBox(
                                  color: AppColors.surfaceContainer,
                                  child: Icon(Symbols.broken_image),
                                ),
                              )
                            : const ColoredBox(
                                color: AppColors.surfaceContainer,
                                child: Icon(Symbols.image),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.locationName ?? 'Konum yok'} • $typeLabel',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.secondary),
                          ),
                          if ((item.description ?? '').trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.secondary),
                              ),
                            ),
                          if ((item.username ?? '').trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '@${item.username}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.secondary),
                              ),
                            ),
                          if (item.createdAt != null)
                            Text(
                              item.createdAt!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.secondary),
                            ),
                        ],
                      ),
                    ),
                    _StatusChip(status: item.verificationStatus),
                  ],
                ),
                if ((item.rejectionReason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Sebep: ${item.rejectionReason}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ],
                if (pendingView) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isBusy ? null : () => _reject(item),
                          icon: isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Symbols.close, size: 18),
                          label: const Text('Reddet'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isBusy ? null : () => _approve(item),
                          icon: isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Symbols.check, size: 18),
                          label: const Text('Onayla'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = (status ?? '').trim().toUpperCase();
    Color color;
    String text;
    if (normalized == 'APPROVED' || normalized == 'VERIFIED') {
      color = AppColors.primaryContainer;
      text = 'Onaylı';
    } else if (normalized == 'REJECTED') {
      color = AppColors.error;
      text = 'Reddedildi';
    } else {
      color = AppColors.secondary;
      text = 'Beklemede';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
