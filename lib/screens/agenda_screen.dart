import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../api/models.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  PageController? _pageCtrl;
  List<DateTime> _days = [];
  int _pageIndex = 0;
  DateTime? _initRangeStart;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pageCtrl?.dispose();
    super.dispose();
  }

  void _ensureDays(AgendaState state) {
    if (_initRangeStart == state.rangeStart && _days.isNotEmpty) return;

    final days = <DateTime>[];
    var d = DateTime(
        state.rangeStart.year, state.rangeStart.month, state.rangeStart.day);
    final end = DateTime(
        state.rangeEnd.year, state.rangeEnd.month, state.rangeEnd.day);
    while (!d.isAfter(end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    int startIndex = 0;
    for (int i = 0; i < days.length; i++) {
      if (!days[i].isBefore(todayDate)) {
        startIndex = i;
        break;
      }
    }

    final oldCtrl = _pageCtrl;
    _days = days;
    _pageCtrl = PageController(initialPage: startIndex);
    _pageIndex = startIndex;
    _initRangeStart = state.rangeStart;
    WidgetsBinding.instance.addPostFrameCallback((_) => oldCtrl?.dispose());
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  void _goToToday() {
    _tabs.animateTo(0);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final idx = _days.indexWhere((d) => d == todayDate);
    if (idx >= 0) {
      _pageCtrl?.animateToPage(idx,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final agendaAsync = ref.watch(agendaProvider);

    ref.listen<DateTime?>(agendaTargetDayProvider, (prev, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(agendaTargetDayProvider.notifier).setDay(null);
      });
      _tabs.animateTo(0);
      if (_days.isEmpty) return;
      final target = DateTime(next.year, next.month, next.day);
      final idx = _days.indexWhere((d) => d == target);
      if (idx >= 0) {
        _pageCtrl?.animateToPage(idx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Giorno'), Tab(text: 'Calendario')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Vai ad oggi',
            onPressed: _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(agendaProvider.notifier).refresh(),
          ),
        ],
      ),
      body: agendaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Errore: $e', style: TextStyle(color: cs.error)),
        ),
        data: (state) {
          _ensureDays(state);

          final eventsByDay = <String, List<AgendaEvent>>{};
          for (final ev in state.events) {
            eventsByDay
                .putIfAbsent(_dayKey(ev.dateBegin), () => [])
                .add(ev);
          }

          return TabBarView(
            controller: _tabs,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDayTab(cs, eventsByDay),
              _CalendarView(
                eventsByDay: eventsByDay,
                rangeStart: state.rangeStart,
                rangeEnd: state.rangeEnd,
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Day tab ──────────────────────────────────────────────────────────────────

  Widget _buildDayTab(
      ColorScheme cs, Map<String, List<AgendaEvent>> eventsByDay) {
    if (_pageCtrl == null || _days.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final day = _days[_pageIndex.clamp(0, _days.length - 1)];
    final today = _isToday(day);
    final fmt = DateFormat('EEEE d MMMM', 'it');

    return Column(
      children: [
        Container(
          color: today ? cs.primaryContainer : cs.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: today ? cs.onPrimaryContainer : cs.onSurface,
                onPressed: _pageIndex > 0
                    ? () => _pageCtrl!.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut)
                    : null,
              ),
              Expanded(
                child: Text(
                  today
                      ? 'Oggi · ${fmt.format(day)}'
                      : fmt.format(day),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: today ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: today ? cs.onPrimaryContainer : cs.onSurface,
                onPressed: _pageIndex < _days.length - 1
                    ? () => _pageCtrl!.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemCount: _days.length,
            itemBuilder: (context, i) {
              final events = eventsByDay[_dayKey(_days[i])] ?? [];
              return _DayEventsPage(events: events);
            },
          ),
        ),
      ],
    );
  }
}

// ── Calendar view ("Calendario" tab) ─────────────────────────────────────────

class _CalendarView extends StatefulWidget {
  final Map<String, List<AgendaEvent>> eventsByDay;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const _CalendarView({
    required this.eventsByDay,
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late DateTime _month;
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    // Pre-select today if it has events
    final todayKey = _dayKey(now);
    if (widget.eventsByDay.containsKey(todayKey)) {
      _selectedKey = todayKey;
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _canGoPrev =>
      _month.year > widget.rangeStart.year ||
      (_month.year == widget.rangeStart.year &&
          _month.month > widget.rangeStart.month);

  bool get _canGoNext =>
      _month.year < widget.rangeEnd.year ||
      (_month.year == widget.rangeEnd.year &&
          _month.month < widget.rangeEnd.month);

  void _prevMonth() => setState(() {
        _month = DateTime(_month.year, _month.month - 1);
        _selectedKey = null;
      });

  void _nextMonth() => setState(() {
        _month = DateTime(_month.year, _month.month + 1);
        _selectedKey = null;
      });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    // ISO weekday: Mon=1..Sun=7, offset for Mon-first grid
    final offset = (DateTime(_month.year, _month.month, 1).weekday - 1) % 7;

    final selectedEvents =
        _selectedKey != null ? (widget.eventsByDay[_selectedKey] ?? []) : [];

    // Build day cells
    final cells = <Widget>[
      // Blank cells before month start
      for (int i = 0; i < offset; i++) const SizedBox.shrink(),
      // Day cells
      for (int d = 1; d <= daysInMonth; d++)
        () {
          final day = DateTime(_month.year, _month.month, d);
          final key = _dayKey(day);
          final events = widget.eventsByDay[key] ?? [];
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          return _DayCell(
            day: d,
            events: events,
            isToday: isToday,
            isSelected: _selectedKey == key,
            cs: cs,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedKey = _selectedKey == key ? null : key;
              });
            },
          );
        }(),
    ];

    // Chunk cells into rows of 7
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final chunk = cells.sublist(i, (i + 7).clamp(0, cells.length));
      while (chunk.length < 7) {
        chunk.add(const SizedBox.shrink());
      }
      rows.add(Row(
        children: chunk.map((c) => Expanded(child: c)).toList(),
      ));
    }

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _canGoPrev ? _prevMonth : null,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'it').format(_month),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _canGoNext ? _nextMonth : null,
              ),
            ],
          ),
        ),

        // Week day headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['L', 'M', 'M', 'G', 'V', 'S', 'D']
                .map((h) => Expanded(
                      child: Center(
                        child: Text(
                          h,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1) const SizedBox(height: 2),
              ],
            ],
          ),
        ),

        const Divider(height: 20),

        // Events for selected day
        Expanded(
          child: _selectedKey == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 40,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text('Seleziona un giorno',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : selectedEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded,
                              size: 40,
                              color: cs.primary.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Text('Nessun evento',
                              style:
                                  TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: selectedEvents.length,
                      itemBuilder: (context, i) =>
                          _AgendaCard(event: selectedEvents[i]),
                    ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<AgendaEvent> events;
  final bool isToday;
  final bool isSelected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : isToday
                        ? cs.primaryContainer
                        : null,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: (isToday || isSelected)
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected
                        ? cs.onPrimary
                        : isToday
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: events.isNotEmpty ? _buildDots() : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    final types = events.map((e) => e.type).toSet().take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: types
          .map((t) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _dotColor(t),
                    shape: BoxShape.circle,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Color _dotColor(AgendaEventType type) => switch (type) {
        AgendaEventType.test => const Color(0xFFC62828),
        AgendaEventType.homework => cs.primary,
        AgendaEventType.reminder => cs.tertiary,
        AgendaEventType.other => cs.secondary,
      };
}

// ── Day events page ───────────────────────────────────────────────────────────

class _DayEventsPage extends StatelessWidget {
  final List<AgendaEvent> events;

  const _DayEventsPage({required this.events});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded,
                size: 56, color: cs.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Nessun evento',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: events.length,
      itemBuilder: (context, i) => _AgendaCard(event: events[i]),
    );
  }
}

// ── Agenda card ───────────────────────────────────────────────────────────────

class _AgendaCard extends StatelessWidget {
  final AgendaEvent event;

  const _AgendaCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, icon, label) = _eventStyle(event.type, cs);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
                      const Spacer(),
                      if (!event.isFullDay)
                        Text(
                          '${_fmtTime(event.evtDatetimeBegin)}–${_fmtTime(event.evtDatetimeEnd)}',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.subjectDesc.isNotEmpty
                        ? event.subjectDesc
                        : event.authorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (event.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(event.notes!,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text(event.authorName,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String dt) {
    final d = DateTime.tryParse(dt);
    if (d == null) return '';
    return DateFormat('HH:mm').format(d);
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
