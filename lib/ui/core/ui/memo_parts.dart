import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/memo_task.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/dates.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'avatar.dart';
import 'buttons.dart';
import 'date_fields.dart';
import 'pn_icon.dart';

/// The Pense-bête's colors: its header, its tag on home.
const memoTheme = ListTheme.peach;

/// "9 h", "8 PM".
String memoHourLabel(BuildContext context, int hour) {
  final locale = AppLocalizations.of(context).localeName;
  // The French pattern pads the hour ("09 h").
  if (locale.startsWith('fr')) return '$hour h';
  return DateFormat.j(locale).format(DateTime(2000, 1, 1, hour));
}

/// "Aujourd’hui", "Demain", "Mardi" within the week, else as elsewhere
/// ("3 déc."). A missed reminder shows as today.
String memoDayLabel(BuildContext context, DateTime day) {
  final shown = effectiveDay(day);
  final n = daysFromToday(shown);
  if (n > 1 && n < 7) {
    final name = DateFormat.EEEE(AppLocalizations.of(context).localeName).format(shown);
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }
  return dateLabel(context, shown);
}

/// "Mardi à 20 h", null without a reminder.
String? memoWhenLabel(BuildContext context, MemoTask t) {
  if (!t.hasReminder) return null;
  return AppLocalizations.of(context)
      .reminderAt(memoDayLabel(context, t.remindOn!), memoHourLabel(context, t.remindHour!));
}

String memoRepeatLabel(AppLocalizations l10n, MemoRepeat r) => switch (r) {
  MemoRepeat.never => l10n.memoRepeatNever,
  MemoRepeat.daily => l10n.memoRepeatDaily,
  MemoRepeat.weekly => l10n.memoRepeatWeekly,
  MemoRepeat.monthly => l10n.memoRepeatMonthly,
};

/// The grey line under a task: "Mardi à 20 h, chaque semaine". Null when
/// there is nothing to say.
String? memoMetaLine(BuildContext context, MemoTask t) {
  final when = memoWhenLabel(context, t);
  if (t.repeat == MemoRepeat.never) return when;
  final repeat = memoRepeatLabel(AppLocalizations.of(context), t.repeat);
  // "Chaque semaine" reads lower case after a comma.
  return when == null ? repeat : '$when, ${repeat.substring(0, 1).toLowerCase()}${repeat.substring(1)}';
}

/// Who a task is for: their avatar, or both overlapping. Nothing for no
/// one in particular.
class MemoWho extends StatelessWidget {
  const MemoWho({super.key, required this.task, required this.members, this.size = 24, this.ring = PnColors.cream});

  final MemoTask task;
  final List<Member> members;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    if (task.forBoth) return AvatarStack(members: members, size: size, ring: ring, overlap: 8);
    final m = members.where((m) => m.id == task.forId).firstOrNull;
    return m == null ? const SizedBox.shrink() : Avatar.of(m, size: size);
  }
}

/// The Pense-bête on home and on the Lists tab: bell, title, what is left
/// ("3 pour toi, 3 pour Yoann", or "5 à faire" alone), chevron.
class MemoCard extends StatelessWidget {
  const MemoCard({super.key, required this.count, required this.partner, required this.onTap});

  final ({int open, int mine, int theirs}) count;

  /// Null while alone in the household.
  final Member? partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = partner;
    final summary = p == null ? l10n.memoCardSolo(count.open) : l10n.memoCardDuo(count.mine, count.theirs, p.name);
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      semanticLabel: '${l10n.memoName}, $summary',
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: PnColors.snow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: PnColors.peachLine, width: 2),
        ),
        child: Row(
          children: [
            const PnIcon(PnIcons.bell, color: PnColors.terra, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.memoTitle,
                    style: PnText.sheetTitle.copyWith(fontSize: 18, height: 1.15, color: PnColors.terra),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: PnColors.muted),
                  ),
                ],
              ),
            ),
            const PnIcon(PnIcons.chevronRight, color: PnColors.terraDark, size: 18),
          ],
        ),
      ),
    );
  }
}

/// On home's Today and Tomorrow, in place of a list's tag: bell and hour.
/// Opens the Pense-bête.
class MemoTag extends StatelessWidget {
  const MemoTag({super.key, required this.hour, required this.onTap});

  final int? hour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final h = hour == null ? null : memoHourLabel(context, hour!);
    return Pressable(
      onTap: onTap,
      semanticLabel: h == null ? l10n.memoName : l10n.memoTag(h),
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 5, 9, 5),
        decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PnIcon(PnIcons.bell, color: PnColors.terraDark, size: 12),
            const SizedBox(width: 4),
            Text(h ?? l10n.memoName, style: PnText.tiny.copyWith(color: PnColors.terraDark)),
          ],
        ),
      ),
    );
  }
}
