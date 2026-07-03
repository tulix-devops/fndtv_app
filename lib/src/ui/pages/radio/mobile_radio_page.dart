import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/core/audio/radio_player_service.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// Radio — large "now playing" hero for the selected language's radio channel
/// (from the API). Leans on big art + an animated equalizer.
class MobileRadioPage extends StatelessWidget {
  final FndtvLanguage language;

  const MobileRadioPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: BlocBuilder<ContentCubit, ContentState>(
        builder: (context, state) {
          if (contentIsLoading(state)) return ContentLoading(colors: colors);
          if (state.status == Status.failure) {
            return ContentError(colors: colors);
          }

          final radios =
              channelsForLanguage(state.contentList?['10']?.data, language);
          if (radios.isEmpty) {
            return Center(
              child: Text(
                context.l.noRadioChannel,
                style: GoogleFonts.sora(color: colors.textMuted, fontSize: 14),
              ),
            );
          }

          final channel = radios.first;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusPill(text: context.l.badgeOnAir, icon: Icons.circle),
                    const SizedBox(height: 28),

                    // Banner artwork
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            width: 3, color: const Color(0xFFFFE088)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: 461 / 310,
                        child: Image.network(
                          channel.images.getBanner(),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.mic_rounded,
                                size: 64, color: colors.textMuted),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text(
                      channel.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 44,
                      child: EqualizerBars(
                          color: colors.accent, height: 44, bars: 11),
                    ),
                    const SizedBox(height: 32),

                    _RadioPlayButton(channel: channel),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Big play/pause button on the radio hero — reflects the shared player state
/// and drives [RadioPlayerService] (which keeps audio alive in the background).
class _RadioPlayButton extends StatelessWidget {
  final LiveModel channel;

  const _RadioPlayButton({required this.channel});

  @override
  Widget build(BuildContext context) {
    final service = RadioPlayerService.instance;

    return ValueListenableBuilder<LiveModel?>(
      valueListenable: service.currentChannel,
      builder: (context, current, _) {
        final isCurrent = current?.id == channel.id;

        return StreamBuilder<PlayerState>(
          stream: service.playerStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final processing = state?.processingState;
            final isLoading = isCurrent &&
                (processing == ProcessingState.loading ||
                    processing == ProcessingState.buffering);
            final isPlaying = isCurrent && (state?.playing ?? false);

            if (isLoading) {
              final colors = context.uiKitColors;
              return SizedBox(
                width: 76,
                height: 76,
                child: Container(
                  decoration: BoxDecoration(
                      color: colors.accent, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(24),
                  child: const CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white),
                ),
              );
            }

            return GestureDetector(
              onTap: () => isCurrent ? service.toggle() : service.play(channel),
              child: RoundedPlayButton(
                size: 76,
                filled: true,
                icon:
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            );
          },
        );
      },
    );
  }
}
