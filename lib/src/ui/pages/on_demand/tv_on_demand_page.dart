import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart';
import 'package:ui_kit/ui_kit.dart';

/// On Demand (TV) — a dark, D-pad-navigable poster grid of the selected
/// language's VOD items.
class TvOnDemandPage extends StatelessWidget {
  final FndtvLanguage language;

  const TvOnDemandPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final l = context.l;

    return Scaffold(
      backgroundColor: kTvBg,
      body: BlocBuilder<ContentCubit, ContentState>(
        builder: (context, state) {
          if (contentIsLoading(state)) return ContentLoading(colors: colors);
          if (state.status == Status.failure) {
            return ContentError(colors: colors);
          }

          final items =
              channelsForLanguage(state.contentList?['17']?.data, language);

          if (items.isEmpty) {
            return Center(
              child: Text(
                'No videos available',
                style: GoogleFonts.sora(color: Colors.white38, fontSize: 15),
              ),
            );
          }

          return FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(44, 22, 44, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvSectionHeader(l.sectionOnDemand),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        childAspectRatio: 16 / 9,
                        mainAxisSpacing: 22,
                        crossAxisSpacing: 20,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _TvVodCard(
                        item: items[i],
                        autofocus: i == 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TvVodCard extends StatefulWidget {
  final LiveModel item;
  final bool autofocus;

  const _TvVodCard({required this.item, this.autofocus = false});

  @override
  State<_TvVodCard> createState() => _TvVodCardState();
}

class _TvVodCardState extends State<_TvVodCard> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() => _focused = _node.hasFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focused;

    return InkWell(
      focusNode: _node,
      autofocus: widget.autofocus,
      onTap: () => openChannel(context, widget.item, ContentType.dvr),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // A Container's `decoration` border insets its child by the border
        // width, so a 1px→3px change on focus would re-inset and RESIZE the
        // poster every time focus moves (the visible "twitch"). Keep the base
        // border a constant 1px, and draw the focus ring via
        // `foregroundDecoration` — which paints OVER the child without insetting
        // it — so focusing never changes layout.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: kTvAccent.withValues(alpha: 0.5),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        foregroundDecoration: focused
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kTvAccent, width: 3),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.item.images.getBanner(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: kTvSurface,
                  child: const Icon(Icons.movie_rounded,
                      color: Colors.white24, size: 34),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 74,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Text(
                  widget.item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
              if (focused)
                Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: kTvAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
