import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/layout.dart';
import '../view_models/settings_viewmodel.dart';

/// Scrolling page with a back link and a big title, shared by the settings,
/// account and notifications screens.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.back,
    required this.onBack,
    required this.title,
    required this.children,
  });

  final String back;
  final VoidCallback onBack;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 4, bottom: bottomBarClearance),
      child: ContentWidth(
        child: Gap(
          gap: 26,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackLink(label: back, onPressed: onBack),
                const SizedBox(height: 14),
                Text(title, style: PnText.screenTitle),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

String deletionDateLabel(BuildContext context, DateTime date) =>
    DateFormat.MMMMd(AppLocalizations.of(context).localeName).format(date);

/// "Your account will be deleted on …" with a way back.
class DeletionBanner extends StatelessWidget {
  const DeletionBanner({super.key, required this.date, required this.onCancel});

  final DateTime date;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deletionBanner(deletionDateLabel(context, date)),
            style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500, color: PnColors.terraDark),
          ),
          const SizedBox(height: 10),
          PnButton(label: l10n.cancelDeletion, compact: true, onPressed: onCancel),
        ],
      ),
    );
  }
}

/// "Your 2 personal lists and 1 personal note will be deleted."
String? personalLine(AppLocalizations l10n, SettingsViewModel vm) {
  final lists = vm.personalLists, notes = vm.personalNotes;
  if (lists + notes == 0) return null;
  if (lists > 0 && notes > 0) return l10n.personalBothDeleted(lists, notes);
  if (lists > 0) return l10n.personalListsDeleted(lists);
  return l10n.personalNotesDeleted(notes);
}
