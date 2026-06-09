import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/classeviva_client.dart';
import '../api/models.dart';

final clientProvider = Provider<ClasseVivaClient>((ref) => ClasseVivaClient());

// ── Account summary ───────────────────────────────────────────────────────────

class AccountSummary {
  final String uid;
  final String studentId;
  final String firstName;
  final String lastName;

  const AccountSummary({
    required this.uid,
    required this.studentId,
    required this.firstName,
    required this.lastName,
  });

  String get initials => '${firstName[0]}${lastName[0]}';
  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'studentId': studentId,
        'firstName': firstName,
        'lastName': lastName,
      };

  factory AccountSummary.fromJson(Map<String, dynamic> j) => AccountSummary(
        uid: j['uid'] as String,
        studentId: j['studentId'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
      );
}

// ── Auth state ────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;
  final String? studentId;
  final StudentCard? card;
  final String? error;
  final List<AccountSummary> accounts;
  final String? activeUid;

  const AuthState({
    required this.status,
    this.token,
    this.studentId,
    this.card,
    this.error,
    this.accounts = const [],
    this.activeUid,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasSavedAccounts => accounts.isNotEmpty;

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    String? studentId,
    StudentCard? card,
    String? error,
    List<AccountSummary>? accounts,
    String? activeUid,
  }) =>
      AuthState(
        status: status ?? this.status,
        token: token ?? this.token,
        studentId: studentId ?? this.studentId,
        card: card ?? this.card,
        error: error ?? this.error,
        accounts: accounts ?? this.accounts,
        activeUid: activeUid ?? this.activeUid,
      );
}

// ── Auth notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  static const _storage = FlutterSecureStorage();

  static const _keyAccounts = 'cvv_accounts';
  static const _keyActiveUid = 'cvv_active_uid';
  static String _keyPass(String uid) => 'cvv_pass_$uid';
  static String _keyToken(String uid) => 'cvv_token_$uid';
  static String _keyStudentId(String uid) => 'cvv_sid_$uid';

  @override
  AuthState build() {
    _init();
    return const AuthState(status: AuthStatus.initial);
  }

  ClasseVivaClient get _client => ref.read(clientProvider);

  // ── Storage helpers ─────────────────────────────────────────────────────────

  Future<List<AccountSummary>> _loadAccounts() async {
    final raw = await _storage.read(key: _keyAccounts);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AccountSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAccounts(List<AccountSummary> accounts) async {
    await _storage.write(
      key: _keyAccounts,
      value: jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  // ── Init: auto re-login on startup ──────────────────────────────────────────

  Future<void> _init() async {
    try {
      final accounts = await _loadAccounts();
      final activeUid = await _storage.read(key: _keyActiveUid);

      if (accounts.isEmpty || activeUid == null) {
        state = AuthState(status: AuthStatus.unauthenticated, accounts: accounts);
        return;
      }

      state = AuthState(
        status: AuthStatus.loading,
        accounts: accounts,
        activeUid: activeUid,
      );

      final account = accounts.firstWhere(
        (a) => a.uid == activeUid,
        orElse: () => accounts.first,
      );
      await _loginWithCredentials(account, accounts);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _loginWithCredentials(
    AccountSummary account,
    List<AccountSummary> accounts,
  ) async {
    final token = await _storage.read(key: _keyToken(account.uid));
    final studentId = await _storage.read(key: _keyStudentId(account.uid));

    if (token != null && studentId != null) {
      _client.setToken(token);
      _client.setStudentId(studentId);

      try {
        final status = await _client.getStatus();
        if (status.remains > 0) {
          final card = await _client.getCard();
          state = AuthState(
            status: AuthStatus.authenticated,
            token: token,
            studentId: studentId,
            card: card,
            accounts: accounts,
            activeUid: account.uid,
          );
          return;
        }
      } catch (_) {
        // Token invalid, fall through to re-login
      }
    }

    // Token missing or expired — re-login with stored credentials
    final password = await _storage.read(key: _keyPass(account.uid));
    if (password == null) {
      state = AuthState(status: AuthStatus.unauthenticated, accounts: accounts);
      return;
    }

    try {
      final response = await _client.login(account.uid, password);
      _client.setToken(response.token);
      _client.setStudentId(response.ident);

      await Future.wait([
        _storage.write(key: _keyToken(account.uid), value: response.token),
        _storage.write(key: _keyStudentId(account.uid), value: response.ident),
      ]);

      final card = await _client.getCard();
      state = AuthState(
        status: AuthStatus.authenticated,
        token: response.token,
        studentId: response.ident,
        card: card,
        accounts: accounts,
        activeUid: account.uid,
      );
    } catch (_) {
      _client.clearAuth();
      state = AuthState(status: AuthStatus.unauthenticated, accounts: accounts);
    }
  }

  // ── Login (add or update account) ───────────────────────────────────────────

  Future<void> login(String uid, String pass) async {
    final accounts = await _loadAccounts();
    state = AuthState(
      status: AuthStatus.loading,
      accounts: accounts,
      activeUid: state.activeUid,
    );

    try {
      final response = await _client.login(uid, pass);
      _client.setToken(response.token);
      _client.setStudentId(response.ident);

      final card = await _client.getCard();

      final summary = AccountSummary(
        uid: uid,
        studentId: response.ident,
        firstName: response.firstName,
        lastName: response.lastName,
      );
      final updated = [
        ...accounts.where((a) => a.uid != uid),
        summary,
      ];

      await _saveAccounts(updated);
      await Future.wait([
        _storage.write(key: _keyPass(uid), value: pass),
        _storage.write(key: _keyToken(uid), value: response.token),
        _storage.write(key: _keyStudentId(uid), value: response.ident),
        _storage.write(key: _keyActiveUid, value: uid),
      ]);

      state = AuthState(
        status: AuthStatus.authenticated,
        token: response.token,
        studentId: response.ident,
        card: card,
        accounts: updated,
        activeUid: uid,
      );
    } catch (e) {
      _client.clearAuth();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
        accounts: accounts,
        activeUid: state.activeUid,
      );
    }
  }

  // ── Login with saved account (from account picker) ───────────────────────────

  Future<void> loginSavedAccount(String uid) async {
    final accounts = await _loadAccounts();
    final account = accounts.firstWhere((a) => a.uid == uid);

    _client.clearAuth();
    await _storage.write(key: _keyActiveUid, value: uid);

    state = AuthState(
      status: AuthStatus.loading,
      accounts: accounts,
      activeUid: uid,
    );

    await _loginWithCredentials(account, accounts);
  }

  // ── Switch active account ────────────────────────────────────────────────────

  Future<void> switchAccount(String uid) => loginSavedAccount(uid);

  // ── Remove account ───────────────────────────────────────────────────────────

  Future<void> removeAccount(String uid) async {
    final accounts = await _loadAccounts();
    final updated = accounts.where((a) => a.uid != uid).toList();

    await _saveAccounts(updated);
    await Future.wait([
      _storage.delete(key: _keyPass(uid)),
      _storage.delete(key: _keyToken(uid)),
      _storage.delete(key: _keyStudentId(uid)),
    ]);

    if (state.activeUid == uid) {
      _client.clearAuth();
      if (updated.isNotEmpty) {
        await _storage.write(key: _keyActiveUid, value: updated.first.uid);
        state = AuthState(
          status: AuthStatus.loading,
          accounts: updated,
        );
        await _loginWithCredentials(updated.first, updated);
      } else {
        await _storage.delete(key: _keyActiveUid);
        state = AuthState(status: AuthStatus.unauthenticated, accounts: updated);
      }
    } else {
      state = state.copyWith(accounts: updated);
    }
  }

  // ── Logout (clear session, keep credentials for next launch) ─────────────────

  Future<void> logout() async {
    _client.clearAuth();
    await _storage.delete(key: _keyActiveUid);
    final accounts = await _loadAccounts();
    state = AuthState(status: AuthStatus.unauthenticated, accounts: accounts);
  }

  String _parseError(Object e) {
    final s = e.toString();
    if (s.contains('401') || s.contains('403')) return 'Credenziali errate';
    if (s.contains('SocketException') || s.contains('connect')) {
      return 'Nessuna connessione internet';
    }
    return 'Errore: $s';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
