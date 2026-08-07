import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/core/services/update_progress_controller.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kAccent = Color(0xFFE0433D);

/// Full-screen "Updating…" overlay shown while an MDM `UPDATE_APP` command
/// downloads and installs a new build, so the box isn't silently downloading
/// behind a frozen-looking screen. Driven by [UpdateProgressController]; hidden
/// when nothing is in progress.
class TvUpdateOverlay extends StatelessWidget {
  const TvUpdateOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<UpdateProgressController>();
    return ValueListenableBuilder<UpdateProgress?>(
      valueListenable: controller.progress,
      builder: (context, progress, _) {
        if (progress == null) return const SizedBox.shrink();
        final l = context.l;
        final downloading = progress.phase == UpdatePhase.downloading;
        final pct = ((progress.value ?? 0) * 100).round();
        return Positioned.fill(
          child: PopScope(
            canPop: false,
            child: Material(
              // Solid, opaque backdrop — a forced update fully covers the app.
              color: const Color(0xFF0A0D12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.system_update_rounded,
                          color: Colors.white70, size: 60),
                      const SizedBox(height: 22),
                      Text(
                        // Not "Update available" — by the time this overlay is
                        // up the update is already downloading or installing,
                        // and the old wording read like nothing had started.
                        l.updatesInProgress,
                        style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 22),
                      if (downloading) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.updatesDownloading,
                                style: GoogleFonts.sora(
                                    color: Colors.white70, fontSize: 14)),
                            Text('$pct%',
                                style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.value,
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_kAccent),
                          ),
                        ),
                      ] else ...[
                        const CircularProgressIndicator(color: _kAccent),
                        const SizedBox(height: 16),
                        Text(l.updatesInstalling,
                            style: GoogleFonts.sora(
                                color: Colors.white70, fontSize: 15)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
