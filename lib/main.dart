import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/auth_provider.dart';
import 'providers/data_providers.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it', null);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const ProviderScope(child: ClasseVivaApp()));
}

class ClasseVivaApp extends ConsumerWidget {
  const ClasseVivaApp({super.key});

  static const _fallbackSeed = Color(0xFF6750A4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (themeState.seedColor != null) {
          // User-chosen seed color
          lightScheme = ColorScheme.fromSeed(
            seedColor: themeState.seedColor!,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: themeState.seedColor!,
            brightness: Brightness.dark,
          );
        } else if (lightDynamic != null && darkDynamic != null) {
          // Material You dynamic colors from wallpaper
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Fallback
          lightScheme = ColorScheme.fromSeed(
            seedColor: _fallbackSeed,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: _fallbackSeed,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'ClasseViva',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(lightScheme),
          darkTheme: buildTheme(darkScheme),
          themeMode: themeState.themeMode,
          home: const _AuthGate(),
        );
      },
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev != null && prev.isAuthenticated && !next.isAuthenticated) {
        ref.invalidate(gradesProvider);
        ref.invalidate(absencesProvider);
        ref.invalidate(noticeboardProvider);
        ref.invalidate(didacticsProvider);
        ref.invalidate(documentsProvider);
        ref.invalidate(notesProvider);
        ref.invalidate(agendaProvider);
        ref.invalidate(periodsProvider);
        ref.invalidate(todayLessonsProvider);
        ref.invalidate(schoolbooksProvider);
        ref.invalidate(navTabProvider);
        ref.invalidate(agendaTargetDayProvider);
      }
    });

    return switch (auth.status) {
      AuthStatus.initial || AuthStatus.loading => const _SplashScreen(),
      AuthStatus.authenticated => const MainShell(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.school_rounded,
                  size: 44, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text('ClasseViva',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                )),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: cs.primary),
          ],
        ),
      ),
    );
  }
}
