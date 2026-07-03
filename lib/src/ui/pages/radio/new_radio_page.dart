import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/ui/pages/radio/mobile_radio_page.dart';
import 'package:fndtv/src/ui/pages/radio/tv_radio_page.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';

class NewRadioPage extends StatelessWidget {
  final FndtvLanguage language;

  const NewRadioPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return context.isTv
        ? TvRadioPage(language: language)
        : MobileRadioPage(language: language);
  }
}
