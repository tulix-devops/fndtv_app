import 'package:flutter/material.dart';
import 'package:fndtv/src/core/services/stb_kiosk_guard.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';

/// Everything that decides whether the kiosk takeover can work, on screen.
///
/// Built to be **photographed**. A box in a customer's living room is not on
/// adb, and "it did the same thing" does not say which of root, device owner,
/// the HOME role or the app removal failed — nor whether the boxes that
/// misbehave differ from the ones that don't. One picture of this screen
/// answers all of it.
///
/// Deliberately raw: no interpretation, no "everything is fine" summary that
/// could be wrong. Verdict lines state only what was actually measured.
class TvKioskStatusPage extends StatefulWidget {
  const TvKioskStatusPage({super.key});

  @override
  State<TvKioskStatusPage> createState() => _TvKioskStatusPageState();
}

class _TvKioskStatusPageState extends State<TvKioskStatusPage> {
  Map<String, Object?>? _diag;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final diag = await StbSystemService().kioskDiagnostics();
    if (!mounted) return;
    setState(() {
      _diag = diag;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final diag = _diag ?? const {};
    final guard = StbKioskGuard.instance;
    final status = guard.status;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F13),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 24, 48, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    autofocus: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Kiosk status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white70, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white24),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section('Takeover'),
                        // The two that matter most, first and unmissable.
                        _row('Root granted', diag['root'],
                            bad: diag['root'] != true),
                        _row('Device owner', diag['deviceOwner'],
                            bad: diag['deviceOwner'] != true),
                        _row('Home app now', diag['defaultLauncher'],
                            bad: !_isUs(diag['defaultLauncher'])),
                        _row('HOME role holder', diag['homeRoleHolder'],
                            bad: !_isUs(diag['homeRoleHolder'])),
                        _row('Other launchers', _list(diag['homeCandidates']),
                            bad: _list(diag['homeCandidates']) != 'none'),
                        _row('Last pass', 'ready=${status.ready} '
                            'durable=${status.durable} (${guard.passes} passes)',
                            bad: !status.durable),

                        _section('Why root failed, if it did'),
                        // Distinguishes "no su on this box" from "su is here but
                        // was never granted to us" — different problems, and the
                        // old code could not tell them apart.
                        _row('su binary present', diag['suBinaryPresent']),
                        _row('su id output', diag['rootId']),

                        _section('Box'),
                        _row('Model', diag['model']),
                        _row('Device', diag['device']),
                        _row('Product', diag['product']),
                        _row('Android', '${diag['androidRelease']} '
                            '(API ${diag['sdk']})'),
                        _row('Build', diag['fingerprint']),

                        _section('Clock'),
                        _row('Timezone', diag['timezone']),
                        _row('System time', diag['systemTime']),

                        const SizedBox(height: 20),
                        // Read-only by design. The takeover itself runs
                        // automatically on every launch (StbKioskGuard) — this
                        // screen only reports what it achieved.
                        const Text(
                          'The kiosk takeover runs automatically at every '
                          'launch. This screen only reports the result.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isUs(Object? v) => v is String && v.contains('com.fndtv.videoplayer');

  String _list(Object? v) {
    if (v is! List || v.isEmpty) return 'none';
    return v.join(', ');
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFE53935),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _row(String label, Object? value, {bool bad = false}) {
    final text = value == null || (value is String && value.isEmpty)
        ? '—'
        : '$value';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: bad ? const Color(0xFFFF6E6E) : Colors.white,
                fontSize: 15,
                // Monospace so a photographed fingerprint or package name can
                // actually be read back character by character.
                fontFamily: 'monospace',
                fontWeight: bad ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
