import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../api/models.dart';
import 'auth_provider.dart';

// ── Grades ────────────────────────────────────────────────────────────────────

class GradesNotifier extends AsyncNotifier<List<Grade>> {
  @override
  Future<List<Grade>> build() => _fetch();

  Future<List<Grade>> _fetch() {
    final client = ref.read(clientProvider);
    return client.getGrades();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final gradesProvider =
    AsyncNotifierProvider<GradesNotifier, List<Grade>>(GradesNotifier.new);

// Derived: grades grouped by subject
final subjectGradesProvider = Provider<List<SubjectGrades>>((ref) {
  final gradesAsync = ref.watch(gradesProvider);
  return gradesAsync.when(
    data: (grades) {
      final map = <int, SubjectGrades>{};
      for (final g in grades) {
        map.putIfAbsent(
          g.subjectId,
          () => SubjectGrades(subjectId: g.subjectId, subjectDesc: g.subjectDesc, grades: []),
        );
        map[g.subjectId]!.grades.add(g);
      }
      for (final sg in map.values) {
        sg.grades.sort((a, b) => b.date.compareTo(a.date));
      }
      final list = map.values.toList()
        ..sort((a, b) => a.subjectDesc.compareTo(b.subjectDesc));
      return list;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ── Absences ──────────────────────────────────────────────────────────────────

class AbsencesNotifier extends AsyncNotifier<List<AbsenceEvent>> {
  @override
  Future<List<AbsenceEvent>> build() => _fetch();

  Future<List<AbsenceEvent>> _fetch() {
    final client = ref.read(clientProvider);
    return client.getAbsences();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final absencesProvider =
    AsyncNotifierProvider<AbsencesNotifier, List<AbsenceEvent>>(AbsencesNotifier.new);

// ── Noticeboard ───────────────────────────────────────────────────────────────

class NoticeboardNotifier extends AsyncNotifier<List<NoticeboardItem>> {
  @override
  Future<List<NoticeboardItem>> build() => _fetch();

  Future<List<NoticeboardItem>> _fetch() async {
    final client = ref.read(clientProvider);
    final items = await client.getNoticeboard();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<NoticeDetail?> readItem(NoticeboardItem item) async {
    try {
      final client = ref.read(clientProvider);
      final detail = await client.readNotice(item.evtCode, item.pubId);
      // Mark as read locally
      state.whenData((items) {
        final updated = items.map((i) {
          if (i.pubId == item.pubId) {
            return NoticeboardItem(
              pubId: i.pubId,
              pubDT: i.pubDT,
              readStatus: true,
              evtCode: i.evtCode,
              cntId: i.cntId,
              cntTitle: i.cntTitle,
              cntCategory: i.cntCategory,
              cntHasAttach: i.cntHasAttach,
              needSign: i.needSign,
              needReply: i.needReply,
              needFile: i.needFile,
              needJoin: i.needJoin,
              attachments: i.attachments,
            );
          }
          return i;
        }).toList();
        state = AsyncValue.data(updated);
      });
      return detail;
    } catch (_) {
      return null;
    }
  }

  Future<void> markAllRead() async {
    final client = ref.read(clientProvider);
    final unread = state.asData?.value.where((i) => !i.readStatus).toList() ?? [];
    if (unread.isEmpty) return;
    await Future.wait(unread.map((i) async {
      try { await client.readNotice(i.evtCode, i.pubId); } catch (_) {}
    }));
    state.whenData((items) {
      state = AsyncValue.data(items.map((i) {
        if (i.readStatus) return i;
        return NoticeboardItem(
          pubId: i.pubId, pubDT: i.pubDT, readStatus: true,
          evtCode: i.evtCode, cntId: i.cntId, cntTitle: i.cntTitle,
          cntCategory: i.cntCategory, cntHasAttach: i.cntHasAttach,
          needSign: i.needSign, needReply: i.needReply,
          needFile: i.needFile, needJoin: i.needJoin,
          attachments: i.attachments,
        );
      }).toList());
    });
  }

  Future<void> downloadAttachment(
      String evtCode, int pubId, int attachNum, String fileName) async {
    final client = ref.read(clientProvider);
    final bytes = await client.getNoticeAttachment(evtCode, pubId, attachNum);
    await _openBytes(bytes, fileName);
  }
}

final noticeboardProvider =
    AsyncNotifierProvider<NoticeboardNotifier, List<NoticeboardItem>>(
        NoticeboardNotifier.new);

// ── Didactics ─────────────────────────────────────────────────────────────────

class DidacticsNotifier extends AsyncNotifier<List<TeacherDidactics>> {
  @override
  Future<List<TeacherDidactics>> build() => _fetch();

  Future<List<TeacherDidactics>> _fetch() {
    final client = ref.read(clientProvider);
    return client.getDidactics();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> downloadContent(FolderContent content) async {
    final client = ref.read(clientProvider);
    final bytes = await client.getDidacticsItem(content.contentId);
    final name = content.contentName.contains('.')
        ? content.contentName
        : '${content.contentName}.pdf';
    await _openBytes(bytes, name);
  }
}

final didacticsProvider =
    AsyncNotifierProvider<DidacticsNotifier, List<TeacherDidactics>>(
        DidacticsNotifier.new);

// ── Documents ─────────────────────────────────────────────────────────────────

class DocumentsNotifier extends AsyncNotifier<StudentDocuments> {
  @override
  Future<StudentDocuments> build() => _fetch();

  Future<StudentDocuments> _fetch() {
    final client = ref.read(clientProvider);
    return client.getDocuments();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> downloadDocument(StudentDocument doc) async {
    final client = ref.read(clientProvider);
    // Trigger preparation and poll until available (max ~10 s).
    bool available = false;
    for (int i = 0; i < 10; i++) {
      try {
        available = await client.checkDocument(doc.hash);
      } catch (_) {}
      if (available) break;
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!available) throw Exception('Documento non disponibile');
    final bytes = await client.readDocument(doc.hash);
    await _openBytes(bytes, '${doc.desc}.pdf');
  }
}

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, StudentDocuments>(
        DocumentsNotifier.new);

// ── Notes ─────────────────────────────────────────────────────────────────────

class NotesNotifier extends AsyncNotifier<StudentNotes> {
  @override
  Future<StudentNotes> build() => _fetch();

  Future<StudentNotes> _fetch() async {
    final client = ref.read(clientProvider);
    final notes = await client.getNotes();
    sortDesc(List<Note> l) => l..sort((a, b) => b.date.compareTo(a.date));
    return StudentNotes(
      teacherNotes: sortDesc(notes.teacherNotes),
      classNotes: sortDesc(notes.classNotes),
      warnings: sortDesc(notes.warnings),
      suspensions: sortDesc(notes.suspensions),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> markRead(NoteType type, int noteId) async {
    final typeCode = switch (type) {
      NoteType.teacherNote => 'NTTE',
      NoteType.warning => 'NTWN',
      NoteType.classNote => 'NTCL',
      NoteType.suspension => 'NTST',
    };
    try {
      await ref.read(clientProvider).markNoteRead(typeCode, noteId);
      state.whenData((notes) {
        state = AsyncValue.data(StudentNotes(
          teacherNotes: type == NoteType.teacherNote
              ? _markInList(notes.teacherNotes, noteId)
              : notes.teacherNotes,
          classNotes: type == NoteType.classNote
              ? _markInList(notes.classNotes, noteId)
              : notes.classNotes,
          warnings: type == NoteType.warning
              ? _markInList(notes.warnings, noteId)
              : notes.warnings,
          suspensions: type == NoteType.suspension
              ? _markInList(notes.suspensions, noteId)
              : notes.suspensions,
        ));
      });
    } catch (_) {}
  }

  List<Note> _markInList(List<Note> notes, int id) => notes
      .map((n) => n.evtId == id
          ? Note(
              evtId: n.evtId,
              evtText: n.evtText,
              evtDate: n.evtDate,
              authorName: n.authorName,
              readStatus: true,
              warningType: n.warningType,
            )
          : n)
      .toList();
}

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, StudentNotes>(NotesNotifier.new);

// ── Agenda ────────────────────────────────────────────────────────────────────

class AgendaState {
  final List<AgendaEvent> events;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  AgendaState(this.events, this.rangeStart, this.rangeEnd);
}

class AgendaNotifier extends AsyncNotifier<AgendaState> {
  @override
  Future<AgendaState> build() => _fetch();

  Future<AgendaState> _fetch() async {
    final now = DateTime.now();
    // Full Italian school year: Sep 1 → Jun 30
    final schoolYear = now.month >= 9 ? now.year : now.year - 1;
    final start = DateTime(schoolYear, 9, 1);
    final end = DateTime(schoolYear + 1, 6, 30);
    final client = ref.read(clientProvider);
    final fmt = _fmtDate;
    final events = await client.getAgenda(fmt(start), fmt(end));
    events.sort((a, b) => a.dateBegin.compareTo(b.dateBegin));
    return AgendaState(events, start, end);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<void> loadRange(DateTime start, DateTime end) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(clientProvider);
      final fmt = _fmtDate;
      final events = await client.getAgenda(fmt(start), fmt(end));
      events.sort((a, b) => a.dateBegin.compareTo(b.dateBegin));
      return AgendaState(events, start, end);
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final agendaProvider =
    AsyncNotifierProvider<AgendaNotifier, AgendaState>(AgendaNotifier.new);

// ── Periods ───────────────────────────────────────────────────────────────────

final periodsProvider = FutureProvider<List<Period>>((ref) async {
  final client = ref.read(clientProvider);
  return client.getPeriods();
});

// ── Today's Lessons ───────────────────────────────────────────────────────────

final todayLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final client = ref.read(clientProvider);
  return client.getLessonsToday();
});

// ── Schoolbooks ───────────────────────────────────────────────────────────────

class SchoolbooksNotifier extends AsyncNotifier<List<Schoolbook>> {
  @override
  Future<List<Schoolbook>> build() => _fetch();

  Future<List<Schoolbook>> _fetch() {
    final client = ref.read(clientProvider);
    return client.getSchoolbooks();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final schoolbooksProvider =
    AsyncNotifierProvider<SchoolbooksNotifier, List<Schoolbook>>(
        SchoolbooksNotifier.new);

// ── Navigation ────────────────────────────────────────────────────────────────

class NavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final navTabProvider =
    NotifierProvider<NavTabNotifier, int>(NavTabNotifier.new);

class AgendaTargetDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setDay(DateTime? day) => state = day;
}

final agendaTargetDayProvider =
    NotifierProvider<AgendaTargetDayNotifier, DateTime?>(
        AgendaTargetDayNotifier.new);

// ── File helper ───────────────────────────────────────────────────────────────

Future<void> _openBytes(List<int> bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final safe = filename.replaceAll(RegExp(r'[^\w\s\-.]'), '_');
  final file = File('${dir.path}/$safe');
  await file.writeAsBytes(bytes);
  await OpenFilex.open(file.path);
}
