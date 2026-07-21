import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/pages/on_demand/mobile_on_demand_page.dart';
import 'package:fndtv/src/ui/pages/on_demand/tv_on_demand_page.dart';

/// On Demand — the selected language's VOD library (content type 17).
class NewOnDemandPage extends StatelessWidget {
  final FndtvLanguage language;

  const NewOnDemandPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return context.isTv
        ? TvOnDemandPage(language: language)
        : MobileOnDemandPage(language: language);
  }
}
