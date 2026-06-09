import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _showAddForm = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _uidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .login(_uidCtrl.text.trim(), _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.loading;
    final hasAccounts = auth.hasSavedAccounts;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Hero header
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primaryContainer, cs.secondaryContainer],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(Icons.school_rounded,
                          size: 48, color: cs.onPrimary),
                    ),
                    const SizedBox(height: 20),
                    Text('ClasseViva',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: cs.onPrimaryContainer,
                          letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 6),
                    Text('Registro elettronico',
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              flex: 3,
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: hasAccounts && !_showAddForm
                        ? _AccountPicker(
                            accounts: auth.accounts,
                            isLoading: isLoading,
                            error: auth.error,
                            onAccountTap: (uid) => ref
                                .read(authProvider.notifier)
                                .loginSavedAccount(uid),
                            onAddAccount: () =>
                                setState(() => _showAddForm = true),
                          )
                        : _LoginForm(
                            formKey: _formKey,
                            uidCtrl: _uidCtrl,
                            passCtrl: _passCtrl,
                            obscure: _obscure,
                            isLoading: isLoading,
                            error: auth.error,
                            showBack: hasAccounts,
                            onToggleObscure: () =>
                                setState(() => _obscure = !_obscure),
                            onSubmit: _submit,
                            onBack: () => setState(() => _showAddForm = false),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Account picker ────────────────────────────────────────────────────────────

class _AccountPicker extends StatelessWidget {
  final List<AccountSummary> accounts;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onAccountTap;
  final VoidCallback onAddAccount;

  const _AccountPicker({
    required this.accounts,
    required this.isLoading,
    required this.error,
    required this.onAccountTap,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scegli account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            )),
        const SizedBox(height: 6),
        Text('Accedi con un account salvato',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 20),
        Card(
          color: cs.surfaceContainerLow,
          child: Column(
            children: accounts.asMap().entries.map((entry) {
              final i = entry.key;
              final acc = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        acc.initials,
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(acc.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(acc.uid,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                    trailing: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.primary),
                          )
                        : Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                    onTap: isLoading ? null : () => onAccountTap(acc.uid),
                  ),
                  if (i < accounts.length - 1)
                    Divider(
                        height: 1,
                        indent: 72,
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                ],
              );
            }).toList(),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(error: error!, cs: cs),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onAddAccount,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Aggiungi account'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

// ── Login form ────────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController uidCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool isLoading;
  final String? error;
  final bool showBack;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _LoginForm({
    required this.formKey,
    required this.uidCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.error,
    required this.showBack,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Account salvati'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: cs.primary,
              ),
            ),
          Text(showBack ? 'Aggiungi account' : 'Accedi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 6),
          Text('Inserisci le tue credenziali Spaggiari',
              style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 28),
          TextFormField(
            controller: uidCtrl,
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
            controller: passCtrl,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              fillColor: cs.surfaceContainerHighest,
              suffixIcon: IconButton(
                icon: Icon(obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (v) =>
                (v?.isEmpty ?? true) ? 'Campo obbligatorio' : null,
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(error: error!, cs: cs),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: cs.onPrimary),
                  )
                : Text(showBack ? 'Aggiungi' : 'Accedi'),
          ),
        ],
      ),
    );
  }
}

// ── Shared error banner ───────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String error;
  final ColorScheme cs;

  const _ErrorBanner({required this.error, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Text(error,
                style: TextStyle(
                    color: cs.onErrorContainer, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
