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

// ── dark terminal-green palette (shared by all dark pages) ──────────────────
const Color kDarkBg = Color(0xFF0F1A14);
const Color kDarkSurface = Color(0xFF172217);
const Color kDarkBorder = Color(0xFF2B4035);
const Color kDarkAccent = Color(0xFF3DDB87);
const Color kDarkAccentDim = Color(0xFF0B6E4F);
const Color kDarkTextHigh = Color(0xFFE8F5EE);
const Color kDarkTextMid = Color(0xFF7FA88E);
const Color kDarkTextLow = Color(0xFF3D5446);
const Color kDarkErrorText = Color(0xFFE06C5B);

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
