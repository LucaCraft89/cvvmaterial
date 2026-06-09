import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../api/models.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note e annotazioni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(notesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Errore: $e', style: TextStyle(color: cs.error)),
        ),
        data: (notes) => DefaultTabController(
          length: 4,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  _Tab(
                      label: 'Docenti',
                      count: notes.teacherNotes.length,
                      cs: cs),
                  _Tab(
                      label: 'Avvisi',
                      count: notes.warnings.length,
                      cs: cs,
                      alert: notes.warnings.isNotEmpty),
                  _Tab(
                      label: 'Classe',
                      count: notes.classNotes.length,
                      cs: cs),
                  _Tab(
                      label: 'Sospensioni',
                      count: notes.suspensions.length,
                      cs: cs,
                      alert: notes.suspensions.isNotEmpty),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _NotesList(
                        notes: notes.teacherNotes,
                        type: NoteType.teacherNote),
                    _NotesList(
                        notes: notes.warnings,
                        type: NoteType.warning),
                    _NotesList(
                        notes: notes.classNotes,
                        type: NoteType.classNote),
                    _NotesList(
                        notes: notes.suspensions,
                        type: NoteType.suspension),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final ColorScheme cs;
  final bool alert;

  const _Tab({
    required this.label,
    required this.count,
    required this.cs,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: alert ? cs.error : cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: alert ? cs.onError : cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  final List<Note> notes;
  final NoteType type;

  const _NotesList({required this.notes, required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 56, color: cs.primary),
            const SizedBox(height: 16),
            Text('Nessuna annotazione',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) =>
          _NoteCard(note: notes[i], type: type),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;
  final NoteType type;

  const _NoteCard({required this.note, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final (color, onColor, icon) = _typeStyle(type, cs);

    return Card(
      color: cs.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: note.readStatus
            ? null
            : () => ref.read(notesProvider.notifier).markRead(type, note.evtId),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          )),
                      Text(
                        DateFormat('d MMMM yyyy', 'it').format(note.date),
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!note.readStatus)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (note.warningType != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.warningType!,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              note.evtText,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  (Color, Color, IconData) _typeStyle(NoteType type, ColorScheme cs) {
    return switch (type) {
      NoteType.teacherNote => (cs.primary, cs.onPrimary, Icons.edit_note_rounded),
      NoteType.warning => (cs.error, cs.onError, Icons.warning_amber_rounded),
      NoteType.classNote => (cs.secondary, cs.onSecondary, Icons.group_rounded),
      NoteType.suspension => (
          cs.error,
          cs.onError,
          Icons.gavel_rounded
        ),
    };
  }
}
