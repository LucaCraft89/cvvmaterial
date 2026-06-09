import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../api/models.dart';

class SchoolbooksScreen extends ConsumerWidget {
  const SchoolbooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final booksAsync = ref.watch(schoolbooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Libri di testo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(schoolbooksProvider.notifier).refresh(),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text('Errore: $e',
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(schoolbooksProvider.notifier).refresh(),
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ),
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  Text('Nessun libro disponibile',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          // Group by subject
          final bySubject = <String, List<Schoolbook>>{};
          for (final b in books) {
            bySubject.putIfAbsent(b.subjectDesc, () => []).add(b);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bySubject.length,
            itemBuilder: (context, i) {
              final subject = bySubject.keys.elementAt(i);
              final subjectBooks = bySubject[subject]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                    child: Text(
                      subject.isNotEmpty ? subject : 'Generale',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...subjectBooks.map((b) => _BookCard(book: b)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Schoolbook book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      color: cs.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.bookTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.bookAuthor,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (book.publisherName.isNotEmpty)
                  _InfoChip(
                    label: book.publisherName,
                    icon: Icons.business_rounded,
                    cs: cs,
                  ),
                if (book.price != null)
                  _InfoChip(
                    label: '€${book.price!.toStringAsFixed(2)}',
                    icon: Icons.euro_rounded,
                    cs: cs,
                  ),
                if (book.isbnCode != null && book.isbnCode!.isNotEmpty)
                  _InfoChip(
                    label: 'ISBN: ${book.isbnCode}',
                    icon: Icons.barcode_reader,
                    cs: cs,
                  ),
                if (book.toBuy)
                  _StatusChip(
                    label: 'Da acquistare',
                    color: cs.tertiaryContainer,
                    onColor: cs.onTertiaryContainer,
                  ),
                if (book.toKeep)
                  _StatusChip(
                    label: 'Tenere dal passato',
                    color: cs.secondaryContainer,
                    onColor: cs.onSecondaryContainer,
                  ),
                if (book.isNew)
                  _StatusChip(
                    label: 'Nuovo',
                    color: cs.primaryContainer,
                    onColor: cs.onPrimaryContainer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;

  const _InfoChip({required this.label, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color onColor;

  const _StatusChip(
      {required this.label, required this.color, required this.onColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
            color: onColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}
