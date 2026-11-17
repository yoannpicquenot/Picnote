import 'package:flutter/material.dart';

import '../../../domain/models/task_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/list_hero.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/rise_in.dart';

/// Colored list tile of the home grid. Rises in, staggered by [index].
class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.list,
    required this.subtitle,
    required this.onTap,
    this.index = 0,
    this.showPerso = true,
    this.rise = true,
  });

  final TaskList list;
  final String subtitle;
  final VoidCallback onTap;
  final int index;

  /// Hidden while alone in the household: everything is personal anyway.
  final bool showPerso;

  /// Rises in when it first shows.
  final bool rise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = ListTheme.of(list.color);
    final card = Pressable(
      onTap: onTap,
      child: Stack(
        // Passes the grid row's height on, so the title sits at the bottom.
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: ListBackdrop(listId: list.id, color: t.bg, radius: BorderRadius.circular(24)),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PnIcon.list(list.icon, color: t.fg, size: 26),
                    const Spacer(),
                    if (!list.isShared && showPerso) PersoMark(label: l10n.listPersonal, color: t.fg),
                  ],
                ),
                const SizedBox(height: 12),
                const Spacer(),
                ListTitle(
                  listId: list.id,
                  text: '${list.name}.',
                  maxLines: 2,
                  style: PnText.cardTitle.copyWith(color: t.fg),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: t.fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return rise ? RiseIn.staggered(index: index, child: card) : card;
  }
}

/// Empty state right after onboarding: a card to create the first list.
class FirstListCard extends StatelessWidget {
  const FirstListCard({super.key, required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const samples = [
      (ListColor.mustard, ListIcon.shoppingCart),
      (ListColor.sage, ListIcon.house),
      (ListColor.cocoa, ListIcon.gift),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PnColors.snow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PnColors.peachLine, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (color, icon) in samples) ...[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: ListTheme.of(color).bg, borderRadius: BorderRadius.circular(14)),
                  child: PnIcon.list(icon, color: ListTheme.of(color).fg, size: 20),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(l10n.firstListTitle, style: PnText.sheetTitle.copyWith(color: PnColors.terra, height: 1.1)),
          const SizedBox(height: 6),
          Text(l10n.firstListSub, style: PnText.sub),
          const SizedBox(height: 14),
          PnButton(label: l10n.createAList, icon: PnIcons.plus, onPressed: onCreate),
        ],
      ),
    );
  }
}
