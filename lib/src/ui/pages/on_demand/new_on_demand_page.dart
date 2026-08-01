import 'package:app_localization/app_localization.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/chewie_player/chewie_player.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// On Demand — the selected language's VOD library (backend content type 17):
/// a poster grid; tapping a poster opens the Chewie player.
class NewOnDemandPage extends StatelessWidget {
  final FndtvLanguage language;

  const NewOnDemandPage({super.key, required this.language});

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

          final items =
              channelsForLanguage(state.contentList?['17']?.data, language);

          if (items.isEmpty) {
            return _Empty(colors: colors);
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 16 / 9,
              mainAxisSpacing: 14,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _VodPosterCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _VodPosterCard extends StatelessWidget {
  final LiveModel item;

  const _VodPosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final videoUrl = item.sources.getPreferredVideoSource() ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChewiePlayerPage(
            title: item.title,
            url: videoUrl,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.images.getBanner(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: colors.bgSurface,
                child:
                    Icon(Icons.movie_rounded, size: 40, color: colors.textHint),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 92,
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
              left: 10,
              right: 10,
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final UiKitColors colors;

  const _Empty({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_rounded, size: 44, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            context.l.noVideosAvailable,
            style: GoogleFonts.sora(color: colors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
