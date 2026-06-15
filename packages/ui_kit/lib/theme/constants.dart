import 'package:flutter/material.dart';

abstract final class Constants {
  static const EdgeInsets pagePadding =
      EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 48.0);
}

/// Margins used in UI
abstract final class Margins {
  static const horizontal10 = SizedBox(width: 10);
  static const horizontal6 = SizedBox(width: 6);
  static const horizontal16 = SizedBox(width: 16);
  static const horizontal12 = SizedBox(width: 12);
  static const horizontal20 = SizedBox(width: 20);

  ///Vertical Margins
  static const vertical6 = SizedBox(height: 6);
  static const vertical10 = SizedBox(height: 10);
  static const vertical20 = SizedBox(height: 20);
  static const vertical16 = SizedBox(height: 16);
  static const vertical24 = SizedBox(height: 24.0);
  static const vertical30 = SizedBox(height: 30);
  static const vertical36 = SizedBox(height: 36);
  static const vertical40 = SizedBox(height: 40);
  static const vertical48 = SizedBox(height: 48);
  static const vertical100 = SizedBox(height: 100);
}

/// Paddings used in UI

abstract final class Paddings {
  static const vertical10 = EdgeInsets.symmetric(vertical: 10);
  static const vertical24 = EdgeInsets.symmetric(vertical: 24);
  static const vertical20 = EdgeInsets.symmetric(vertical: 20);
  static const vertical12 = EdgeInsets.symmetric(vertical: 12);
  static const vertical15 = EdgeInsets.symmetric(vertical: 15);

  static const horizontal10 = EdgeInsets.symmetric(horizontal: 10);

  static const all24 = EdgeInsets.all(24);
  static const all16 = EdgeInsets.all(16);
  static const all8 = EdgeInsets.all(8);
  static const all6 = EdgeInsets.all(6);
  static const all4 = EdgeInsets.all(4);
  static const all2 = EdgeInsets.all(2);
  static const all12 = EdgeInsets.all(12);
  static const all20 = EdgeInsets.all(20);
  static const all10 = EdgeInsets.all(10);
}
