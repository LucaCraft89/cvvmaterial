import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import 'home_screen.dart';
import 'grades_screen.dart';
import 'absences_screen.dart';
import 'noticeboard_screen.dart';
import 'agenda_screen.dart';
import 'files_screen.dart';
import 'documents_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';
import 'schoolbooks_screen.dart';
import 'web_view_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _screens = [
    HomeScreen(),
    GradesScreen(),
    AbsencesScreen(),
    NoticeboardScreen(),
    AgendaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedIndex = ref.watch(navTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          ref.read(navTabProvider.notifier).setTab(i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade_rounded),
            label: 'Voti',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_busy_outlined),
            selectedIcon: Icon(Icons.event_busy_rounded),
            label: 'Assenze',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Bacheca',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded),
            label: 'Agenda',
          ),
        ],
      ),
      floatingActionButton: _buildFab(context, cs, selectedIndex),
    );
  }

  Widget? _buildFab(BuildContext context, ColorScheme cs, int selectedIndex) {
    if (selectedIndex != 0) return null;

    return FloatingActionButton.extended(
      onPressed: () => _showMoreSheet(context),
      icon: const Icon(Icons.more_horiz_rounded),
      label: const Text('Altro'),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MoreSheet(),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              // Handle
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
              Text('Altro',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  )),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _ShortcutCard(
                    label: 'File',
                    icon: Icons.folder_rounded,
                    color: cs.primaryContainer,
                    onColor: cs.onPrimaryContainer,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FilesScreen()));
                    },
                  ),
                  _ShortcutCard(
                    label: 'Note',
                    icon: Icons.edit_note_rounded,
                    color: cs.secondaryContainer,
                    onColor: cs.onSecondaryContainer,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NotesScreen()));
                    },
                  ),
                  _ShortcutCard(
                    label: 'Documenti',
                    icon: Icons.description_rounded,
                    color: cs.tertiaryContainer,
                    onColor: cs.onTertiaryContainer,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DocumentsScreen()));
                    },
                  ),
                  _ShortcutCard(
                    label: 'Libri',
                    icon: Icons.menu_book_rounded,
                    color: cs.secondaryContainer,
                    onColor: cs.onSecondaryContainer,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SchoolbooksScreen()));
                    },
                  ),
                  _ShortcutCard(
                    label: 'Impostazioni',
                    icon: Icons.settings_rounded,
                    color: cs.surfaceContainerHighest,
                    onColor: cs.onSurface,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  _ShortcutCard(
                    label: 'Web',
                    icon: Icons.language_rounded,
                    color: cs.primaryContainer,
                    onColor: cs.onPrimaryContainer,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WebViewScreen(
                            url: 'https://web.spaggiari.eu/',
                            title: 'ClasseViva Web',
                            useWebAuth: true,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: onColor, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    color: onColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
