import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:commons/commons.dart';
import 'package:ui_kit/ui_kit.dart';

class NewGuidePage extends StatelessWidget {
  const NewGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Program schedule list
              Expanded(
                child: BlocBuilder<ContentCubit, ContentState>(
                  builder: (context, state) {
                    if (state.status == Status.loading) {
                      return Center(
                        child: CircularProgressIndicator(color: colors.accent),
                      );
                    }

                    if (state.status == Status.failure) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: colors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load schedule',
                              style: TextStyle(color: colors.textPrimary, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    // Get live content - show all program items (schedule)
                    final contentList = state.contentList?['3']?.data ?? [];
                    final scheduleItems = contentList.where((item) => !item.isMainChannel).toList();

                    if (scheduleItems.isEmpty) {
                      return Center(
                        child: Text(
                          'No programs scheduled',
                          style: TextStyle(color: colors.textMuted, fontSize: 14),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: scheduleItems.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: colors.border,
                      ),
                      itemBuilder: (context, index) {
                        return _ScheduleItem(program: scheduleItems[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
// SCHEDULE ITEM
// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

class _ScheduleItem extends StatelessWidget {
  final LiveModel program;

  const _ScheduleItem({required this.program});

  String _formatTimeRange() {
    if (program.startsAt != null && program.endsAt != null) {
      try {
        final startTime = DateTime.parse(program.startsAt!);
        final endTime = DateTime.parse(program.endsAt!);
        final startHour = startTime.hour.toString().padLeft(2, '0');
        final startMin = startTime.minute.toString().padLeft(2, '0');
        final endHour = endTime.hour.toString().padLeft(2, '0');
        final endMin = endTime.minute.toString().padLeft(2, '0');
        return '$startHour:$startMin - $endHour:$endMin';
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final timeRange = _formatTimeRange();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0), // Increased from 12 to 16
      child: Row(
        children: [
          // Thumbnail - 16:9 landscape
          Container(
            width: 96,
            height: 54,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 0.5, color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: program.images.getThumbnail().isNotEmpty &&
                     program.images.getThumbnail() != defaultPosterImage
                  ? Image.network(
                      program.images.getThumbnail(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colors.bgSurface,
                          child: Icon(Icons.tv, size: 28, color: colors.textHint),
                        );
                      },
                    )
                  : Icon(Icons.tv, size: 28, color: colors.textHint),
            ),
          ),
          
          const SizedBox(width: 14), // Increased from 12 to 14
          
          // Program info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Program title
                Text(
                  program.title,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (program.tagline != null || program.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    program.tagline ?? program.description ?? '',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colors.textPrimary.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 14), // Increased from 12 to 14
          
          // Time range on the right - bigger and more visible
          if (timeRange.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Increased padding
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(6), // Increased from 4 to 6
                border: Border.all(width: 0.5, color: colors.border),
              ),
              child: Text(
                timeRange,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
