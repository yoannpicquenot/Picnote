import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/pn_icon.dart';

/// No note yet: like "Your first list.", with a single icon, and a button
/// that opens a new note.
class FirstNoteCard extends StatelessWidget {
  const FirstNoteCard({super.key, required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(14)),
              child: const PnIcon(PnIcons.document, color: PnColors.terraDark, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          Text(l10n.firstNoteTitle, style: PnText.sheetTitle.copyWith(color: PnColors.terra, height: 1.1)),
          const SizedBox(height: 6),
          Text(l10n.firstNoteSub, style: PnText.sub),
          const SizedBox(height: 14),
          PnButton(label: l10n.createANote, icon: PnIcons.plus, onPressed: onCreate),
        ],
      ),
    );
  }
}
