import 'package:flutter/material.dart';

const Color kPrimarySeed = Color(0xFF5672B8);
const Color kScaffoldBackground = Color(0xFFECEFF6);
const Color kTextDark = Color(0xFF24324B);
const Color kTextMid = Color(0xFF64738D);
const Color kTextLight = Color(0xFF8B97AC);
const Color kGreenBadge = Color(0xFFD8EBDD);
const Color kRedBadge = Color(0xFFF6DFDE);
const Color kNeutralBadge = Color(0xFFE2E8F1);
const Color kErrorText = Color(0xFFC45663);

// Shared light glass palette used across shell pages.
const Color kDarkBg = Color(0xFFECEFF6);
const Color kDarkSurface = Color(0xE9F6F8FC);
const Color kDarkBorder = Color(0xFFCDD7E6);
const Color kDarkAccent = Color(0xFF4E6FB5);
const Color kDarkAccentDim = Color(0xFF91A9D6);
const Color kDarkTextHigh = Color(0xFF24324B);
const Color kDarkTextMid = Color(0xFF64738D);
const Color kDarkTextLow = Color(0xFF8B97AC);
const Color kDarkErrorText = Color(0xFFC45663);
const Color kGlassGlow = Color(0x3FBECCE3);
const Color kGlassGlowWarm = Color(0x34EADBCB);
const Color kGlassShadow = Color(0x12344A67);
const Color kGlassFillStrong = Color(0xEAF9FAFC);
const Color kGlassFillSoft = Color(0xC7F7F9FC);
const Color kEditorBg = Color(0xFFF0F4FA);
const Color kCodeBg = Color(0xFFE4EAF4);
const Color kMutedPanel = Color(0xFFE1E7F0);
const Color kErrorBg = Color(0xFFF9E8EB);

ThemeData buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimarySeed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: kScaffoldBackground,
    useMaterial3: true,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: kTextDark,
      displayColor: kTextDark,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF28466E),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kGlassFillStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kDarkBorder),
      ),
    ),
  );
}
