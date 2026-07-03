import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// Radio — large "now playing" hero for the selected language's radio channel
/// (from the API). Leans on big art + an animated equalizer.
class TvRadioPage extends StatefulWidget {
  final FndtvLanguage language;

  const TvRadioPage({super.key, required this.language});

  @override
  State<TvRadioPage> createState() => _TvRadioPageState();
}

class _TvRadioPageState extends State<TvRadioPage> {
  final _timeShiftFocusNode = FocusNode(debugLabel: 'timeShift');
  @override
  void initState() {
    super.initState();
    _timeShiftFocusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    _timeShiftFocusNode.removeListener(_rebuild);
    _timeShiftFocusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});
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

          final radios = channelsForLanguage(
              state.contentList?['10']?.data, widget.language);
          if (radios.isEmpty) {
            return Center(
              child: Text(
                context.l.noRadioChannel,
                style: GoogleFonts.sora(color: colors.textMuted, fontSize: 14),
              ),
            );
          }

          final channel = radios.first;
          return ListView(
            children: [
              FndtvSectionHeader(channel.title),
              AppCard(
                image: channel.images.getBanner(),
                focusNode: _timeShiftFocusNode,
                isSelected: _timeShiftFocusNode.hasFocus,
                onTap: () => openLiveDetail(context, channel,
                    contentType: ContentType.radio),
                content: Text(
                  channel.title,
                  style: GoogleFonts.sora(
                    color: colors.textHint,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
