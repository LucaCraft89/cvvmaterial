import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../api/models.dart';

class AbsencesScreen extends ConsumerWidget {
  const AbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final absencesAsync = ref.watch(absencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assenze'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(absencesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: absencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  Text('Nessuna assenza',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          final absences = events
              .where((e) => e.type == AbsenceType.absence)
              .length;
          final lates = events
              .where((e) => e.type == AbsenceType.lateArrival)
              .length;
          final exits = events
              .where((e) => e.type == AbsenceType.earlyExit)
              .length;
          final unjustified = events.where((e) => !e.isJustified).length;

          // Group by month, sorted newest-first
          final sortedEvents = [...events]..sort((a, b) => b.date.compareTo(a.date));
          final grouped = <String, List<AbsenceEvent>>{};
          for (final e in sortedEvents) {
            final key = DateFormat('yyyy-MM').format(e.date);
            grouped.putIfAbsent(key, () => []).add(e);
          }
          final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              Row(
                children: [
                  _SummaryChip(
                    label: 'Assenze',
                    count: absences,
                    icon: Icons.event_busy_rounded,
                    color: cs.errorContainer,
                    onColor: cs.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Ritardi',
                    count: lates,
                    icon: Icons.schedule_rounded,
                    color: cs.secondaryContainer,
                    onColor: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Uscite ant.',
                    count: exits,
                    icon: Icons.exit_to_app_rounded,
                    color: cs.tertiaryContainer,
                    onColor: cs.onTertiaryContainer,
                  ),
                ],
              ),
              if (unjustified > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: cs.onErrorContainer, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$unjustified event${unjustified > 1 ? 'i' : 'o'} non giustificat${unjustified > 1 ? 'i' : 'o'}',
                        style: TextStyle(
                          color: cs.onErrorContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ...sortedKeys.map((key) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          DateFormat('MMMM yyyy', 'it').format(DateFormat('yyyy-MM').parse(key)),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...grouped[key]!.map((e) => _AbsenceCard(event: e)),
                      const SizedBox(height: 12),
                    ],
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color onColor;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: onColor, size: 20),
              const SizedBox(height: 4),
              Text('$count',
                  style: TextStyle(
                    color: onColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  )),
              Text(label,
                  style: TextStyle(
                    color: onColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbsenceCard extends StatelessWidget {
  final AbsenceEvent event;
  const _AbsenceCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, label, typeColor) = _typeInfo(event.type, cs);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: event.isJustified
          ? cs.surfaceContainerLow
          : cs.errorContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: typeColor.withOpacity(0.4)),
              ),
              child: Icon(icon, color: typeColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(
                        DateFormat('d MMM yyyy', 'it').format(event.date),
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (event.isJustified)
                        _badge(
                          context,
                          icon: Icons.check_circle_outline_rounded,
                          text: event.justifReasonDesc ?? 'Giustificato',
                          color: const Color(0xFF2E7D32),
                        )
                      else
                        _badge(
                          context,
                          icon: Icons.pending_rounded,
                          text: 'Da giustificare',
                          color: cs.error,
                        ),
                      if (event.evtHPos != null) ...[
                        const SizedBox(width: 8),
                        _badge(context,
                            icon: Icons.access_time_rounded,
                            text: 'Ora ${event.evtHPos}',
                            color: cs.onSurfaceVariant),
                      ],
                    ],
                  ),
                  if (event.hoursAbsence.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.hoursAbsence
                          .map((h) => h.subject)
                          .join(', '),
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  (IconData, String, Color) _typeInfo(AbsenceType type, ColorScheme cs) {
    return switch (type) {
      AbsenceType.absence => (
          Icons.event_busy_rounded,
          'Assenza',
          cs.error,
        ),
      AbsenceType.lateArrival => (
          Icons.schedule_rounded,
          'Ritardo',
          const Color(0xFFE65100),
        ),
      AbsenceType.earlyExit => (
          Icons.exit_to_app_rounded,
          'Uscita ant.',
          cs.tertiary,
        ),
      AbsenceType.unknown => (
          Icons.help_outline_rounded,
          'Evento',
          cs.onSurfaceVariant,
        ),
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
