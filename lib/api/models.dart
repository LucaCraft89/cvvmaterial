// ignore_for_file: constant_identifier_names

// ── Auth ──────────────────────────────────────────────────────────────────────

class LoginResponse {
  final String ident;
  final String firstName;
  final String lastName;
  final String token;
  final String release;
  final String expire;

  const LoginResponse({
    required this.ident,
    required this.firstName,
    required this.lastName,
    required this.token,
    required this.release,
    required this.expire,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        ident: j['ident'] ?? '',
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        token: j['token'] ?? '',
        release: j['release'] ?? '',
        expire: j['expire'] ?? '',
      );
}

class AuthStatus {
  final String expire;
  final String release;
  final String ident;
  final int remains;

  const AuthStatus({
    required this.expire,
    required this.release,
    required this.ident,
    required this.remains,
  });

  factory AuthStatus.fromJson(Map<String, dynamic> j) => AuthStatus(
        expire: j['expire'] ?? '',
        release: j['release'] ?? '',
        ident: j['ident'] ?? '',
        remains: (j['remains'] as num?)?.toInt() ?? 0,
      );
}

// ── Card ─────────────────────────────────────────────────────────────────────

class StudentCard {
  final String ident;
  final int usrId;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String fiscalCode;
  final String schName;
  final String schCity;
  final String schProv;

  const StudentCard({
    required this.ident,
    required this.usrId,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.fiscalCode,
    required this.schName,
    required this.schCity,
    required this.schProv,
  });

  factory StudentCard.fromJson(Map<String, dynamic> j) => StudentCard(
        ident: j['ident'] ?? '',
        usrId: (j['usrId'] as num?)?.toInt() ?? 0,
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        birthDate: j['birthDate'] ?? '',
        fiscalCode: j['fiscalCode'] ?? '',
        schName: j['schName'] ?? '',
        schCity: j['schCity'] ?? '',
        schProv: j['schProv'] ?? '',
      );

  String get fullName => '$firstName $lastName';
}

// ── Grade ────────────────────────────────────────────────────────────────────

class Grade {
  final int subjectId;
  final String subjectDesc;
  final int evtId;
  final String evtCode;
  final String evtDate;
  final double? decimalValue;
  final String displayValue;
  final String? notesForFamily;
  final String apiColor;
  final bool canceled;
  final bool underlined;
  final int periodPos;
  final String periodDesc;
  final String componentDesc;
  final double weightFactor;
  final String teacherName;

  const Grade({
    required this.subjectId,
    required this.subjectDesc,
    required this.evtId,
    required this.evtCode,
    required this.evtDate,
    this.decimalValue,
    required this.displayValue,
    this.notesForFamily,
    required this.apiColor,
    required this.canceled,
    required this.underlined,
    required this.periodPos,
    required this.periodDesc,
    required this.componentDesc,
    required this.weightFactor,
    this.teacherName = '',
  });

  factory Grade.fromJson(Map<String, dynamic> j) => Grade(
        subjectId: (j['subjectId'] as num?)?.toInt() ?? 0,
        subjectDesc: j['subjectDesc'] ?? '',
        evtId: (j['evtId'] as num?)?.toInt() ?? 0,
        evtCode: j['evtCode'] ?? '',
        evtDate: j['evtDate'] ?? '',
        decimalValue: (j['decimalValue'] as num?)?.toDouble(),
        displayValue: j['displayValue'] ?? '',
        notesForFamily: j['notesForFamily'],
        apiColor: j['color'] ?? '',
        canceled: j['canceled'] ?? false,
        underlined: j['underlined'] ?? false,
        periodPos: (j['periodPos'] as num?)?.toInt() ?? 1,
        periodDesc: j['periodDesc'] ?? '',
        componentDesc: j['componentDesc'] ?? '',
        weightFactor: (j['weightFactor'] as num?)?.toDouble() ?? 1.0,
        teacherName: j['teacherName'] ?? '',
      );

  DateTime get date => DateTime.tryParse(evtDate) ?? DateTime.now();
  bool get isNumeric => decimalValue != null;
}

enum GradeColor { green, orange, red }

GradeColor gradeColorFrom(double? value) {
  if (value == null) return GradeColor.red;
  if (value >= 6.0) return GradeColor.green;
  if (value >= 5.0) return GradeColor.orange;
  return GradeColor.red;
}

class SubjectGrades {
  final int subjectId;
  final String subjectDesc;
  final List<Grade> grades;

  const SubjectGrades({
    required this.subjectId,
    required this.subjectDesc,
    required this.grades,
  });

  List<Grade> get validGrades =>
      grades.where((g) => !g.canceled && g.decimalValue != null).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  double? get average {
    final v = validGrades;
    if (v.isEmpty) return null;
    return v.fold(0.0, (s, g) => s + g.decimalValue!) / v.length;
  }

  List<({int additionalGrades, double gradeNeeded})> reachTarget(
      {double target = 6.0}) {
    final v = validGrades;
    if (v.isEmpty) return [];
    final n = v.length;
    final sum = v.fold(0.0, (s, g) => s + g.decimalValue!);
    final results = <({int additionalGrades, double gradeNeeded})>[];
    for (var x = 1; x <= 10; x++) {
      final needed = (target * (n + x) - sum) / x;
      if (needed <= 10.0) {
        results.add((additionalGrades: x, gradeNeeded: needed));
        if (results.length >= 5) break;
      }
    }
    return results;
  }
}

// ── Absence ──────────────────────────────────────────────────────────────────

enum AbsenceType { absence, lateArrival, earlyExit, unknown }

AbsenceType absenceTypeFrom(String code) {
  return switch (code) {
    'ABA0' => AbsenceType.absence,
    'ABR1' || 'ABR0' => AbsenceType.lateArrival,
    'ABU0' => AbsenceType.earlyExit,
    _ => AbsenceType.unknown,
  };
}

class HoursAbsence {
  final int hPos;
  final String subject;

  const HoursAbsence({required this.hPos, required this.subject});

  factory HoursAbsence.fromJson(Map<String, dynamic> j) =>
      HoursAbsence(hPos: (j['hPos'] as num?)?.toInt() ?? 0, subject: j['subject'] ?? '');
}

class AbsenceEvent {
  final int evtId;
  final String evtCode;
  final String evtDate;
  final int? evtHPos;
  final bool isJustified;
  final String? justifReasonCode;
  final String? justifReasonDesc;
  final List<HoursAbsence> hoursAbsence;

  const AbsenceEvent({
    required this.evtId,
    required this.evtCode,
    required this.evtDate,
    this.evtHPos,
    required this.isJustified,
    this.justifReasonCode,
    this.justifReasonDesc,
    required this.hoursAbsence,
  });

  factory AbsenceEvent.fromJson(Map<String, dynamic> j) => AbsenceEvent(
        evtId: (j['evtId'] as num?)?.toInt() ?? 0,
        evtCode: j['evtCode'] ?? '',
        evtDate: j['evtDate'] ?? '',
        evtHPos: (j['evtHPos'] as num?)?.toInt(),
        isJustified: j['isJustified'] ?? false,
        justifReasonCode: j['justifReasonCode'],
        justifReasonDesc: j['justifReasonDesc'],
        hoursAbsence: (j['hoursAbsence'] as List? ?? [])
            .map((e) => HoursAbsence.fromJson(e))
            .toList(),
      );

  AbsenceType get type => absenceTypeFrom(evtCode);
  DateTime get date => DateTime.tryParse(evtDate) ?? DateTime.now();
}

// ── Noticeboard ───────────────────────────────────────────────────────────────

class NoticeAttachment {
  final String fileName;
  final int attachNum;

  const NoticeAttachment({required this.fileName, required this.attachNum});

  factory NoticeAttachment.fromJson(Map<String, dynamic> j) => NoticeAttachment(
        fileName: j['fileName'] ?? '',
        attachNum: (j['attachNum'] as num?)?.toInt() ?? 1,
      );
}

class NoticeboardItem {
  final int pubId;
  final String pubDT;
  final bool readStatus;
  final String evtCode;
  final int cntId;
  final String cntTitle;
  final String cntCategory;
  final bool cntHasAttach;
  final bool needSign;
  final bool needReply;
  final bool needFile;
  final bool needJoin;
  final List<NoticeAttachment> attachments;

  const NoticeboardItem({
    required this.pubId,
    required this.pubDT,
    required this.readStatus,
    required this.evtCode,
    required this.cntId,
    required this.cntTitle,
    required this.cntCategory,
    required this.cntHasAttach,
    required this.needSign,
    required this.needReply,
    required this.needFile,
    required this.needJoin,
    required this.attachments,
  });

  factory NoticeboardItem.fromJson(Map<String, dynamic> j) => NoticeboardItem(
        pubId: (j['pubId'] as num?)?.toInt() ?? 0,
        pubDT: j['pubDT'] ?? '',
        readStatus: j['readStatus'] ?? false,
        evtCode: j['evtCode'] ?? '',
        cntId: (j['cntId'] as num?)?.toInt() ?? 0,
        cntTitle: j['cntTitle'] ?? '',
        cntCategory: j['cntCategory'] ?? '',
        cntHasAttach: j['cntHasAttach'] ?? false,
        needSign: j['needSign'] ?? false,
        needReply: j['needReply'] ?? false,
        needFile: j['needFile'] ?? false,
        needJoin: j['needJoin'] ?? false,
        attachments: (j['attachments'] as List? ?? [])
            .map((e) => NoticeAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  DateTime get date => DateTime.tryParse(pubDT) ?? DateTime.now();
}

class NoticeDetail {
  final String title;
  final String text;

  const NoticeDetail({required this.title, required this.text});

  factory NoticeDetail.fromJson(Map<String, dynamic> j) =>
      NoticeDetail(title: j['title'] ?? '', text: j['text'] ?? '');
}

// ── Didactics ─────────────────────────────────────────────────────────────────

class FolderContent {
  final int contentId;
  final String contentName;
  final int objectId;
  final String objectType;
  final String shareDT;

  const FolderContent({
    required this.contentId,
    required this.contentName,
    required this.objectId,
    required this.objectType,
    required this.shareDT,
  });

  factory FolderContent.fromJson(Map<String, dynamic> j) => FolderContent(
        contentId: (j['contentId'] as num?)?.toInt() ?? 0,
        contentName: j['contentName'] ?? '',
        objectId: (j['objectId'] as num?)?.toInt() ?? 0,
        objectType: j['objectType'] ?? '',
        shareDT: j['shareDT'] ?? '',
      );
}

class TeacherFolder {
  final int folderId;
  final String folderName;
  final String lastShareDT;
  final List<FolderContent> contents;

  const TeacherFolder({
    required this.folderId,
    required this.folderName,
    required this.lastShareDT,
    required this.contents,
  });

  factory TeacherFolder.fromJson(Map<String, dynamic> j) => TeacherFolder(
        folderId: (j['folderId'] as num?)?.toInt() ?? 0,
        folderName: j['folderName'] ?? '',
        lastShareDT: j['lastShareDT'] ?? '',
        contents: (j['contents'] as List? ?? [])
            .map((e) => FolderContent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TeacherDidactics {
  final String teacherId;
  final String teacherName;
  final List<TeacherFolder> folders;

  const TeacherDidactics({
    required this.teacherId,
    required this.teacherName,
    required this.folders,
  });

  factory TeacherDidactics.fromJson(Map<String, dynamic> j) => TeacherDidactics(
        teacherId: j['teacherId'] ?? '',
        teacherName: j['teacherName'] ?? '',
        folders: (j['folders'] as List? ?? [])
            .map((e) => TeacherFolder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Documents ─────────────────────────────────────────────────────────────────

class StudentDocument {
  final String hash;
  final String desc;

  const StudentDocument({required this.hash, required this.desc});

  factory StudentDocument.fromJson(Map<String, dynamic> j) =>
      StudentDocument(hash: j['hash'] ?? '', desc: j['desc'] ?? '');
}

class SchoolReport {
  final String desc;
  final String confirmLink;
  final String viewLink;

  const SchoolReport({
    required this.desc,
    required this.confirmLink,
    required this.viewLink,
  });

  factory SchoolReport.fromJson(Map<String, dynamic> j) => SchoolReport(
        desc: j['desc'] ?? '',
        confirmLink: j['confirmLink'] ?? '',
        viewLink: j['viewLink'] ?? '',
      );
}

class StudentDocuments {
  final List<StudentDocument> documents;
  final List<SchoolReport> schoolReports;

  const StudentDocuments({
    required this.documents,
    required this.schoolReports,
  });

  factory StudentDocuments.fromJson(Map<String, dynamic> j) => StudentDocuments(
        documents: (j['documents'] as List? ?? [])
            .map((e) => StudentDocument.fromJson(e as Map<String, dynamic>))
            .toList(),
        schoolReports: (j['schoolReports'] as List? ?? [])
            .map((e) => SchoolReport.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Notes ─────────────────────────────────────────────────────────────────────

enum NoteType { teacherNote, warning, classNote, suspension }

class Note {
  final int evtId;
  final String evtText;
  final String evtDate;
  final String authorName;
  final bool readStatus;
  final String? warningType;

  const Note({
    required this.evtId,
    required this.evtText,
    required this.evtDate,
    required this.authorName,
    required this.readStatus,
    this.warningType,
  });

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        evtId: (j['evtId'] as num?)?.toInt() ?? 0,
        evtText: j['evtText'] ?? '',
        evtDate: j['evtDate'] ?? '',
        authorName: j['authorName'] ?? '',
        readStatus: j['readStatus'] ?? false,
        warningType: j['warningType'],
      );

  DateTime get date => DateTime.tryParse(evtDate) ?? DateTime.now();
}

class StudentNotes {
  final List<Note> teacherNotes;
  final List<Note> classNotes;
  final List<Note> warnings;
  final List<Note> suspensions;

  const StudentNotes({
    required this.teacherNotes,
    required this.classNotes,
    required this.warnings,
    required this.suspensions,
  });

  factory StudentNotes.fromJson(Map<String, dynamic> j) => StudentNotes(
        teacherNotes: (j['NTTE'] as List? ?? [])
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList(),
        classNotes: (j['NTCL'] as List? ?? [])
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList(),
        warnings: (j['NTWN'] as List? ?? [])
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList(),
        suspensions: (j['NTST'] as List? ?? [])
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get total =>
      teacherNotes.length + classNotes.length + warnings.length + suspensions.length;
}

// ── Agenda ────────────────────────────────────────────────────────────────────

enum AgendaEventType { homework, test, reminder, other }

AgendaEventType agendaTypeFrom(String code) {
  return switch (code) {
    'AGHW' => AgendaEventType.homework,
    'AGNT' || 'AGVE' => AgendaEventType.test,
    'AGCM' => AgendaEventType.reminder,
    _ => AgendaEventType.other,
  };
}

class AgendaEvent {
  final int evtId;
  final String evtCode;
  final String evtDatetimeBegin;
  final String evtDatetimeEnd;
  final bool isFullDay;
  final String? notes;
  final String authorName;
  final String subjectDesc;

  const AgendaEvent({
    required this.evtId,
    required this.evtCode,
    required this.evtDatetimeBegin,
    required this.evtDatetimeEnd,
    required this.isFullDay,
    this.notes,
    required this.authorName,
    required this.subjectDesc,
  });

  factory AgendaEvent.fromJson(Map<String, dynamic> j) => AgendaEvent(
        evtId: (j['evtId'] as num?)?.toInt() ?? 0,
        evtCode: j['evtCode'] ?? '',
        evtDatetimeBegin: j['evtDatetimeBegin'] ?? '',
        evtDatetimeEnd: j['evtDatetimeEnd'] ?? '',
        isFullDay: j['isFullDay'] ?? false,
        notes: j['notes'],
        authorName: j['authorName'] ?? '',
        subjectDesc: j['subjectDesc'] ?? '',
      );

  DateTime get dateBegin =>
      DateTime.tryParse(evtDatetimeBegin) ?? DateTime.now();
  AgendaEventType get type => agendaTypeFrom(evtCode);
}

// ── Lessons ───────────────────────────────────────────────────────────────────

class Lesson {
  final int evtId;
  final String evtDate;
  final int evtHPos;
  final int evtDuration;
  final String subjectDesc;
  final String authorName;
  final String lessonType;
  final String lessonArg;

  const Lesson({
    required this.evtId,
    required this.evtDate,
    required this.evtHPos,
    required this.evtDuration,
    required this.subjectDesc,
    required this.authorName,
    required this.lessonType,
    required this.lessonArg,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        evtId: (j['evtId'] as num?)?.toInt() ?? 0,
        evtDate: j['evtDate'] ?? '',
        evtHPos: (j['evtHPos'] as num?)?.toInt() ?? 0,
        evtDuration: (j['evtDuration'] as num?)?.toInt() ?? 1,
        subjectDesc: j['subjectDesc'] ?? '',
        authorName: j['authorName'] ?? '',
        lessonType: j['lessonType'] ?? '',
        lessonArg: j['lessonArg'] ?? '',
      );
}

// ── Periods ───────────────────────────────────────────────────────────────────

class Period {
  final String periodCode;
  final int periodPos;
  final String periodDesc;
  final bool isFinal;
  final String dateStart;
  final String dateEnd;

  const Period({
    required this.periodCode,
    required this.periodPos,
    required this.periodDesc,
    required this.isFinal,
    required this.dateStart,
    required this.dateEnd,
  });

  factory Period.fromJson(Map<String, dynamic> j) => Period(
        periodCode: j['periodCode'] ?? '',
        periodPos: (j['periodPos'] as num?)?.toInt() ?? 1,
        periodDesc: j['periodDesc'] ?? '',
        isFinal: j['isFinal'] ?? false,
        dateStart: j['dateStart'] ?? '',
        dateEnd: j['dateEnd'] ?? '',
      );
}

// ── Schoolbook ────────────────────────────────────────────────────────────────

class Schoolbook {
  final int bookId;
  final String? isbnCode;
  final String bookTitle;
  final String bookAuthor;
  final String publisherName;
  final String subjectDesc;
  final double? price;
  final bool toBuy;
  final bool toKeep;
  final bool isNew;

  const Schoolbook({
    required this.bookId,
    this.isbnCode,
    required this.bookTitle,
    required this.bookAuthor,
    required this.publisherName,
    required this.subjectDesc,
    this.price,
    required this.toBuy,
    required this.toKeep,
    required this.isNew,
  });

  factory Schoolbook.fromJson(Map<String, dynamic> j) => Schoolbook(
        bookId: (j['bookId'] as num?)?.toInt() ?? 0,
        isbnCode: j['isbnCode'],
        bookTitle: j['bookTitle'] ?? '',
        bookAuthor: j['bookAuthor'] ?? '',
        publisherName: j['publisherName'] ?? '',
        subjectDesc: j['subjectDesc'] ?? '',
        price: (j['price'] as num?)?.toDouble(),
        toBuy: j['toBuy'] ?? false,
        toKeep: j['toKeep'] ?? false,
        isNew: j['new'] ?? false,
      );
}

// ── Calendar ──────────────────────────────────────────────────────────────────

class CalendarDay {
  final String dayDate;
  final int dayOfWeek;
  final String dayStatus;

  const CalendarDay({
    required this.dayDate,
    required this.dayOfWeek,
    required this.dayStatus,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> j) => CalendarDay(
        dayDate: j['dayDate'] ?? '',
        dayOfWeek: (j['dayOfWeek'] as num?)?.toInt() ?? 0,
        dayStatus: j['dayStatus'] ?? '',
      );

  DateTime get date => DateTime.tryParse(dayDate) ?? DateTime.now();
  bool get isSchoolDay => dayStatus == 'SD';
  bool get isHoliday => dayStatus == 'HD';
}

// ── Subject ───────────────────────────────────────────────────────────────────

class SubjectTeacher {
  final String teacherId;
  final String teacherName;

  const SubjectTeacher({required this.teacherId, required this.teacherName});

  factory SubjectTeacher.fromJson(Map<String, dynamic> j) => SubjectTeacher(
        teacherId: j['teacherId'] ?? '',
        teacherName: j['teacherName'] ?? '',
      );
}

class Subject {
  final int id;
  final String description;
  final int order;
  final List<SubjectTeacher> teachers;

  const Subject({
    required this.id,
    required this.description,
    required this.order,
    required this.teachers,
  });

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: (j['id'] as num?)?.toInt() ?? 0,
        description: j['description'] ?? '',
        order: (j['order'] as num?)?.toInt() ?? 0,
        teachers: (j['teachers'] as List? ?? [])
            .map((e) => SubjectTeacher.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
