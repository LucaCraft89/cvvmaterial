import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  List<Widget> _buildAccountTiles(
    BuildContext context,
    WidgetRef ref,
    AuthState auth,
    ColorScheme cs,
  ) {
    final others =
        auth.accounts.where((a) => a.uid != auth.activeUid).toList();
    if (others.isEmpty) {
      return [
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddAccountSheet(context, ref),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Aggiungi account'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ];
    }
    return [
      const SizedBox(height: 12),
      Text('Altri account',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      Card(
        color: cs.surfaceContainerLow,
        child: Column(
          children: [
            ...others.asMap().entries.map((entry) {
              final i = entry.key;
              final acc = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.secondaryContainer,
                      child: Text(
                        acc.initials,
                        style: TextStyle(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(acc.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(acc.uid,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: cs.error, size: 20),
                          tooltip: 'Rimuovi',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Rimuovi account'),
                                content: Text(
                                    'Rimuovere ${acc.fullName} dal dispositivo?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Annulla'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Rimuovi'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(authProvider.notifier)
                                  .removeAccount(acc.uid);
                            }
                          },
                        ),
                        Icon(Icons.swap_horiz_rounded,
                            color: cs.primary, size: 20),
                      ],
                    ),
                    onTap: () =>
                        ref.read(authProvider.notifier).switchAccount(acc.uid),
                  ),
                  if (i < others.length - 1)
                    Divider(
                        height: 1,
                        indent: 72,
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                ],
              );
            }),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.tertiaryContainer,
                child: Icon(Icons.add_rounded,
                    color: cs.onTertiaryContainer, size: 20),
              ),
              title: const Text('Aggiungi account'),
              onTap: () => _showAddAccountSheet(context, ref),
            ),
          ],
        ),
      ),
    ];
  }

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddAccountSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final theme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account section
          _SectionLabel(label: 'Account'),
          if (auth.card != null)
            Card(
              color: cs.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        '${auth.card!.firstName[0]}${auth.card!.lastName[0]}',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.card!.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.card!.schName.trim(),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${auth.card!.schCity} (${auth.card!.schProv})',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'C.F. ${auth.card!.fiscalCode}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Other saved accounts + add
          ..._buildAccountTiles(context, ref, auth, cs),
          const SizedBox(height: 24),

          // Theme section
          _SectionLabel(label: 'Tema'),
          Card(
            color: cs.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modalità',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      )),
                  const SizedBox(height: 12),
                  _ThemeModeSelector(
                    current: theme.themeMode,
                    onChanged: (m) =>
                        ref.read(themeProvider.notifier).setThemeMode(m),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: cs.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Colore accento',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          )),
                      const Spacer(),
                      if (theme.seedColor != null)
                        TextButton(
                          onPressed: () => ref
                              .read(themeProvider.notifier)
                              .setSeedColor(null),
                          child: const Text('Usa dispositivo'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (theme.seedColor == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 14, color: cs.onPrimaryContainer),
                          const SizedBox(width: 6),
                          Text('Dinamico (dal dispositivo)',
                              style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kSeedPresets.map((preset) {
                      final selected = theme.seedColor == preset.color;
                      return GestureDetector(
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setSeedColor(preset.color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: preset.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? cs.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: preset.color.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 22)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App info
          _SectionLabel(label: 'App'),
          Card(
            color: cs.surfaceContainerLow,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Versione'),
                  trailing: Text('1.0.0',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('API'),
                  trailing: Text('ClasseViva REST v1',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Rimuovi account'),
                  content: const Text(
                      'Rimuovi questo account dal dispositivo? Dovrai accedere di nuovo per aggiungerlo.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annulla'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Rimuovi'),
                    ),
                  ],
                ),
              );
              if (confirm == true && auth.activeUid != null) {
                await ref
                    .read(authProvider.notifier)
                    .removeAccount(auth.activeUid!);
              }
            },
            icon: const Icon(Icons.person_remove_outlined),
            label: const Text('Rimuovi account'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Add account bottom sheet ──────────────────────────────────────────────────

class _AddAccountSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddAccountSheet({required this.ref});

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _uidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(_uidCtrl.text.trim(), _passCtrl.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && mounted) {
        Navigator.pop(context);
      }
      if (next.status == AuthStatus.unauthenticated &&
          next.error != null &&
          mounted) {
        setState(() {
          _loading = false;
          _error = next.error;
        });
      }
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Aggiungi account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _uidCtrl,
              keyboardType: TextInputType.text,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Codice fiscale / Username',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                fillColor: cs.surfaceContainerHighest,
              ),
              validator: (v) =>
                  (v?.isEmpty ?? true) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                fillColor: cs.surfaceContainerHighest,
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v?.isEmpty ?? true) ? 'Campo obbligatorio' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: cs.onErrorContainer, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: cs.onErrorContainer, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: cs.onPrimary),
                    )
                  : const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _ModeChip(
          label: 'Sistema',
          icon: Icons.brightness_auto_rounded,
          selected: current == ThemeMode.system,
          onTap: () => onChanged(ThemeMode.system),
          cs: cs,
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Chiaro',
          icon: Icons.light_mode_rounded,
          selected: current == ThemeMode.light,
          onTap: () => onChanged(ThemeMode.light),
          cs: cs,
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Scuro',
          icon: Icons.dark_mode_rounded,
          selected: current == ThemeMode.dark,
          onTap: () => onChanged(ThemeMode.dark),
          cs: cs,
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
