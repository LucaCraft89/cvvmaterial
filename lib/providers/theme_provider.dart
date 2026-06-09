import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode themeMode;
  final Color? seedColor;

  const ThemeState({this.themeMode = ThemeMode.system, this.seedColor});

  ThemeState copyWith({ThemeMode? themeMode, Color? seedColor, bool clearSeed = false}) =>
      ThemeState(
        themeMode: themeMode ?? this.themeMode,
        seedColor: clearSeed ? null : (seedColor ?? this.seedColor),
      );
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _keyMode = 'theme_mode';
  static const _keySeed = 'theme_seed';

  @override
  ThemeState build() {
    _load();
    return const ThemeState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIdx = prefs.getInt(_keyMode) ?? ThemeMode.system.index;
    final seedVal = prefs.getInt(_keySeed);
    state = ThemeState(
      themeMode: ThemeMode.values[modeIdx.clamp(0, ThemeMode.values.length - 1)],
      seedColor: seedVal != null ? Color(seedVal) : null,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, mode.index);
  }

  Future<void> setSeedColor(Color? color) async {
    state = state.copyWith(seedColor: color, clearSeed: color == null);
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove(_keySeed);
    } else {
      await prefs.setInt(_keySeed, color.toARGB32());
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);

// Preset seed colors for the color picker
const List<({Color color, String label})> kSeedPresets = [
  (color: Color(0xFF6750A4), label: 'Viola'),
  (color: Color(0xFF0066CC), label: 'Blu'),
  (color: Color(0xFF006E1C), label: 'Verde'),
  (color: Color(0xFFB3261E), label: 'Rosso'),
  (color: Color(0xFFE8700A), label: 'Arancio'),
  (color: Color(0xFF006A60), label: 'Teal'),
  (color: Color(0xFF6B4EAA), label: 'Indigo'),
  (color: Color(0xFFAD3400), label: 'Marrone'),
];

// ── Home Card Order ───────────────────────────────────────────────────────────

enum HomeCardId {
  recentGrades,
  todayLessons,
  lateArrivals,
  earlyExits,
  upcomingEvents,
}

const kHomeCardMeta = <HomeCardId, ({String label, IconData icon})>{
  HomeCardId.recentGrades: (label: 'Voti recenti', icon: Icons.grade_rounded),
  HomeCardId.todayLessons: (label: 'Lezioni di oggi', icon: Icons.schedule_rounded),
  HomeCardId.lateArrivals: (label: 'Ritardi', icon: Icons.schedule_outlined),
  HomeCardId.earlyExits: (label: 'Uscite anticipate', icon: Icons.exit_to_app_rounded),
  HomeCardId.upcomingEvents: (label: 'Prossimi appuntamenti', icon: Icons.event_rounded),
};

const _kDefaultOrder = [
  HomeCardId.todayLessons,
  HomeCardId.recentGrades,
  HomeCardId.lateArrivals,
  HomeCardId.earlyExits,
  HomeCardId.upcomingEvents,
];

class HomeCardOrderNotifier extends Notifier<List<HomeCardId>> {
  static const _key = 'home_card_order';

  @override
  List<HomeCardId> build() {
    _load();
    return List.unmodifiable(_kDefaultOrder);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved == null) return;
    final ids = saved
        .map((s) => HomeCardId.values.where((e) => e.name == s).firstOrNull)
        .whereType<HomeCardId>()
        .toList();
    final missing = _kDefaultOrder.where((id) => !ids.contains(id)).toList();
    state = List.unmodifiable([...ids, ...missing]);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = List.unmodifiable(list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list.map((e) => e.name).toList());
  }
}

final homeCardOrderProvider =
    NotifierProvider<HomeCardOrderNotifier, List<HomeCardId>>(
        HomeCardOrderNotifier.new);
