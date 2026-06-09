import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../api/models.dart';

class NoticeboardScreen extends ConsumerWidget {
  const NoticeboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final noticeAsync = ref.watch(noticeboardProvider);
    final hasUnread = noticeAsync.asData?.value.any((i) => !i.readStatus) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca'),
        actions: [
          if (hasUnread)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Segna tutte come lette',
              onPressed: () =>
                  ref.read(noticeboardProvider.notifier).markAllRead(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(noticeboardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: noticeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  const Text('Nessuna circolare'),
                ],
              ),
            );
          }

          final unread = items.where((i) => !i.readStatus).length;

          return Column(
            children: [
              if (unread > 0)
                Container(
                  width: double.infinity,
                  color: cs.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Text(
                    '$unread non lett${unread > 1 ? 'e' : 'a'}',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) =>
                      _NoticeCard(item: items[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoticeCard extends ConsumerWidget {
  final NoticeboardItem item;
  const _NoticeCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: item.readStatus
          ? cs.surfaceContainerLow
          : cs.primaryContainer.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NoticeDetailScreen(item: item),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!item.readStatus)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item.cntTitle,
                      style: TextStyle(
                        fontWeight: item.readStatus
                            ? FontWeight.w500
                            : FontWeight.w700,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(label: item.cntCategory, cs: cs),
                  const SizedBox(width: 8),
                  if (item.cntHasAttach)
                    _Chip(
                      label: '${item.attachments.length} allegat${item.attachments.length == 1 ? 'o' : 'i'}',
                      icon: Icons.attach_file_rounded,
                      cs: cs,
                    ),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM', 'it').format(item.date),
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
              if (item.needSign || item.needReply || item.needFile ||
                  item.needJoin) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    if (item.needSign)
                      _ActionChip(label: 'Firma', icon: Icons.draw_rounded),
                    if (item.needReply)
                      _ActionChip(
                          label: 'Risposta', icon: Icons.reply_rounded),
                    if (item.needFile)
                      _ActionChip(
                          label: 'File', icon: Icons.upload_file_rounded),
                    if (item.needJoin)
                      _ActionChip(
                          label: 'Adesione',
                          icon: Icons.how_to_vote_rounded),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ColorScheme cs;

  const _Chip({required this.label, this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: cs.onSecondaryContainer),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: cs.onSecondaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ActionChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: cs.onTertiaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail screen ─────────────────────────────────────────────────────────────

class NoticeDetailScreen extends ConsumerStatefulWidget {
  final NoticeboardItem item;
  const NoticeDetailScreen({super.key, required this.item});

  @override
  ConsumerState<NoticeDetailScreen> createState() =>
      _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends ConsumerState<NoticeDetailScreen> {
  NoticeDetail? _detail;
  bool _loading = true;
  String? _error;
  String? _downloadingFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await ref
          .read(noticeboardProvider.notifier)
          .readItem(widget.item);
      if (mounted) {
        setState(() {
          _detail = detail;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _download(NoticeAttachment att) async {
    setState(() => _downloadingFile = att.fileName);
    try {
      await ref
          .read(noticeboardProvider.notifier)
          .downloadAttachment(widget.item.evtCode, widget.item.pubId, att.attachNum, att.fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore download: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circolare'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text('Errore: $_error',
                      style: TextStyle(color: cs.error)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Title
                    Text(
                      _detail?.title ?? widget.item.cntTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Metadata
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          label: widget.item.cntCategory,
                          icon: Icons.label_outline_rounded,
                          cs: cs,
                        ),
                        _InfoChip(
                          label: DateFormat('d MMMM yyyy', 'it')
                              .format(widget.item.date),
                          icon: Icons.calendar_today_rounded,
                          cs: cs,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Body text
                    if (_detail?.text.isNotEmpty == true) ...[
                      Card(
                        color: cs.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _detail!.text,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Attachments
                    if (widget.item.attachments.isNotEmpty) ...[
                      Text('Allegati',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: cs.onSurface,
                          )),
                      const SizedBox(height: 10),
                      ...widget.item.attachments.map(
                        (att) => Card(
                          color: cs.surfaceContainerLow,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _fileIcon(att.fileName),
                              color: cs.primary,
                            ),
                            title: Text(att.fileName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            trailing: _downloadingFile == att.fileName
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                        Icons.download_rounded),
                                    onPressed: () => _download(att),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'xls' || 'xlsx' => Icons.table_chart_rounded,
      'jpg' || 'jpeg' || 'png' => Icons.image_rounded,
      _ => Icons.attach_file_rounded,
    };
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(message, style: TextStyle(color: cs.error)),
    );
  }
}
