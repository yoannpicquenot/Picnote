import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/reminder.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/dates.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'avatar.dart';
import 'buttons.dart';
import 'controls.dart';
import 'pn_icon.dart';
import '../../../domain/models/household.dart';

/// "Today", "Tomorrow", "in 12 days", or "3 Dec".
String dateLabel(BuildContext context, DateTime date) {
  final l10n = AppLocalizations.of(context);
  final n = daysFromToday(date);
  if (n == 0) return l10n.today;
  if (n == 1) return l10n.tomorrow;
  if (n == -1) return l10n.yesterday;
  if (n > 1 && n < 30) return l10n.inDays(n);
  return DateFormat.MMMd(l10n.localeName).format(date);
}

/// "Today at 10:00" — a missed reminder shows as today.
String reminderLabel(BuildContext context, Reminder r) =>
    AppLocalizations.of(context).reminderAt(dateLabel(context, effectiveDay(r.date)), r.time);

const reminderTimes = ['8:00', '9:00', '12:00', '18:00', '20:00'];

/// Horizontally scrolling chip row that bleeds to the sheet edges.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(width: 6), c],
        ],
      ),
    );
  }
}

/// Quick dates (None, Today, Tomorrow, This weekend, Next week) plus a
/// "Pick a date" calendar. The pill keeps the custom date it picked.
class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.hint,
    this.allowNone = true,
  });

  final String title;
  final String? hint;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final ListTheme theme;
  final bool allowNone;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late bool _calendarOpen = !_isQuick(widget.value) && widget.value == null && !widget.allowNone;

  List<(String, DateTime?)> _quick(AppLocalizations l10n) => [
    if (widget.allowNone) (l10n.dateNone, null),
    (l10n.today, inDays(0)),
    (l10n.tomorrow, inDays(1)),
    (l10n.dateThisWeekend, nextWeekday(DateTime.saturday)),
    (l10n.dateNextWeek, nextWeekday(DateTime.monday)),
  ];

  bool _isQuick(DateTime? v) {
    if (v == null) return widget.allowNone;
    final d = dateOnly(v);
    return [inDays(0), inDays(1), nextWeekday(DateTime.saturday), nextWeekday(DateTime.monday)].contains(d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = widget.theme;
    final value = widget.value == null ? null : dateOnly(widget.value!);
    final custom = value != null && !_isQuick(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(widget.title, style: PnText.label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? dateLabel(context, value) : (widget.hint ?? l10n.optional),
                textAlign: TextAlign.right,
                style: PnText.label.copyWith(color: value != null ? t.fg : PnColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ChipRow(
          children: [
            for (final (label, date) in _quick(l10n))
              ChoicePill(
                label: label,
                selected: !_calendarOpen && value == date,
                bg: t.bg,
                fg: t.fg,
                onTap: () {
                  setState(() => _calendarOpen = false);
                  widget.onChanged(date);
                },
              ),
            ChoicePill(
              label: custom ? dateLabel(context, value) : l10n.datePick,
              selected: _calendarOpen || custom,
              bg: t.bg,
              fg: t.fg,
              leading: custom ? PnIcon(PnIcons.check, color: t.bg, size: 14) : null,
              onTap: () => setState(() => _calendarOpen = !_calendarOpen),
            ),
          ],
        ),
        if (_calendarOpen) ...[
          const SizedBox(height: 10),
          MonthCalendar(
            value: value,
            theme: t,
            onChanged: widget.onChanged,
            onDone: () => setState(() => _calendarOpen = false),
          ),
        ],
      ],
    );
  }
}

/// Month grid; past days are disabled. "Done" closes it.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({super.key, required this.value, required this.theme, required this.onChanged, this.onDone});

  final DateTime? value;
  final ListTheme theme;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onDone;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month = DateTime((widget.value ?? today()).year, (widget.value ?? today()).month);

  void _go(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final t = widget.theme;
    final now = today();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    final offset = (DateTime(_month.year, _month.month, 1).weekday + 6) % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final value = widget.value;
    final title = DateFormat.yMMMM(locale).format(_month);
    final weekdays = [for (var i = 0; i < 7; i++) DateFormat.EEEEE(locale).format(DateTime(2024, 1, 1 + i))];

    Widget nav(int delta, bool disabled) => Opacity(
      opacity: disabled ? 0.3 : 1,
      child: IconChip(
        onPressed: disabled ? null : () => _go(delta),
        background: disabled ? Colors.transparent : t.bg,
        label: delta < 0 ? l10n.previousMonth : l10n.nextMonth,
        child: PnIcon(PnIcons.chevronRight, color: t.fg, size: 18, turns: delta < 0 ? 2 : 0),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PnColors.line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              nav(-1, isCurrent),
              Text(
                toBeginningOfSentenceCase(title),
                style: TextStyle(fontFamily: PnFonts.display, fontWeight: FontWeight.w600, fontSize: 17, color: t.fg),
              ),
              nav(1, false),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in weekdays)
                Expanded(
                  child: Center(
                    child: Text(d.toUpperCase(), style: PnText.tiny.copyWith(color: PnColors.muted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.05,
            children: [
              for (var i = 0; i < offset; i++) const SizedBox.shrink(),
              for (var day = 1; day <= days; day++)
                Builder(
                  builder: (context) {
                    final date = DateTime(_month.year, _month.month, day);
                    final past = date.isBefore(now);
                    final selected = value != null && dateOnly(value) == date;
                    final isToday = date == now;
                    return GestureDetector(
                      onTap: past ? null : () => widget.onChanged(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? t.fg : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isToday && !selected ? Border.all(color: t.bg, width: 2) : null,
                        ),
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: selected || isToday ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                            color: selected ? t.bg : (past ? PnColors.line : PnColors.ink),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (widget.onDone != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? DateFormat.MMMMEEEEd(locale).format(value) : l10n.datePickDay,
                    style: PnText.pill.copyWith(color: value != null ? t.fg : PnColors.muted),
                  ),
                ),
                Opacity(
                  opacity: value != null ? 1 : 0.4,
                  child: Pressable(
                    onTap: value != null ? widget.onDone : null,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: t.fg, borderRadius: BorderRadius.circular(14)),
                      child: Text(l10n.calendarDone, style: PnText.pill.copyWith(color: t.bg)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Reminder time picker: a few fixed times.
class TimeChips extends StatelessWidget {
  const TimeChips({super.key, required this.time, required this.onChanged, required this.theme});

  final String time;
  final ValueChanged<String> onChanged;
  final ListTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppLocalizations.of(context).time, style: PnText.label),
        const SizedBox(height: 8),
        _ChipRow(
          children: [
            for (final t in reminderTimes)
              ChoicePill(label: t, selected: time == t, bg: theme.bg, fg: theme.fg, onTap: () => onChanged(t)),
          ],
        ),
      ],
    );
  }
}

/// "Only me" / "Household" choice when creating a list or a note.
class VisibilityPicker extends StatelessWidget {
  const VisibilityPicker({
    super.key,
    required this.shared,
    required this.onChanged,
    required this.theme,
    required this.members,
    required this.partnerName,
    this.note = false,
  });

  final bool shared;
  final ValueChanged<bool> onChanged;
  final ListTheme theme;
  final List<Member> members;
  final String partnerName;
  final bool note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget option(bool value, String title, String sub) {
      final on = shared == value;
      // No press effect: only the selected option is colored.
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: on ? theme.bg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: on ? theme.fg : PnColors.line, width: on ? 2 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (value)
                        AvatarStack(members: members, size: 16, ring: on ? theme.bg : PnColors.snow, overlap: 6)
                      else
                        PnIcon(PnIcons.lock, color: on ? theme.fg : PnColors.muted, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: on ? theme.fg : PnColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(sub, style: PnText.meta.copyWith(color: on ? theme.fg : PnColors.muted)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.whoSeesIt, style: PnText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            // Shared first: it is the default.
            option(true, l10n.theHousehold, l10n.partnerSeesItToo(partnerName)),
            const SizedBox(width: 8),
            option(false, l10n.onlyMe, note ? l10n.personalNote : l10n.personalList),
          ],
        ),
      ],
    );
  }
}
