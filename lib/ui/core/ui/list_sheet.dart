import 'package:flutter/material.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/task_list.dart';
import '../../../l10n/app_localizations.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'buttons.dart';
import 'controls.dart';
import 'date_fields.dart';
import 'pn_icon.dart';
import 'sheet.dart';

/// New list: name, color + icon and who sees it. It starts with no
/// deadline and no reminder (set later from the list itself). Pops the
/// draft [TaskList].
class ListSheet extends StatefulWidget {
  const ListSheet({super.key, required this.members, required this.partnerName, this.defaultColor = ListColor.mustard});

  /// Color of a new list.
  final ListColor defaultColor;
  final List<Member> members;

  /// Null when alone in the household: the visibility choice is hidden.
  final String? partnerName;

  @override
  State<ListSheet> createState() => _ListSheetState();
}

class _ListSheetState extends State<ListSheet> {
  final _name = TextEditingController();
  late ListColor _color = widget.defaultColor;
  ListIcon _icon = ListIcon.heart;

  /// New lists are shared by default (ignored while alone in the household).
  bool _shared = true;
  bool _picking = false;

  /// Opening it closes the keyboard first, which would otherwise hide the
  /// bottom of the picker.
  void _togglePicker() {
    if (!_picking) FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _picking = !_picking);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      TaskList(id: '', name: name, color: _color, icon: _icon, isShared: widget.partnerName != null && _shared),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ListTheme.of(_color);
    return PnSheet(
      title: l10n.newListTitle,
      footer: ValueListenableBuilder(
        valueListenable: _name,
        builder: (context, value, _) =>
            PnButton(label: l10n.createList, onPressed: value.text.trim().isEmpty ? null : _submit),
      ),
      children: [
        // The picker opens under the name, inside the sheet, which grows to
        // fit it. A tap anywhere else closes it.
        TapRegion(
          onTapOutside: _picking ? (_) => setState(() => _picking = false) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: l10n.changeIconAndColor,
                    child: Pressable(
                      onTap: _togglePicker,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: _picking ? Border.all(color: theme.fg, width: 2) : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(child: PnIcon.list(_icon, color: theme.fg, size: 24)),
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: PickerBadge(color: theme.fg, open: _picking),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PnTextField(
                      controller: _name,
                      hint: l10n.listName,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
              if (_picking) ...[
                const SizedBox(height: 12),
                IconColorPicker(
                  color: _color,
                  icon: _icon,
                  onColor: (c) => setState(() => _color = c),
                  onIcon: (i) => setState(() => _icon = i),
                ),
              ],
            ],
          ),
        ),
        if (widget.partnerName != null)
          VisibilityPicker(
            shared: _shared,
            onChanged: (v) => setState(() => _shared = v),
            theme: theme,
            members: widget.members,
            partnerName: widget.partnerName!,
          ),
      ],
    );
  }
}

/// Color + icon picker under an icon tile (new list sheet, and the header
/// of an open list). Fills the width it is given without [width].
class IconColorPicker extends StatelessWidget {
  const IconColorPicker({
    super.key,
    this.width,
    required this.color,
    required this.icon,
    required this.onColor,
    required this.onIcon,
  });

  final double? width;
  final ListColor color;
  final ListIcon icon;
  final ValueChanged<ListColor> onColor;
  final ValueChanged<ListIcon> onIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ListTheme.of(color);
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PnColors.snow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x2E583727), blurRadius: 40, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.color, style: PnText.label),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in ListColor.values) ...[
                Semantics(
                  button: true,
                  selected: c == color,
                  label: c.name,
                  child: GestureDetector(
                    onTap: () => onColor(c),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ListTheme.of(c).bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == color ? ListTheme.of(c).fg : PnColors.line,
                          width: c == color ? 3 : 1,
                        ),
                      ),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: ListTheme.of(c).fg, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                if (c != ListColor.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(l10n.icon, style: PnText.label),
          const SizedBox(height: 8),
          // 6 icons per row, spread over the width.
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.2,
            children: [
              for (final i in ListIcon.values)
                GestureDetector(
                  onTap: () => onIcon(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == icon ? theme.bg : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PnIcon.list(i, color: i == icon ? theme.fg : PnColors.muted, size: 22),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Result of [NoteSheet].
typedef NoteDraft = ({String title, bool shared});

/// New note: optional title and who sees it ("The household" by default).
class NoteSheet extends StatefulWidget {
  const NoteSheet({super.key, required this.members, required this.partnerName});

  final List<Member> members;

  /// Null when alone in the household: the visibility choice is hidden.
  final String? partnerName;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  final _title = TextEditingController();

  /// New notes are shared by default (ignored while alone in the household).
  bool _shared = true;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() =>
      Navigator.pop<NoteDraft>(context, (title: _title.text.trim(), shared: widget.partnerName != null && _shared));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PnSheet(
      title: l10n.newNoteTitle,
      footer: PnButton(label: l10n.createNote, onPressed: _submit),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(16)),
              child: const PnIcon(PnIcons.document, color: PnColors.terraDark, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PnTextField(
                controller: _title,
                hint: l10n.titleOptional,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
        if (widget.partnerName != null)
          VisibilityPicker(
            note: true,
            shared: _shared,
            onChanged: (v) => setState(() => _shared = v),
            theme: ListTheme.app,
            members: widget.members,
            partnerName: widget.partnerName!,
          ),
      ],
    );
  }
}

/// Confirms sharing an item, or making it personal again. Pops `true`.
class ShareConfirmSheet extends StatelessWidget {
  const ShareConfirmSheet({
    super.key,
    required this.itemName,
    required this.isList,
    required this.makePersonal,
    required this.partner,
    required this.members,
  });

  final String itemName;
  final bool isList;
  final bool makePersonal;
  final Member partner;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PnSheet(
      title: makePersonal ? l10n.makePersonalQuestion : (isList ? l10n.shareListQuestion : l10n.shareNoteQuestion),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PnButton(label: makePersonal ? l10n.makePersonal : l10n.share, onPressed: () => Navigator.pop(context, true)),
          const SizedBox(height: 6),
          PnButton(label: l10n.cancel, kind: PnButtonKind.tertiary, onPressed: () => Navigator.pop(context, false)),
        ],
      ),
      children: [
        Row(
          children: [
            if (makePersonal)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: PnColors.peach, shape: BoxShape.circle),
                child: const PnIcon(PnIcons.lock, color: PnColors.terraDark, size: 16),
              )
            else
              _Pair(members: members),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                makePersonal
                    ? l10n.partnerWontSee(partner.name, itemName)
                    : l10n.partnerWillSee(partner.name, itemName),
                style: const TextStyle(fontSize: 15, height: 1.4, color: PnColors.ink),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.members});

  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, m) in members.indexed)
          Transform.translate(
            offset: Offset(-6.0 * i, 0),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(m.color),
                shape: BoxShape.circle,
                border: Border.all(color: PnColors.snow, width: 2),
              ),
              child: Text(
                m.initial,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: PnColors.snow),
              ),
            ),
          ),
      ],
    );
  }
}
