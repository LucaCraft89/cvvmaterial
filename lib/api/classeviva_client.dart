import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'models.dart';

class ClasseVivaClient {
  static const String _baseUrl = 'https://web.spaggiari.eu/rest/';
  static const String _apiKey = 'Tg1NWEwNGIgIC0K';

  late final Dio _dio;
  String? _token;
  String? _studentId;
  String _userAgent = 'CVVS/std/4.1.7 Android/10';

  ClasseVivaClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Z-Dev-ApiKey'] = _apiKey;
        options.headers['User-Agent'] = _userAgent;
        if (_token != null) {
          options.headers['Z-Auth-Token'] = _token;
        }
        handler.next(options);
      },
    ));
    _initUserAgent();
  }

  Future<void> _initUserAgent() async {
    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      _userAgent = 'CVVS/std/4.1.7 Android/${android.version.release}';
    } catch (_) {}
  }

  void setToken(String token) => _token = token;

  void setStudentId(String id) {
    // API URLs require digits-only studentId (e.g. "S9497195R" → "9497195")
    _studentId = id.replaceAll(RegExp(r'\D'), '');
  }

  void clearAuth() {
    _token = null;
    _studentId = null;
  }

  String? get studentId => _studentId;
  String? get token => _token;

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<LoginResponse> login(String uid, String pass) async {
    final res = await _dio.post('v1/auth/login',
        data: {'ident': null, 'pass': pass, 'uid': uid});
    return LoginResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthStatus> getStatus() async {
    final res = await _dio.get('v1/auth/status');
    return AuthStatus.fromJson(
        (res.data as Map<String, dynamic>)['status'] as Map<String, dynamic>);
  }

  // ── Student ─────────────────────────────────────────────────────────────────

  String get _sid => _studentId!;

  Future<StudentCard> getCard() async {
    final res = await _dio.get('v1/students/$_sid/card');
    return StudentCard.fromJson(
        (res.data as Map<String, dynamic>)['card'] as Map<String, dynamic>);
  }

  Future<List<Grade>> getGrades() async {
    final res = await _dio.get('v1/students/$_sid/grades');
    return ((res.data as Map<String, dynamic>)['grades'] as List)
        .map((e) => Grade.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AbsenceEvent>> getAbsences() async {
    final res = await _dio.get('v1/students/$_sid/absences/details');
    return ((res.data as Map<String, dynamic>)['events'] as List)
        .map((e) => AbsenceEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NoticeboardItem>> getNoticeboard() async {
    final res = await _dio.get('v1/students/$_sid/noticeboard');
    return ((res.data as Map<String, dynamic>)['items'] as List)
        .map((e) => NoticeboardItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoticeDetail> readNotice(String evtCode, int pubId) async {
    final res = await _dio
        .post('v1/students/$_sid/noticeboard/read/$evtCode/$pubId/101');
    return NoticeDetail.fromJson(
        (res.data as Map<String, dynamic>)['item'] as Map<String, dynamic>);
  }

  Future<Uint8List> getNoticeAttachment(
      String evtCode, int pubId, int attachNum) async {
    final res = await _dio.get(
      'v1/students/$_sid/noticeboard/attach/$evtCode/$pubId/$attachNum',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data as Uint8List;
  }

  Future<List<TeacherDidactics>> getDidactics() async {
    final res = await _dio.get('v1/students/$_sid/didactics');
    final data = res.data as Map<String, dynamic>;
    // API response key is "didacticts" (typo in the official API)
    final list = (data['didacticts'] ?? data['didactics']) as List? ?? [];
    return list
        .map((e) => TeacherDidactics.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Uint8List> getDidacticsItem(int contentId) async {
    final res = await _dio.get(
      'v1/students/$_sid/didactics/item/$contentId',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data as Uint8List;
  }

  Future<StudentDocuments> getDocuments() async {
    final res = await _dio.post('v1/students/$_sid/documents');
    return StudentDocuments.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> checkDocument(String hash) async {
    final res =
        await _dio.post('v1/students/$_sid/documents/check/$hash');
    final available =
        (res.data as Map<String, dynamic>)['document']?['available'];
    return available == true || available == 1 || available == '1' || available == 'true';
  }

  Future<Uint8List> readDocument(String hash) async {
    try {
      final res = await _dio.get(
        'v1/students/$_sid/documents/read/$hash',
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data as Uint8List;
    } on DioException catch (e) {
      if (e.response?.statusCode == 405) {
        final res = await _dio.post(
          'v1/students/$_sid/documents/read/$hash',
          options: Options(responseType: ResponseType.bytes),
        );
        return res.data as Uint8List;
      }
      rethrow;
    }
  }

  // Returns md5+ticket for use as the `t` parameter in restbridge.php.
  Future<String?> getWebTicket() async {
    try {
      final res = await _dio.get('v1/auth/ticket');
      if (res.data is Map) {
        final d = res.data as Map<String, dynamic>;
        final ticket = d['ticket'] as String?;
        final md5 = d['md5'] as String?;
        if (ticket == null) return null;
        return md5 != null ? md5 + ticket : ticket;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StudentNotes> getNotes() async {
    final res = await _dio.get('v1/students/$_sid/notes/all');
    return StudentNotes.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markNoteRead(String type, int noteId) async {
    await _dio.post('v1/students/$_sid/notes/$type/read/$noteId');
  }

  Future<List<AgendaEvent>> getAgenda(String begin, String end) async {
    final res = await _dio.get('v1/students/$_sid/agenda/all/$begin/$end');
    return ((res.data as Map<String, dynamic>)['agenda'] as List? ?? [])
        .map((e) => AgendaEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Lesson>> getLessonsToday() async {
    final res = await _dio.get('v1/students/$_sid/lessons/today');
    return ((res.data as Map<String, dynamic>)['lessons'] as List? ?? [])
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Lesson>> getLessons(String start, String end) async {
    final res = await _dio.get('v1/students/$_sid/lessons/$start/$end');
    return ((res.data as Map<String, dynamic>)['lessons'] as List? ?? [])
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Period>> getPeriods() async {
    final res = await _dio.get('v1/students/$_sid/periods');
    return ((res.data as Map<String, dynamic>)['periods'] as List)
        .map((e) => Period.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Subject>> getSubjects() async {
    final res = await _dio.get('v1/students/$_sid/subjects');
    return ((res.data as Map<String, dynamic>)['subjects'] as List)
        .map((e) => Subject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Schoolbook>> getSchoolbooks() async {
    final res = await _dio.get('v1/students/$_sid/schoolbooks');
    return ((res.data as Map<String, dynamic>)['schoolbooks'] as List? ?? [])
        .map((e) => Schoolbook.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CalendarDay>> getCalendar() async {
    final res = await _dio.get('v1/students/$_sid/calendar/all');
    return ((res.data as Map<String, dynamic>)['calendar'] as List? ?? [])
        .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
