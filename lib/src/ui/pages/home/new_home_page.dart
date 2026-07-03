import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/pages/home/mobile_home_page.dart';
import 'package:fndtv/src/ui/pages/home/tv_home_page.dart';

/// Home — editorial layout from the live API. Shows the selected language's
/// live channels (main + Chicago time), then its radio.
class NewHomePage extends StatefulWidget {
  final FndtvLanguage language;

  const NewHomePage({super.key, required this.language});

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  @override
  Widget build(BuildContext context) {
    return context.isTv
        ? TvHomePage(language: widget.language)
        : MobileHomePage(language: widget.language);
  }
}
