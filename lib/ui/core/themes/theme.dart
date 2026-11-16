import 'package:flutter/material.dart';

import 'colors.dart';

/// Display face (titles, wordmark) and body face, from the design tokens.
abstract final class PnFonts {
  static const display = 'Chillax';
  static const body = 'GeneralSans';
}

/// Text styles used across screens. Colors are set where they are used.
/// Display titles are tightened by 0.04 em.
abstract final class PnText {
  static const wordmark = TextStyle(
    fontFamily: PnFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: 0.3,
    color: PnColors.terra,
  );
  static const greeting = TextStyle(
    fontFamily: PnFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 1.1,
    letterSpacing: -1.6,
    color: PnColors.terra,
  );
  static const screenTitle = TextStyle(
    fontFamily: PnFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 36,
    height: 1.1,
    letterSpacing: -1.44,
    color: PnColors.terra,
  );
  static const section = TextStyle(
    fontFamily: PnFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    color: PnColors.terra,
  );
  static const sheetTitle = TextStyle(fontFamily: PnFonts.display, fontWeight: FontWeight.w600, fontSize: 22);
  static const cardTitle = TextStyle(
    fontFamily: PnFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.1,
    letterSpacing: -0.8,
  );
  static const prompt = TextStyle(
    fontFamily: PnFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 26,
    height: 1.15,
    color: PnColors.ink,
  );
  static const lede = TextStyle(fontSize: 20, height: 1.2, color: PnColors.ink);
  static const body = TextStyle(fontWeight: FontWeight.w500, fontSize: 16, height: 1.3, color: PnColors.ink);
  static const sub = TextStyle(fontSize: 14, height: 1.45, color: PnColors.muted);
  static const label = TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: PnColors.muted);
  static const meta = TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: PnColors.muted);
  static const pill = TextStyle(fontWeight: FontWeight.w600, fontSize: 13);
  static const tiny = TextStyle(fontWeight: FontWeight.w600, fontSize: 11);
}

/// Picnote follows a single light palette for now; the dark tokens exist in
/// the design system but no screen is drawn with them yet.
abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: PnFonts.body,
    scaffoldBackgroundColor: PnColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PnColors.terra,
      primary: PnColors.terra,
      surface: PnColors.cream,
      onSurface: PnColors.ink,
      error: PnColors.danger,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: PnColors.terra,
      selectionColor: PnColors.selection,
      selectionHandleColor: PnColors.terra,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: PnColors.night,
      contentTextStyle: TextStyle(
        fontFamily: PnFonts.body,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: PnColors.peach,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
    ),
  );
}
