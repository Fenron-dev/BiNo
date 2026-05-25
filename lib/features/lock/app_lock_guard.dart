// Datei: lib/features/lock/app_lock_guard.dart
//
// ZWECK: Überwacht den App-Lifecycle und legt bei aktivierter Sperre
//        einen undurchsichtigen Sperrschirm über den Inhalt.
//        Beim Aufrufen der Authentifizierung (Biometrie/PIN) wird der
//        Schirm nach Erfolg entfernt.
// ABHÄNGIGKEITEN: AppLockService, WidgetsBindingObserver.
// PHASE: 6 – App-Lock.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/app_lock_service.dart';

class AppLockGuard extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGuard({super.key, required this.child});

  @override
  ConsumerState<AppLockGuard> createState() => _AppLockGuardState();
}

class _AppLockGuardState extends ConsumerState<AppLockGuard>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkOnStart() async {
    if (await AppLockService.isEnabled()) {
      if (mounted) setState(() => _locked = true);
      await _authenticate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Bei Hintergrund-Wechsel sofort sperren (Vorschau im Task-Switcher verbergen).
      _lockIfEnabled();
    } else if (state == AppLifecycleState.resumed && _locked && !_authInProgress) {
      _authenticate();
    }
  }

  Future<void> _lockIfEnabled() async {
    if (await AppLockService.isEnabled()) {
      if (mounted) setState(() => _locked = true);
    }
  }

  Future<void> _authenticate() async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);

    final success = await AppLockService.authenticate();

    if (mounted) {
      setState(() {
        _authInProgress = false;
        if (success) _locked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          _LockScreen(
            authInProgress: _authInProgress,
            onUnlock: _authenticate,
          ),
      ],
    );
  }
}

// ── Sperr-Bildschirm ──────────────────────────────────────────────────────────

class _LockScreen extends StatelessWidget {
  final bool authInProgress;
  final VoidCallback onUnlock;

  const _LockScreen({required this.authInProgress, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'BiNo ist gesperrt',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Authentifiziere dich um fortzufahren.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),
              authInProgress
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: onUnlock,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Entsperren'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
