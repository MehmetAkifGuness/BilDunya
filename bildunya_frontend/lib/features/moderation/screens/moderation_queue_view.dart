import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/content_dto.dart';
import '../providers/moderation_provider.dart';

class ModerationQueueView extends StatefulWidget {
  const ModerationQueueView({super.key});

  @override
  State<ModerationQueueView> createState() => _ModerationQueueViewState();
}

class _ModerationQueueViewState extends State<ModerationQueueView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ModerationProvider>().loadQueue();
    });
  }

  Future<void> _approve(ContentDto content) async {
    final id = content.id;
    if (id == null) return;
    final err = await context.read<ModerationProvider>().approve(id);
    if (!mounted || err == null) return;
    showAppSnackBar(context, err, isError: true);
  }

  Future<void> _reject(ContentDto content) async {
    final id = content.id;
    if (id == null) return;
    final reason = await _askRejectReason();
    if (!mounted) return;
    if (reason == null) return;

    final err = await context.read<ModerationProvider>().reject(
      id,
      rejectionReason: reason.trim().isEmpty ? null : reason.trim(),
    );
    if (!mounted || err == null) return;
    showAppSnackBar(context, err, isError: true);
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
      return RefreshIndicator(
        onRefresh: () =>
            moderation.loadQueue(status: moderation.selectedStatus),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(child: Text('Bu filtrede içerik yok.')),
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
          final content = moderation.queue[index];
          final imageUrl = ApiConfig.resolveFileUrl(content.fileUrl);
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
                            content.description ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${content.locationName ?? 'Konum yok'} • ${content.contentType ?? '-'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.secondary),
                          ),
                          if (content.createdAt != null)
                            Text(
                              content.createdAt!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.secondary),
                            ),
                        ],
                      ),
                    ),
                    _StatusChip(status: content.verificationStatus),
                  ],
                ),
                if ((content.rejectionReason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Sebep: ${content.rejectionReason}',
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
                          onPressed: moderation.acting
                              ? null
                              : () => _reject(content),
                          icon: const Icon(Symbols.close, size: 18),
                          label: const Text('Reddet'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: moderation.acting
                              ? null
                              : () => _approve(content),
                          icon: const Icon(Symbols.check, size: 18),
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
    if (normalized == 'VERIFIED') {
      color = AppColors.primaryContainer;
      text = 'ONAY';
    } else if (normalized == 'REJECTED') {
      color = AppColors.error;
      text = 'RED';
    } else {
      color = AppColors.secondary;
      text = 'BEKLEME';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
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
