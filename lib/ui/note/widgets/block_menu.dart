import 'package:flutter/material.dart';

import '../../../domain/models/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/ui/pn_icon.dart';

/// A "/" menu pick: the kind of line, and a heading's level.
typedef BlockPick = void Function(NoteBlockType type, {int level});

/// The "/" menu, above the keyboard: the kinds of line whose name contains
/// what was typed after the "/". Links need no block: an address typed or
/// pasted becomes a link on its own.
class BlockMenu extends StatelessWidget {
  const BlockMenu({super.key, required this.query, required this.onPick});

  final String query;
  final BlockPick onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kinds = _BlockKind.all(l10n).where((k) => k.label.toLowerCase().contains(query.toLowerCase())).toList();
    // Part of the editor: tapping it does not unfocus it.
    return TextFieldTapRegion(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(6),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
        decoration: BoxDecoration(
          color: PnColors.snow,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x2E583727), blurRadius: 40, offset: Offset(0, 8))],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final k in kinds)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onPick(k.type, level: k.level),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(10)),
                          child: k.icon,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              k.label,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: PnColors.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(k.description, style: const TextStyle(fontSize: 12, color: PnColors.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (kinds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(l10n.noBlockNamed(query), style: const TextStyle(fontSize: 13, color: PnColors.muted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockKind {
  const _BlockKind(this.type, this.label, this.description, this.icon, {this.level = 1});

  final NoteBlockType type;
  final String label;
  final String description;
  final Widget icon;
  final int level;

  static List<_BlockKind> all(AppLocalizations l10n) {
    const c = PnColors.terraDark;
    return [
      _BlockKind(
        NoteBlockType.text,
        l10n.blockText,
        l10n.blockTextDesc,
        const PnIcon(PnIcons.text, size: 18, color: c),
      ),
      for (var level = 1; level <= NoteBlock.maxLevel; level++)
        _BlockKind(
          NoteBlockType.heading,
          l10n.blockHeadingLevel(level),
          l10n.blockHeadingDesc,
          level == 1
              ? const PnIcon(PnIcons.heading, size: 18, color: c)
              : Text(
                  'H$level',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c),
                ),
          level: level,
        ),
      _BlockKind(
        NoteBlockType.bullet,
        l10n.blockBullet,
        l10n.blockBulletDesc,
        const PnIcon(PnIcons.list, size: 18, color: c),
      ),
      _BlockKind(
        NoteBlockType.todo,
        l10n.blockCheckbox,
        l10n.blockCheckboxDesc,
        const PnIcon(PnIcons.checkbox, color: c, size: 18),
      ),
      _BlockKind(
        NoteBlockType.table,
        l10n.blockTable,
        l10n.blockTableDesc,
        const Icon(Icons.table_chart_outlined, color: c, size: 18),
      ),
    ];
  }
}
