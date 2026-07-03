import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/pages/live/mobile_live_page.dart';
import 'package:fndtv/src/ui/pages/live/tv_live_page.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// Live — the selected language's live channels from the API: Live TV (main)
/// and Chicago time (time-shift).
class NewLivePage extends StatelessWidget {
  final FndtvLanguage language;

  const NewLivePage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return context.isTv
        ? TvLivePage(language: language)
        : MobileLivePage(language: language);
  }
}
