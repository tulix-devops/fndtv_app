import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';

/// §6 power management (STB): after [_idleTimeout] with no remote/pointer input,
/// shows an "Are you still watching?" prompt with a countdown; if unanswered,
/// puts the box to sleep via root. Any key or touch resets the timer.
///
/// The prompt is rendered in the guard's own subtree (a self-contained overlay),
/// so it doesn't depend on the app's Navigator/Overlay. Mounted via
/// `MaterialApp.builder` on the stb flavor only; pass-through everywhere else.
class StbPowerGuard extends StatefulWidget {
  const StbPowerGuard({super.key, required this.child});

  final Widget child;

  @override
  State<StbPowerGuard> createState() => _StbPowerGuardState();
}

class _StbPowerGuardState extends State<StbPowerGuard> {
  static const Duration _idleTimeout = Duration(hours: 3);
  static const int _countdownSeconds = 20;

  final StbSystemService _stb = StbSystemService();
  Timer? _idleTimer;
  Timer? _countdownTimer;
  bool _prompting = false;
  int _secondsLeft = _countdownSeconds;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _resetIdle();
  }

  bool _onKey(KeyEvent event) {
    // Any remote key: dismiss the prompt if up, otherwise just reset the timer.
    if (_prompting) {
      _continueWatching();
    } else {
      _resetIdle();
    }
    return false; // never consume — just observe activity
  }

  void _resetIdle() {
    if (_prompting) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _startPrompt);
  }

  void _startPrompt() {
    if (_prompting) return;
    setState(() {
      _prompting = true;
      _secondsLeft = _countdownSeconds;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) _sleepNow();
    });
  }

  void _continueWatching() {
    _countdownTimer?.cancel();
    setState(() => _prompting = false);
    _resetIdle();
  }

  Future<void> _sleepNow() async {
    _countdownTimer?.cancel();
    setState(() => _prompting = false);
    await _stb.sleep();
    _resetIdle();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _idleTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _resetIdle(),
          onPointerMove: (_) => _resetIdle(),
          child: widget.child,
        ),
        if (_prompting)
          _InactivityPrompt(
            secondsLeft: _secondsLeft,
            onContinue: _continueWatching,
          ),
      ],
    );
  }
}

class _InactivityPrompt extends StatelessWidget {
  const _InactivityPrompt({required this.secondsLeft, required this.onContinue});

  final int secondsLeft;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D28),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Inactivity Detected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Are you still watching? Device will sleep in '
                '$secondsLeft seconds.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 17),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                autofocus: true,
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7443F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
                child: const Text('Continue Watching'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
