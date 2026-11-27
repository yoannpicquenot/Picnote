import 'package:flutter/material.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/memo_task.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/date_fields.dart';
import '../../core/ui/memo_parts.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/sheet.dart';

enum _For { me, partner, both }

enum _Day { none, today, tomorrow, pick }

/// "New task." or, with [initial], "Edit task.": what to do, for whom
/// (hidden while alone), when it rings and how often, and who will get the
/// reminder. Pops the task as it should be saved.
class MemoSheet extends StatefulWidget {
  const MemoSheet({super.key, this.initial, required this.meId, required this.partner, required this.defaultHour});

  final MemoTask? initial;
  final String meId;

  /// Null while alone in the household.
  final Member? partner;
  final int defaultHour;

  @override
  State<MemoSheet> createState() => _MemoSheetState();
}

class _MemoSheetState extends State<MemoSheet> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');

  late _For? _for = switch (widget.initial) {
    null => _For.me,
    final t when t.forBoth => _For.both,
    final t when t.forId == widget.meId => _For.me,
    final t when t.forId != null && t.forId == widget.partner?.id => _For.partner,
    _ => null,
  };

  late DateTime? _date = widget.initial?.remindOn;
  late int _hour = widget.initial?.remindHour ?? widget.defaultHour;
  late MemoRepeat _repeat = widget.initial?.repeat ?? MemoRepeat.never;

  /// The calendar shows after "Pick…", until a day is chosen.
  bool _calendar = false;

  /// The row unfolded: reminder or repeat.
  String? _open;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  _Day get _day {
    final d = _date;
    if (d == null) return _Day.none;
    return switch (daysFromToday(d)) {
      0 => _Day.today,
      1 => _Day.tomorrow,
      _ => _Day.pick,
    };
  }

  bool get _valid => _title.text.trim().isNotEmpty;

  void _submit() {
    if (!_valid) return;
    final who = widget.partner == null ? _For.me : _for;
    final base = widget.initial ?? const MemoTask(id: '', title: '');
    Navigator.pop(
      context,
      base.copyWith(
        title: _title.text.trim(),
        forId: () => switch (who) {
          _For.me => widget.meId,
          _For.partner => widget.partner?.id,
          _For.both || null => null,
        },
        forBoth: who == _For.both,
        remindOn: () => _date == null ? null : dateOnly(_date!),
        remindHour: () => _date == null ? null : _hour,
        repeat: _repeat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final partner = widget.partner;
    final editing = widget.initial != null;
    return PnSheet(
      title: editing ? l10n.memoEditTask : l10n.memoNewTask,
      footer: ListenableBuilder(
        listenable: _title,
        builder: (context, _) =>
            PnButton(label: editing ? l10n.memoSave : l10n.add, onPressed: _valid ? _submit : null),
      ),
      children: [
        PnTextField(
          controller: _title,
          hint: l10n.memoWhatToDo,
          tall: true,
          autofocus: !editing,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _submit(),
        ),
        if (partner != null)
          _Segmented(
            label: l10n.memoForWhom,
            value: _for,
            onChanged: (v) => setState(() => _for = v),
            items: [(_For.me, l10n.memoMe), (_For.partner, partner.name), (_For.both, l10n.memoBoth)],
          ),
        _settingsCard(context, l10n),
        if (_ringsFor(l10n) case final rings?)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(rings, style: PnText.meta.copyWith(fontSize: 13, height: 1.4)),
          ),
      ],
    );
  }

  /// Who the reminder will go to; nothing without a reminder.
  String? _ringsFor(AppLocalizations l10n) {
    if (_date == null) return null;
    final partner = widget.partner;
    if (partner == null) return l10n.memoRingsSolo;
    return switch (_for) {
      _For.me => l10n.memoRingsForMe,
      _For.partner => l10n.memoRingsFor(partner.name),
      _For.both || null => l10n.memoRingsForBoth,
    };
  }

  Widget _settingsCard(BuildContext context, AppLocalizations l10n) {
    _Chip chip(String label, bool on, VoidCallback onTap) => _Chip(label: label, selected: on, onTap: onTap);
    final day = _day;
    final picked = _date;
    final reminder = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _Fill(
          children: [
            chip(l10n.memoNone, day == _Day.none, () => setState(() => _date = null)),
            chip(l10n.today, day == _Day.today, () => setState(() => _date = today())),
            chip(l10n.tomorrow, day == _Day.tomorrow, () => setState(() => _date = inDays(1))),
            chip(
              day == _Day.pick && picked != null ? memoDayLabel(context, picked) : l10n.memoPick,
              day == _Day.pick || _calendar,
              () => setState(() => _calendar = !_calendar),
            ),
          ],
        ),
        if (_calendar)
          MonthCalendar(
            value: picked,
            theme: memoTheme,
            onChanged: (d) => setState(() => _date = d),
            onDone: () => setState(() => _calendar = false),
          ),
        if (picked != null)
          _Fill(
            children: [
              for (final h in memoHours) chip(memoHourLabel(context, h), _hour == h, () => setState(() => _hour = h)),
            ],
          ),
      ],
    );
    final repeat = _Fill(
      children: [
        for (final r in MemoRepeat.values)
          chip(memoRepeatLabel(l10n, r), _repeat == r, () => setState(() => _repeat = r)),
      ],
    );
    final when = picked == null
        ? l10n.memoNone
        : l10n.reminderAt(memoDayLabel(context, picked), memoHourLabel(context, _hour));
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PnColors.snow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PnColors.peachLine, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Unfolding(
            icon: PnIcons.bell,
            title: l10n.reminder,
            value: when,
            open: _open == 'reminder',
            onTap: () => setState(() => _open = _open == 'reminder' ? null : 'reminder'),
            child: reminder,
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: PnColors.cream100, borderRadius: BorderRadius.circular(1)),
          ),
          _Unfolding(
            icon: PnIcons.clock,
            title: l10n.memoRepeat,
            value: memoRepeatLabel(l10n, _repeat),
            open: _open == 'repeat',
            onTap: () => setState(() => _open = _open == 'repeat' ? null : 'repeat'),
            child: repeat,
          ),
        ],
      ),
    );
  }
}

/// A row of the settings card, with its value, that unfolds [child] below.
class _Unfolding extends StatelessWidget {
  const _Unfolding({
    required this.icon,
    required this.title,
    required this.value,
    required this.open,
    required this.onTap,
    required this.child,
  });

  final String icon;
  final String title;
  final String value;
  final bool open;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: open,
          child: Pressable(
            onTap: onTap,
            scale: 0.99,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Center(child: PnIcon(icon, color: PnColors.terra, size: 22)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: PnColors.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: PnColors.terraDark),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: open ? -0.25 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const PnIcon(PnIcons.chevronRight, color: PnColors.terraDark, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 14), child: child)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Chips at their own width, packed in rows, each row's leftover width
/// shared equally between its chips (as CSS `flex: 1 1 auto` would). A
/// chip never breaks over two lines.
class _Fill extends StatelessWidget {
  const _Fill({required this.children});

  final List<_Chip> children;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final widths = [for (final chip in children) chip.naturalWidth(context)];
        final rows = <List<int>>[];
        var used = 0.0;
        for (final (i, w) in widths.indexed) {
          if (rows.isEmpty || used + _gap + w > c.maxWidth) {
            rows.add([i]);
            used = w;
          } else {
            rows.last.add(i);
            used += _gap + w;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (r, row) in rows.indexed) ...[
              if (r > 0) const SizedBox(height: _gap),
              Builder(
                builder: (context) {
                  final natural = row.fold<double>(0, (sum, i) => sum + widths[i]) + _gap * (row.length - 1);
                  final share = ((c.maxWidth - natural) / row.length).clamp(0.0, double.infinity);
                  return Row(
                    children: [
                      for (final (k, i) in row.indexed) ...[
                        if (k > 0) const SizedBox(width: _gap),
                        // The last one takes what is left, rounding included.
                        if (k == row.length - 1)
                          Expanded(child: children[i])
                        else
                          SizedBox(width: widths[i] + share, child: children[i]),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A 44 px chip: night when chosen, peach otherwise.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _padding = 10.0;

  static final _style = PnText.pill.copyWith(fontSize: 14);

  /// Its width before any share of the row's leftover.
  double naturalWidth(BuildContext context) {
    final text = TextPainter(
      // With the app's font, as drawn.
      text: TextSpan(text: label, style: DefaultTextStyle.of(context).style.merge(_style)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = text.width + 2 * _padding + 1;
    text.dispose();
    return width < 44 ? 44 : width;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.96,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: _padding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? PnColors.night : PnColors.peach,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: _style.copyWith(color: selected ? PnColors.peach : PnColors.terraDark),
          ),
        ),
      ),
    );
  }
}

/// "Pour qui ?": three 44 px segments on a cream track.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({required this.label, required this.value, required this.onChanged, required this.items});

  final String label;
  final T? value;
  final ValueChanged<T> onChanged;
  final List<(T, String)> items;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: PnColors.cream, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            for (final (i, (v, text)) in items.indexed) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: v == value,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 44,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: v == value ? PnColors.snow : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: v == value
                            ? const [BoxShadow(color: Color(0x24583727), blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PnText.pill.copyWith(fontSize: 14, color: v == value ? PnColors.ink : PnColors.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens [MemoSheet]; null when closed without saving.
Future<MemoTask?> showMemoSheet(
  BuildContext context, {
  MemoTask? initial,
  required String meId,
  required Member? partner,
  required int defaultHour,
}) => showPnSheet<MemoTask>(
  context,
  MemoSheet(initial: initial, meId: meId, partner: partner, defaultHour: defaultHour),
  editing: true,
);
