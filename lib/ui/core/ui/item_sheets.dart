import 'package:flutter/material.dart';

import '../../../domain/models/reminder.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/dates.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'buttons.dart';
import 'date_fields.dart';
import 'sheet.dart';

/// One setting of an open list or note at a time, each in its own small
/// sheet. They pop the new value; closing without saving pops null.

/// A list's deadline. Pops `(day,)`, with null meaning "remove".
class DaySheet extends StatefulWidget {
  const DaySheet({super.key, required this.initial, required this.theme});

  final DateTime? initial;
  final ListTheme theme;

  @override
  State<DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<DaySheet> {
  late DateTime _day = widget.initial ?? today();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PnSheet(
      title: l10n.deadlineTitle,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PnButton(label: l10n.save, onPressed: () => Navigator.pop<(DateTime?,)>(context, (_day,))),
          if (widget.initial != null) ...[
            const SizedBox(height: 6),
            PnButton(
              label: l10n.removeDeadline,
              kind: PnButtonKind.tertiary,
              onPressed: () => Navigator.pop<(DateTime?,)>(context, (null,)),
            ),
          ],
        ],
      ),
      children: [
        DateField(
          title: l10n.day,
          hint: l10n.dayHint,
          allowNone: false,
          value: _day,
          theme: widget.theme,
          onChanged: (d) => setState(() => _day = d ?? _day),
        ),
      ],
    );
  }
}

/// A list's or note's reminder. Pops `(reminder,)`, with null meaning
/// "remove".
class ReminderSheet extends StatefulWidget {
  const ReminderSheet({
    super.key,
    required this.initial,
    required this.defaultTime,
    required this.theme,
    this.partnerName,
    this.day,
  });

  final Reminder? initial;
  final String defaultTime;
  final ListTheme theme;

  /// Set when the item is shared: both get notified.
  final String? partnerName;

  /// Suggested day for a new reminder (the list's deadline), else today.
  final DateTime? day;

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  late Reminder _r = widget.initial ?? Reminder(date: widget.day ?? today(), time: widget.defaultTime);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PnSheet(
      title: l10n.reminderTitle,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PnButton(label: l10n.save, onPressed: () => Navigator.pop<(Reminder?,)>(context, (_r,))),
          if (widget.initial != null) ...[
            const SizedBox(height: 6),
            PnButton(
              label: l10n.removeReminder,
              kind: PnButtonKind.tertiary,
              onPressed: () => Navigator.pop<(Reminder?,)>(context, (null,)),
            ),
          ],
        ],
      ),
      children: [
        Text(
          widget.partnerName != null ? l10n.reminderBothNotified(widget.partnerName!) : l10n.reminderOnlyYou,
          style: PnText.sub,
        ),
        DateField(
          title: l10n.remindMeOn,
          allowNone: false,
          value: _r.date,
          theme: widget.theme,
          onChanged: (d) => setState(() => _r = _r.copyWith(date: d)),
        ),
        TimeChips(
          time: _r.time,
          theme: widget.theme,
          onChanged: (t) => setState(() => _r = _r.copyWith(time: t)),
        ),
      ],
    );
  }
}
