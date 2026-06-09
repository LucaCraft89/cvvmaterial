import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../api/models.dart';
import 'web_view_screen.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final docsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documenti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(documentsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Errore: $e', style: TextStyle(color: cs.error)),
        ),
        data: (data) {
          final hasContent = data.documents.isNotEmpty ||
              data.schoolReports.isNotEmpty;

          if (!hasContent) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_off_outlined,
                      size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  const Text('Nessun documento disponibile'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // School reports section
              if (data.schoolReports.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Pagelle e valutazioni',
                  icon: Icons.school_rounded,
                ),
                const SizedBox(height: 10),
                ...data.schoolReports.map((r) => _SchoolReportCard(report: r)),
                const SizedBox(height: 20),
              ],

              // Documents section
              if (data.documents.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Documenti',
                  icon: Icons.description_rounded,
                ),
                const SizedBox(height: 10),
                ...data.documents.map((d) => _DocumentCard(doc: d)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: cs.onSurface,
            )),
      ],
    );
  }
}

class _SchoolReportCard extends StatelessWidget {
  final SchoolReport report;
  const _SchoolReportCard({required this.report});

  void _open(BuildContext context) {
    if (report.viewLink.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          url: report.viewLink,
          title: report.desc,
          useWebAuth: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerLow,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.assessment_rounded,
              color: cs.onPrimaryContainer, size: 22),
        ),
        title: Text(report.desc,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Apri nel browser integrato'),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
        onTap: () => _open(context),
      ),
    );
  }
}

class _DocumentCard extends ConsumerStatefulWidget {
  final StudentDocument doc;
  const _DocumentCard({required this.doc});

  @override
  ConsumerState<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends ConsumerState<_DocumentCard> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(documentsProvider.notifier)
          .downloadDocument(widget.doc);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerLow,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.picture_as_pdf_rounded,
              color: cs.onSecondaryContainer, size: 22),
        ),
        title: Text(widget.doc.desc,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Hash: ${widget.doc.hash.substring(0, 8)}...',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        trailing: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: _download,
              ),
      ),
    );
  }
}
