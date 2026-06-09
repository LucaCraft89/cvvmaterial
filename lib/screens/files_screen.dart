import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../api/models.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final didacticsAsync = ref.watch(didacticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materiale didattico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(didacticsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: didacticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (teachers) {
          if (teachers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_off_outlined, size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  const Text('Nessun materiale disponibile'),
                ],
              ),
            );
          }

          // Count total files
          final totalFiles = teachers
              .expand((t) => t.folders)
              .expand((f) => f.contents)
              .length;

          return Column(
            children: [
              Container(
                color: cs.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.folder_rounded,
                        color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '$totalFiles file da ${teachers.length} docent${teachers.length > 1 ? 'i' : 'e'}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: teachers
                      .map((t) => _TeacherExpansion(teacher: t))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherExpansion extends StatelessWidget {
  final TeacherDidactics teacher;

  const _TeacherExpansion({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fileCount = teacher.folders
        .expand((f) => f.contents)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerLow,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            teacher.teacherName.isNotEmpty
                ? teacher.teacherName[0]
                : '?',
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          teacher.teacherName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${teacher.folders.length} cartel${teacher.folders.length == 1 ? 'la' : 'le'} · $fileCount file',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        children: teacher.folders
            .map((f) => _FolderExpansion(folder: f))
            .toList(),
      ),
    );
  }
}

class _FolderExpansion extends StatelessWidget {
  final TeacherFolder folder;

  const _FolderExpansion({required this.folder});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lastShare = DateTime.tryParse(folder.lastShareDT);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        color: cs.surfaceContainerLowest,
        child: ExpansionTile(
          leading: Icon(Icons.folder_outlined, color: cs.secondary),
          title: Text(
            folder.folderName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: lastShare != null
              ? Text(
                  'Aggiornato ${DateFormat('d MMM yyyy', 'it').format(lastShare)}',
                  style:
                      TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                )
              : null,
          children: folder.contents.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Cartella vuota',
                        style:
                            TextStyle(color: cs.onSurfaceVariant)),
                  )
                ]
              : folder.contents
                  .map((c) => _ContentTile(content: c))
                  .toList(),
        ),
      ),
    );
  }
}

class _ContentTile extends ConsumerStatefulWidget {
  final FolderContent content;
  const _ContentTile({required this.content});

  @override
  ConsumerState<_ContentTile> createState() => _ContentTileState();
}

class _ContentTileState extends ConsumerState<_ContentTile> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      await ref
          .read(didacticsProvider.notifier)
          .downloadContent(widget.content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shareDate = DateTime.tryParse(widget.content.shareDT);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          _fileIcon(widget.content.contentName, widget.content.objectType),
          color: cs.primary,
          size: 22,
        ),
        title: Text(
          widget.content.contentName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        subtitle: shareDate != null
            ? Text(
                DateFormat('d MMM yyyy', 'it').format(shareDate),
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 11),
              )
            : null,
        trailing: _downloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: _download,
                tooltip: 'Scarica',
              ),
        dense: true,
      ),
    );
  }

  IconData _fileIcon(String name, String type) {
    if (type == 'link') return Icons.link_rounded;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'xls' || 'xlsx' => Icons.table_chart_rounded,
      'ppt' || 'pptx' => Icons.slideshow_rounded,
      'jpg' || 'jpeg' || 'png' || 'gif' => Icons.image_rounded,
      'mp4' || 'mov' || 'avi' => Icons.video_file_rounded,
      'mp3' || 'wav' => Icons.audio_file_rounded,
      'zip' || 'rar' || '7z' => Icons.folder_zip_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
