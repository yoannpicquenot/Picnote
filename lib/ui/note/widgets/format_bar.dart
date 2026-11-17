import 'package:flutter/material.dart';

import '../../../domain/models/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import 'note_delta.dart';
import 'note_editor.dart';

/// Bold, italic, underline, headings (and their color), undo, redo: sits
/// on top of the keyboard while a note is typed in, like Notion's. "H"
/// and the color dot open their choices in place of the buttons.
class FormatBar extends StatefulWidget {
  const FormatBar({super.key, required this.editor});

  static const height = 52.0;

  final NoteEditorState editor;

  @override
  State<FormatBar> createState() => _FormatBarState();
}

enum _Panel { buttons, headings, colors }

class _FormatBarState extends State<FormatBar> {
  _Panel _panel = _Panel.buttons;

  NoteEditorState get editor => widget.editor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Part of the editor: tapping it neither unfocuses nor deselects.
    return TextFieldTapRegion(
      child: ListenableBuilder(
        listenable: editor.controller,
        builder: (context, _) => Container(
          height: FormatBar.height,
          decoration: const BoxDecoration(
            color: PnColors.snow,
            border: Border(top: BorderSide(color: PnColors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: switch (_panel) {
                _Panel.buttons => _buttons(l10n),
                _Panel.headings => _headings(l10n),
                _Panel.colors => _colors(l10n),
              },
            ),
          ),
        ),
      ),
    );
  }

  void _show(_Panel panel) => setState(() => _panel = panel);

  List<Widget> _buttons(AppLocalizations l10n) {
    const base = TextStyle(fontSize: 20, height: 1, color: PnColors.ink);
    final level = editor.headingLevel;
    return [
      _style(InlineStyle.bold, l10n.formatBold, const Icon(Icons.format_bold_rounded, size: 24)),
      _style(InlineStyle.italic, l10n.formatItalic, const Icon(Icons.format_italic_rounded, size: 24)),
      _style(InlineStyle.underline, l10n.formatUnderline, const Icon(Icons.format_underlined_rounded, size: 24)),
      _button(
        label: l10n.formatHeading,
        on: level != null,
        onTap: () => _show(_Panel.headings),
        child: Text(level == null ? 'H' : 'H$level', style: base.copyWith(fontWeight: FontWeight.w700)),
      ),
      if (level != null)
        _button(
          label: l10n.headingColor,
          onTap: () => _show(_Panel.colors),
          child: _Dot(headingColor(editor.headingColorNow)),
        ),
      _list(NoteBlockType.bullet, l10n.blockBullet, Icons.format_list_bulleted_rounded),
      _list(NoteBlockType.todo, l10n.blockCheckbox, Icons.checklist_rounded),
      const _Divider(),
      _button(
        label: l10n.formatUndo,
        onTap: editor.canUndo ? editor.undo : null,
        child: const Icon(Icons.undo_rounded, size: 22),
      ),
      _button(
        label: l10n.formatRedo,
        onTap: editor.canRedo ? editor.redo : null,
        child: const Icon(Icons.redo_rounded, size: 22),
      ),
    ];
  }

  List<Widget> _headings(AppLocalizations l10n) {
    final level = editor.headingLevel;
    void pick(int? l) {
      editor.setHeading(l);
      _show(_Panel.buttons);
    }

    return [
      _back(l10n),
      _button(
        label: l10n.blockText,
        on: level == null,
        onTap: () => pick(null),
        child: const Text('T', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      for (var l = 1; l <= NoteBlock.maxLevel; l++)
        _button(
          label: l10n.blockHeadingLevel(l),
          on: level == l,
          onTap: () => pick(l),
          child: Text(
            'H$l',
            style: TextStyle(fontSize: 20 - l * 1.5, fontWeight: FontWeight.w700),
          ),
        ),
    ];
  }

  List<Widget> _colors(AppLocalizations l10n) {
    final now = editor.headingColorNow;
    return [
      _back(l10n),
      for (final c in HeadingColor.values)
        _button(
          label: l10n.headingColorName(c.name),
          on: c == now,
          onTap: () {
            editor.setHeadingColor(c);
            _show(_Panel.buttons);
          },
          child: _Dot(headingColor(c)),
        ),
    ];
  }

  Widget _back(AppLocalizations l10n) => _button(
    label: l10n.back,
    onTap: () => _show(_Panel.buttons),
    child: const Icon(Icons.chevron_left_rounded, size: 24),
  );

  /// On: the selected lines are [type] items, and a tap makes them text.
  Widget _list(NoteBlockType type, String label, IconData icon) =>
      _button(label: label, on: editor.isList(type), onTap: () => editor.toggleList(type), child: Icon(icon, size: 24));

  Widget _style(InlineStyle style, String label, Widget glyph) =>
      _button(label: label, on: editor.isActive(style), onTap: () => editor.toggleStyle(style), child: glyph);

  Widget _button({required String label, required Widget child, VoidCallback? onTap, bool on = false}) {
    final color = onTap == null
        ? PnColors.grey500
        : on
        ? PnColors.terraDark
        : PnColors.ink;
    return Semantics(
      button: true,
      toggled: on,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
          child: IconTheme.merge(
            data: IconThemeData(color: color),
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 20, height: 1, color: color),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 24, margin: const EdgeInsets.only(left: 4, right: 8), color: PnColors.line);
}
