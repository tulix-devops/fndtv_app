import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ui_kit/ui_kit.dart';

/// Live — the selected language's live channels from the API: Live TV (main)
/// and Chicago time (time-shift).
class TvLivePage extends StatefulWidget {
  final FndtvLanguage language;

  const TvLivePage({super.key, required this.language});

  @override
  State<TvLivePage> createState() => _TvLivePageState();
}

class _TvLivePageState extends State<TvLivePage> {
  final _mainLiveFocusNode = FocusNode(debugLabel: 'mainLive');
  final _timeShiftFocusNode = FocusNode(debugLabel: 'timeShift');

  @override
  void initState() {
    super.initState();
    _mainLiveFocusNode.addListener(_rebuild);
    _timeShiftFocusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    _mainLiveFocusNode.removeListener(_rebuild);
    _timeShiftFocusNode.removeListener(_rebuild);
    _mainLiveFocusNode.dispose();
    _timeShiftFocusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});
  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final l = context.l;

    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        if (contentIsLoading(state)) return ContentLoading(colors: colors);
        if (state.status == Status.failure) {
          return ContentError(colors: colors);
        }

        final live =
            channelsForLanguage(state.contentList?['8']?.data, widget.language);
        final mainLive = live.where((m) => !m.isTimeShift).toList();
        final timeShift = live.where((m) => m.isTimeShift).toList();
        return FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              if (mainLive.isNotEmpty) ...[
                FndtvSectionHeader(l.sectionLiveTv),
                AppCard(
                  image: mainLive.first.images.getBanner(),
                  focusNode: _mainLiveFocusNode,
                  isSelected: _mainLiveFocusNode.hasFocus,
                  onTap: () => openLiveDetail(context, mainLive.first,
                      contentType: ContentType.television),
                  content: Text(
                    mainLive.first.title,
                    style: GoogleFonts.sora(
                      color: colors.textHint,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              if (timeShift.isNotEmpty) ...[
                FndtvSectionHeader(l.sectionChicagoTime),
                AppCard(
                  image: timeShift.first.images.getBanner(),
                  focusNode: _timeShiftFocusNode,
                  isSelected: _timeShiftFocusNode.hasFocus,
                  onTap: () => openLiveDetail(context, timeShift.first,
                      contentType: ContentType.television),
                  content: Text(
                    timeShift.first.title,
                    style: GoogleFonts.sora(
                      color: colors.textHint,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ],
          ),
        );
      },
    );
  }
}
