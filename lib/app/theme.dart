import 'package:flutter/material.dart';

const Color kPrimarySeed = Color(0xFF0B6E4F);
const Color kScaffoldBackground = Color(0xFFF4EFE6);
const Color kTextDark = Color(0xFF13201A);
const Color kTextMid = Color(0xFF4D5C56);
const Color kTextLight = Color(0xFF5A6B64);
const Color kGreenBadge = Color(0xFFD7F4E7);
const Color kRedBadge = Color(0xFFFDE2E0);
const Color kNeutralBadge = Color(0xFFE8F0EC);
const Color kErrorText = Color(0xFFB42318);

ThemeData buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimarySeed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: kScaffoldBackground,
    useMaterial3: true,
  );
}
