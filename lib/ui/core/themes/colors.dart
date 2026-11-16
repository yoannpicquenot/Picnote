import 'package:flutter/material.dart';

import '../../../domain/models/task_list.dart';

/// Picnote palette, from the "Tout doux" Figma file.
abstract final class PnColors {
  static const terra = Color(0xFFAF5C3C);
  static const terraDark = Color(0xFF9E4E30);
  static const terraPressed = Color(0xFF5B301F);
  static const peach = Color(0xFFFCE0C4);

  /// Outline of snow cards (inputs keep the full [peach] at rest).
  static const peachLine = Color(0x8CFCE0C4);

  /// Selected text. See-through: the note editor paints it over the letters.
  static const selection = Color(0x47AF5C3C);
  static const cream = Color(0xFFFEF7EF);
  static const cream100 = Color(0xFFFEF1E2);
  static const snow = Color(0xFFFFFDFA);
  static const ink = Color(0xFF171311);
  static const night = Color(0xFF1C120D);
  static const muted = Color(0xFF7B6C65);
  static const line = Color(0xFFE2DDDC);
  static const grey500 = Color(0xFFC3B6AF);
  static const placeholder = Color(0xFFB08C7C);
  static const sage = Color(0xFF3F7063);
  static const sageBg = Color(0xFFDCE9E1);
  static const sageInk = Color(0xFF2C564B);
  static const danger = Color(0xFFBC2F2F);
  static const roseBg = Color(0xFFF6DDDB);
  static const scrim = Color(0x591C120D);
  static const translucentSnow = Color(0x8CFFFDFA);
  static const shadow = Color(0x1F583727);

  /// Avatar colors, in picker order.
  static const avatars = [terra, sage, Color(0xFF7A5412), Color(0xFF8C323E), Color(0xFF5E3E2C)];
}

/// Background + ink pair for a list. Ink is at least 4.5:1 on the background.
class ListTheme {
  const ListTheme(this.bg, this.fg);

  final Color bg;
  final Color fg;

  static const mustard = ListTheme(Color(0xFFFAE8C4), Color(0xFF7A5412));
  static const sage = ListTheme(Color(0xFFDCE9E1), Color(0xFF2C564B));
  static const peach = ListTheme(Color(0xFFFCE0C4), Color(0xFF91462A));
  static const rose = ListTheme(Color(0xFFF6DDDB), Color(0xFF8C323E));
  static const cocoa = ListTheme(Color(0xFFEADDD2), Color(0xFF5E3E2C));

  /// Neutral theme used by notes and settings pickers.
  static const app = ListTheme(PnColors.peach, PnColors.terraDark);

  static ListTheme of(ListColor color) => switch (color) {
    ListColor.mustard => mustard,
    ListColor.sage => sage,
    ListColor.peach => peach,
    ListColor.rose => rose,
    ListColor.cocoa => cocoa,
  };
}
