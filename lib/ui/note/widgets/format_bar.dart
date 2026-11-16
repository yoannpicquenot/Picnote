import 'package:flutter/material.dart';

import '../../../domain/models/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';

/// Bold, italic, underline: sits on top of the keyboard while text is
/// selected in a note, like Notion's.
class FormatBar extends StatelessWidget {
  const FormatBar({super.key, required this.selection, required this.isActive, required this.onToggle});

  static const height = 52.0;

  /// Notifies as the selection moves, so the buttons follow it.
  final Listenable selection;
  final bool Function(InlineStyle) isActive;
  final ValueChanged<InlineStyle> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const base = TextStyle(fontSize: 20, height: 1, color: PnColors.ink);
    // Part of the editor: tapping it neither unfocuses nor deselects.
    return TextFieldTapRegion(
      child: ListenableBuilder(
        listenable: selection,
        builder: (context, _) => Container(
          height: height,
          decoration: const BoxDecoration(
            color: PnColors.snow,
            border: Border(top: BorderSide(color: PnColors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _button(InlineStyle.bold, l10n.formatBold, base.copyWith(fontWeight: FontWeight.w700), 'B'),
              _button(InlineStyle.italic, l10n.formatItalic, base.copyWith(fontStyle: FontStyle.italic), 'I'),
              _button(
                InlineStyle.underline,
                l10n.formatUnderline,
                base.copyWith(decoration: TextDecoration.underline),
                'U',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(InlineStyle style, String label, TextStyle textStyle, String glyph) {
    final on = isActive(style);
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onToggle(style),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 44,
          height: 36,
          margin: const EdgeInsets.only(right: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? PnColors.peach : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(glyph, style: textStyle.copyWith(color: on ? PnColors.terraDark : PnColors.ink)),
        ),
      ),
    );
  }
}
