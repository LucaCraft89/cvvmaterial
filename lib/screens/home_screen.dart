import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../providers/theme_provider.dart';
import '../api/models.dart';
import '../theme/app_theme.dart';
import 'grades_screen.dart' show showGradeDetail;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final card = auth.card;
    final gradesAsync = ref.watch(gradesProvider);
    final absencesAsync = ref.watch(absencesProvider);
    final lessonsAsync = ref.watch(todayLessonsProvider);
    final agendaAsync = ref.watch(agendaProvider);
    final cardOrder = ref.watch(homeCardOrderProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(gradesProvider.notifier).refresh(),
            ref.read(absencesProvider.notifier).refresh(),
            ref.refresh(todayLessonsProvider.future),
            ref.read(agendaProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              expandedHeight: 180,
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Personalizza',
                  onPressed: () => _showCustomizeSheet(context),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  card != null ? 'Ciao, ${card.firstName}' : 'ClasseViva',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primaryContainer, cs.secondaryContainer],
                    ),
                  ),
                  child: card != null
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: cs.primary,
                                child: Text(
                                  '${card.firstName[0]}${card.lastName[0]}',
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card.fullName,
                                        style: TextStyle(
                                          color: cs.onPrimaryContainer,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        )),
                                    const SizedBox(height: 4),
                                    Text(card.schName.trim(),
                                        style: TextStyle(
                                          color: cs.onSecondaryContainer,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StatsRow(
                    gradesAsync: gradesAsync,
                    absencesAsync: absencesAsync,
                  ),
                  const SizedBox(height: 20),
                  ...cardOrder.expand((id) {
                    final meta = kHomeCardMeta[id]!;
                    final Widget cardWidget = switch (id) {
                      HomeCardId.recentGrades =>
                        _RecentGradesCard(gradesAsync: gradesAsync),
                      HomeCardId.todayLessons =>
                        _TodayLessonsCard(lessonsAsync: lessonsAsync),
                      HomeCardId.lateArrivals =>
                        _LateArrivalsCard(absencesAsync: absencesAsync),
                      HomeCardId.earlyExits =>
                        _EarlyExitsCard(absencesAsync: absencesAsync),
                      HomeCardId.upcomingEvents =>
                        _UpcomingEventsCard(agendaAsync: agendaAsync),
                    };
                    return [
                      _SectionHeader(title: meta.label, icon: meta.icon),
                      const SizedBox(height: 10),
                      cardWidget,
                      const SizedBox(height: 20),
                    ];
                  }),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CustomizeHomeSheet(),
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
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            )),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AsyncValue<List<Grade>> gradesAsync;
  final AsyncValue<List<AbsenceEvent>> absencesAsync;

  const _StatsRow({
    required this.gradesAsync,
    required this.absencesAsync,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradeCount = gradesAsync.value?.length ?? 0;
    final absenceCount = absencesAsync.value
            ?.where((e) => e.type == AbsenceType.absence)
            .length ??
        0;
    final lateCount = absencesAsync.value
            ?.where((e) => e.type == AbsenceType.lateArrival)
            .length ??
        0;

    return Row(
      children: [
        _StatCard(
          label: 'Voti',
          value: '$gradeCount',
          icon: Icons.grade_rounded,
          color: cs.primaryContainer,
          onColor: cs.onPrimaryContainer,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Assenze',
          value: '$absenceCount',
          icon: Icons.event_busy_rounded,
          color: cs.errorContainer,
          onColor: cs.onErrorContainer,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Ritardi',
          value: '$lateCount',
          icon: Icons.schedule_rounded,
          color: cs.secondaryContainer,
          onColor: cs.onSecondaryContainer,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color onColor;

  const _StatCard({
    required this.label,
    required this.value,
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: onColor, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: onColor,
                  )),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: onColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayLessonsCard extends StatelessWidget {
  final AsyncValue<List<Lesson>> lessonsAsync;

  const _TodayLessonsCard({required this.lessonsAsync});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerLow,
      child: lessonsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Errore nel caricamento',
              style: TextStyle(color: cs.error)),
        ),
        data: (lessons) => lessons.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: cs.primary, size: 20),
                    const SizedBox(width: 10),
                    Text('Nessuna lezione oggi',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : Column(
                children: lessons
                    .take(4)
                    .map((l) => ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text('${l.evtHPos}ª',
                                  style: TextStyle(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  )),
                            ),
                          ),
                          title: Text(l.subjectDesc,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: l.lessonArg.isNotEmpty
                              ? Text(l.lessonArg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                          dense: true,
                        ))
                    .toList(),
              ),
      ),
    );
  }
}

class _RecentGradesCard extends ConsumerWidget {
  final AsyncValue<List<Grade>> gradesAsync;

  const _RecentGradesCard({required this.gradesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerLow,
      child: gradesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Errore', style: TextStyle(color: cs.error)),
        ),
        data: (grades) {
          final recent = grades
              .where((g) => !g.canceled && g.decimalValue != null)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          if (recent.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Nessun voto disponibile',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            );
          }
          return Column(
            children: recent
                .take(4)
                .map((g) => ListTile(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showGradeDetail(context, g);
                      },
                      leading: _GradeChip(value: g.decimalValue!),
                      title: Text(g.subjectDesc,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${g.componentDesc} · ${DateFormat('d MMM', 'it').format(g.date)}',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                      trailing: g.notesForFamily?.isNotEmpty == true
                          ? Icon(Icons.notes_rounded,
                              size: 16, color: cs.onSurfaceVariant)
                          : null,
                      dense: true,
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _LateArrivalsCard extends ConsumerWidget {
  final AsyncValue<List<AbsenceEvent>> absencesAsync;

  const _LateArrivalsCard({required this.absencesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    const lateColor = Color(0xFFE65100);
    return Card(
      color: cs.surfaceContainerLow,
      child: absencesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Errore', style: TextStyle(color: cs.error)),
        ),
        data: (events) {
          final lates = events
              .where((e) => e.type == AbsenceType.lateArrival)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          if (lates.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: cs.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Nessun ritardo',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }
          return Column(
            children: lates.take(3).map((e) => ListTile(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(navTabProvider.notifier).setTab(2);
              },
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lateColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: lateColor, size: 18),
              ),
              title: Text(
                e.isJustified ? 'Giustificato' : 'Da giustificare',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: e.isJustified ? null : cs.error,
                ),
              ),
              subtitle: Text(
                DateFormat('d MMM yyyy', 'it').format(e.date),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              dense: true,
            )).toList(),
          );
        },
      ),
    );
  }
}

class _EarlyExitsCard extends ConsumerWidget {
  final AsyncValue<List<AbsenceEvent>> absencesAsync;

  const _EarlyExitsCard({required this.absencesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerLow,
      child: absencesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Errore', style: TextStyle(color: cs.error)),
        ),
        data: (events) {
          final exits = events
              .where((e) => e.type == AbsenceType.earlyExit)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          if (exits.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: cs.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Nessuna uscita anticipata',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }
          return Column(
            children: exits.take(3).map((e) => ListTile(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(navTabProvider.notifier).setTab(2);
              },
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.exit_to_app_rounded,
                    color: cs.tertiary, size: 18),
              ),
              title: Text(
                e.isJustified ? 'Giustificata' : 'Da giustificare',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: e.isJustified ? null : cs.error,
                ),
              ),
              subtitle: Text(
                DateFormat('d MMM yyyy', 'it').format(e.date),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              dense: true,
            )).toList(),
          );
        },
      ),
    );
  }
}

class _UpcomingEventsCard extends ConsumerWidget {
  final AsyncValue<AgendaState> agendaAsync;

  const _UpcomingEventsCard({required this.agendaAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerLow,
      child: agendaAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Errore', style: TextStyle(color: cs.error)),
        ),
        data: (state) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final upcoming = state.events
              .where((e) {
                final d = e.dateBegin;
                return !DateTime(d.year, d.month, d.day).isBefore(today);
              })
              .toList()
            ..sort((a, b) => a.dateBegin.compareTo(b.dateBegin));

          if (upcoming.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: cs.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Nessun evento imminente',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return Column(
            children: upcoming.take(3).map((e) {
              final (color, icon, label) = _eventStyle(e.type, cs);
              return ListTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(agendaTargetDayProvider.notifier).setDay(
                      DateTime(e.dateBegin.year, e.dateBegin.month, e.dateBegin.day));
                  ref.read(navTabProvider.notifier).setTab(4);
                },
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                title: Text(
                  e.subjectDesc.isNotEmpty ? e.subjectDesc : label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat('d MMM', 'it').format(e.dateBegin),
                  style:
                      TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                dense: true,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  (Color, IconData, String) _eventStyle(
      AgendaEventType type, ColorScheme cs) {
    return switch (type) {
      AgendaEventType.homework => (
          cs.primary,
          Icons.assignment_rounded,
          'Compiti',
        ),
      AgendaEventType.test => (cs.error, Icons.quiz_rounded, 'Verifica'),
      AgendaEventType.reminder => (
          cs.tertiary,
          Icons.notifications_rounded,
          'Promemoria',
        ),
      AgendaEventType.other => (cs.secondary, Icons.event_rounded, 'Evento'),
    };
  }
}

class _GradeChip extends StatelessWidget {
  final double value;
  const _GradeChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = gradeChipBg(value, cs);
    final fg = gradeChipFg(value, cs);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gradeBorderColor(value), width: 1.5),
      ),
      child: Center(
        child: Text(
          value == value.truncateToDouble()
              ? value.toInt().toString()
              : value.toStringAsFixed(1),
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}

class _CustomizeHomeSheet extends ConsumerWidget {
  const _CustomizeHomeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final cardOrder = ref.watch(homeCardOrderProvider);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Personalizza home',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  )),
              const SizedBox(height: 6),
              Text('Trascina per riordinare le sezioni',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 16),
              SizedBox(
                height: cardOrder.length * 60.0,
                child: ReorderableListView(
                  onReorderItem: (oldIndex, newIndex) {
                    ref
                        .read(homeCardOrderProvider.notifier)
                        .reorder(oldIndex, newIndex);
                  },
                  proxyDecorator: (child, index, animation) {
                    HapticFeedback.mediumImpact();
                    return Material(
                      elevation: 4,
                      shadowColor: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  children: cardOrder.map((id) {
                    final meta = kHomeCardMeta[id]!;
                    return ListTile(
                      key: ValueKey(id),
                      leading: Icon(meta.icon, color: cs.primary),
                      title: Text(meta.label,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Icon(Icons.drag_handle_rounded,
                          color: cs.onSurfaceVariant),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
