import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../api/models.dart';
import '../theme/app_theme.dart';

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  int? _selectedPeriod;
  bool _periodInitialized = false;

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradesProvider);
    final subjectList = ref.watch(subjectGradesProvider);

    // Auto-select current period once, using periods date ranges
    if (!_periodInitialized) {
      ref.watch(periodsProvider).maybeWhen(
        data: (periods) {
          if (periods.isNotEmpty) {
            _periodInitialized = true;
            final now = DateTime.now();
            Period? current;
            for (final p in periods) {
              final s = DateTime.tryParse(p.dateStart);
              final e = DateTime.tryParse(p.dateEnd);
              if (s != null &&
                  e != null &&
                  !now.isBefore(s) &&
                  !now.isAfter(e)) {
                current = p;
                break;
              }
            }
            final found = current ??
                periods.reduce(
                    (a, b) => a.periodPos > b.periodPos ? a : b);
            final target = found.periodPos;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedPeriod = target);
            });
          }
        },
        orElse: () {},
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(gradesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: gradesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (_) {
          // Build period list from data
          final periods = <int, String>{};
          for (final sg in subjectList) {
            for (final g in sg.grades) {
              periods[g.periodPos] = g.periodDesc;
            }
          }

          final filtered = _selectedPeriod == null
              ? subjectList
              : subjectList
                  .map((sg) => SubjectGrades(
                        subjectId: sg.subjectId,
                        subjectDesc: sg.subjectDesc,
                        grades: sg.grades
                            .where((g) => g.periodPos == _selectedPeriod)
                            .toList(),
                      ))
                  .where((sg) => sg.grades.isNotEmpty)
                  .toList();

          return Column(
            children: [
              // Period filter chips
              if (periods.length > 1)
                SizedBox(
                  height: 52,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('Tutti'),
                        selected: _selectedPeriod == null,
                        onSelected: (_) =>
                            setState(() => _selectedPeriod = null),
                      ),
                      ...periods.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              label: Text('${e.key}° ${e.value}'),
                              selected: _selectedPeriod == e.key,
                              onSelected: (_) =>
                                  setState(() => _selectedPeriod = e.key),
                            ),
                          )),
                    ],
                  ),
                ),
              // Overall summary
              _OverallSummary(subjectList: filtered),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _SubjectCard(subject: filtered[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverallSummary extends StatelessWidget {
  final List<SubjectGrades> subjectList;

  const _OverallSummary({required this.subjectList});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allValid = subjectList
        .expand((sg) => sg.validGrades)
        .where((g) => g.decimalValue != null)
        .toList();

    final overall = allValid.isEmpty
        ? null
        : allValid.fold(0.0, (s, g) => s + g.decimalValue!) / allValid.length;

    final below6 = subjectList
        .where((sg) => (sg.average ?? 10) < 6.0 && sg.validGrades.isNotEmpty)
        .length;

    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Media generale',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  overall != null ? overall.toStringAsFixed(2) : '—',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: overall != null
                        ? _avgColor(overall)
                        : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (below6 > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$below6 materia${below6 > 1 ? 'e' : ''}\nsotto al 6',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${allValid.length} voti',
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 12)),
              Text('${subjectList.length} materie',
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Color _avgColor(double v) {
    if (v >= 6) return const Color(0xFF2E7D32);
    if (v >= 5) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectGrades subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avg = subject.average;
    final chipBg = gradeChipBg(avg, cs);
    final chipFg = gradeChipFg(avg, cs);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubjectDetailScreen(subject: subject),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject.subjectDesc,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: gradeBorderColor(avg), width: 1.5),
                    ),
                    child: Text(
                      avg != null ? avg.toStringAsFixed(2) : '—',
                      style: TextStyle(
                        color: chipFg,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              if (subject.validGrades.isNotEmpty) ...[
                const SizedBox(height: 12),
                _MiniGradeRow(grades: subject.validGrades),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniGradeRow extends StatelessWidget {
  final List<Grade> grades;
  const _MiniGradeRow({required this.grades});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: grades
          .take(10)
          .map((g) => Container(
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  color: gradeChipBg(g.decimalValue, cs),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    g.displayValue,
                    style: TextStyle(
                      color: gradeChipFg(g.decimalValue, cs),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Subject detail screen ─────────────────────────────────────────────────────

class SubjectDetailScreen extends StatelessWidget {
  final SubjectGrades subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avg = subject.average;
    final valid = subject.validGrades;
    final below6 = avg != null && avg < 6.0;

    return Scaffold(
      appBar: AppBar(title: Text(subject.subjectDesc)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Average hero
          Card(
            color: gradeChipBg(avg, cs),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Media',
                      style: TextStyle(
                          color: gradeChipFg(avg, cs).withOpacity(0.8),
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    avg != null ? avg.toStringAsFixed(2) : '—',
                    style: TextStyle(
                      color: gradeChipFg(avg, cs),
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('${valid.length} voti',
                      style: TextStyle(
                          color: gradeChipFg(avg, cs).withOpacity(0.8),
                          fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chart
          if (valid.length >= 2) ...[
            Card(
              color: cs.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Andamento voti',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _GradeChart(grades: valid, avg: avg ?? 6.0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reach 6 card
          if (below6) ...[
            _ReachSixCard(subject: subject),
            const SizedBox(height: 16),
          ],

          // Grade list
          Text('Voti',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cs.onSurface,
              )),
          const SizedBox(height: 8),
          ...subject.grades.map((g) => _GradeListItem(grade: g)),
        ],
      ),
    );
  }
}

class _GradeChart extends StatelessWidget {
  final List<Grade> grades;
  final double avg;
  const _GradeChart({required this.grades, required this.avg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spots = grades.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.decimalValue!);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 10,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (_) => FlLine(
            color: cs.outlineVariant.withOpacity(0.5),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: TextStyle(
                      fontSize: 10, color: cs.onSurfaceVariant)),
            ),
          ),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= grades.length) {
                      return const SizedBox.shrink();
                    }
                    final d = grades[idx].date;
                    return Text(
                      DateFormat('d/M').format(d),
                      style: TextStyle(
                          fontSize: 9, color: cs.onSurfaceVariant),
                    );
                  })),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 6,
              color: const Color(0xFFE03030).withOpacity(0.7),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => '6',
                style: const TextStyle(
                    color: Color(0xFFE03030),
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
            HorizontalLine(
              y: avg,
              color: cs.secondary.withOpacity(0.8),
              strokeWidth: 1.5,
              dashArray: [4, 3],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.bottomRight,
                labelResolver: (_) => 'M',
                style: TextStyle(
                    color: cs.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: cs.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 5,
                color: _dotColor(spot.y),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }

  Color _dotColor(double v) {
    if (v >= 6) return const Color(0xFF2E7D32);
    if (v >= 5) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }
}

class _ReachSixCard extends StatelessWidget {
  final SubjectGrades subject;
  const _ReachSixCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final targets = subject.reachTarget();

    return Card(
      color: cs.errorContainer.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    color: cs.onErrorContainer, size: 20),
                const SizedBox(width: 8),
                Text('Come recuperare il 6',
                    style: TextStyle(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
              ],
            ),
            const SizedBox(height: 14),
            if (targets.isEmpty)
              Text('Impossibile raggiungere 6 con voti aggiuntivi.',
                  style: TextStyle(color: cs.onErrorContainer))
            else
              ...targets.map((t) {
                final needed = t.gradeNeeded;
                final feasible = needed >= 0 && needed <= 10;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cs.onErrorContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('+${t.additionalGrades}',
                              style: TextStyle(
                                color: cs.onErrorContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feasible
                              ? 'Prendi ${t.additionalGrades} vot${t.additionalGrades > 1 ? 'i' : 'o'} da ${needed.toStringAsFixed(1)} o più'
                              : 'Non raggiungibile con ${t.additionalGrades} vot${t.additionalGrades > 1 ? 'i' : 'o'}',
                          style: TextStyle(
                            color: cs.onErrorContainer,
                            fontSize: 13,
                            fontWeight: feasible
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _GradeListItem extends StatelessWidget {
  final Grade grade;
  const _GradeListItem({required this.grade});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: grade.canceled
          ? cs.surfaceContainerLowest
          : cs.surfaceContainerLow,
      child: ListTile(
        onTap: () {
          HapticFeedback.selectionClick();
          showGradeDetail(context, grade);
        },
        leading: grade.canceled
            ? Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.block_rounded,
                    size: 18, color: cs.onSurfaceVariant),
              )
            : grade.isNumeric
                ? Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: gradeChipBg(grade.decimalValue, cs),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: gradeBorderColor(grade.decimalValue),
                          width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        grade.displayValue,
                        style: TextStyle(
                          color: gradeChipFg(grade.decimalValue, cs),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        grade.displayValue,
                        style: TextStyle(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
        title: Text(
          '${grade.componentDesc} · ${DateFormat('d MMM yyyy', 'it').format(grade.date)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: grade.canceled
                ? cs.onSurfaceVariant
                : cs.onSurface,
            decoration: grade.canceled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: grade.notesForFamily?.isNotEmpty == true
            ? Text(grade.notesForFamily!,
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)
            : null,
        trailing: null,
      ),
    );
  }
}

// ── Grade detail sheet ────────────────────────────────────────────────────────

void showGradeDetail(BuildContext context, Grade grade) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GradeDetailSheet(grade: grade),
  );
}

class GradeDetailSheet extends StatelessWidget {
  final Grade grade;
  const GradeDetailSheet({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = gradeChipBg(grade.decimalValue, cs);
    final fg = gradeChipFg(grade.decimalValue, cs);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
              Text(grade.subjectDesc.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.0,
                  )),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: gradeBorderColor(grade.decimalValue),
                          width: 2),
                    ),
                    child: Center(
                      child: Text(
                        grade.displayValue,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(grade.componentDesc,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d MMMM yyyy', 'it').format(grade.date),
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                        if (grade.periodDesc.isNotEmpty)
                          Text(grade.periodDesc,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              if (grade.teacherName.isNotEmpty) ...[
                _GradeDetailRow(
                  icon: Icons.person_rounded,
                  label: 'Professore',
                  value: grade.teacherName,
                  cs: cs,
                ),
                const SizedBox(height: 14),
              ],
              if (grade.notesForFamily?.isNotEmpty == true) ...[
                _GradeDetailRow(
                  icon: Icons.notes_rounded,
                  label: 'Note / Argomento',
                  value: grade.notesForFamily!,
                  cs: cs,
                ),
                const SizedBox(height: 14),
              ],
              _GradeDetailRow(
                icon: Icons.scale_rounded,
                label: 'Peso voto',
                value: grade.weightFactor == 1.0
                    ? 'Normale (1×)'
                    : '${grade.weightFactor}×',
                cs: cs,
              ),
              if (grade.canceled || grade.underlined) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    if (grade.canceled)
                      Chip(
                        label: const Text('Annullato'),
                        avatar: Icon(Icons.block_rounded,
                            size: 14, color: cs.onErrorContainer),
                        backgroundColor: cs.errorContainer,
                        labelStyle: TextStyle(
                            color: cs.onErrorContainer,
                            fontWeight: FontWeight.w600),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (grade.underlined)
                      Chip(
                        label: const Text('Sottolineato'),
                        avatar: Icon(Icons.format_underline_rounded,
                            size: 14, color: cs.onSecondaryContainer),
                        backgroundColor: cs.secondaryContainer,
                        labelStyle: TextStyle(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600),
                        visualDensity: VisualDensity.compact,
                      ),
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

class _GradeDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const _GradeDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  )),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

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
            Icon(Icons.error_outline_rounded,
                size: 56, color: cs.error),
            const SizedBox(height: 16),
            Text('Errore', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
