import 'package:flutter/material.dart';

import '../../../domain/models/activity.dart';
import '../../../domain/models/household.dart';
import '../../../l10n/app_localizations.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'avatar.dart';
import 'buttons.dart';
import 'date_fields.dart';
import 'edited_label.dart';
import 'pn_icon.dart';
import 'sheet.dart';

/// What was picked in an [ItemMenuSheet].
enum ItemMenuAction { toggleShared, invite, togglePin, delete }

/// "⋯" menu of an open list or note: its 3 latest changes, who sees it
/// (or "Invite someone" while alone) and "Delete". Pops the
/// [ItemMenuAction] picked; picking the visibility already set does
/// nothing.
class ItemMenuSheet extends StatefulWidget {
  const ItemMenuSheet({
    super.key,
    required this.title,
    required this.isNote,
    required this.changes,
    required this.meId,
    required this.members,
    required this.shared,
    required this.theme,
    this.creatorId,
    this.pinned,
    this.canShare = true,
    this.canDelete = true,
  });

  final String title;
  final bool isNote;
  final Future<List<Activity>> changes;
  final String meId;
  final List<Member> members;
  final bool shared;
  final ListTheme theme;

  /// Who created it, when known: shown while the household is two.
  final String? creatorId;

  /// Whether a list is on home; null for a note, which has no pin.
  final bool? pinned;

  /// False on a shared note written by the other member.
  final bool canShare;
  final bool canDelete;

  @override
  State<ItemMenuSheet> createState() => _ItemMenuSheetState();
}

class _ItemMenuSheetState extends State<ItemMenuSheet> {
  Member? get _partner {
    for (final m in widget.members) {
      if (m.id != widget.meId) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final partner = _partner;
    const divider = BorderSide(color: PnColors.line);
    Widget row({required Widget icon, required Widget text, required VoidCallback onTap}) => Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(top: divider)),
        child: Row(
          children: [
            SizedBox(width: 20, child: Center(child: icon)),
            const SizedBox(width: 12),
            Expanded(child: text),
          ],
        ),
      ),
    );
    final creator = widget.creatorId == null ? null : _member(widget.creatorId!);
    return PnSheet(
      title: widget.title,
      children: [
        if (partner != null && creator != null)
          Row(
            children: [
              Avatar.of(creator, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  creator.id == widget.meId ? l10n.createdByYou : l10n.createdBy(creator.name),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: PnColors.ink),
                ),
              ),
            ],
          ),
        FutureBuilder(
          future: widget.changes,
          builder: (context, snapshot) {
            final changes = snapshot.data ?? const <Activity>[];
            if (changes.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.latestChanges, style: PnText.label),
                for (final e in changes.take(3)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (partner != null)
                        if (_member(e.actorId) case final m?) ...[Avatar.of(m, size: 24), const SizedBox(width: 10)],
                      Expanded(
                        child: Text(
                          activityText(l10n, e, meId: widget.meId, solo: partner == null, actor: _member(e.actorId)),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1.35,
                            color: PnColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(editedLabel(context, e.at), style: PnText.meta),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (partner == null)
              row(
                icon: const PnIcon(PnIcons.plus, color: PnColors.terraDark, size: 20),
                text: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.inviteSomeone,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: PnColors.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(widget.isNote ? l10n.toShareThisNote : l10n.toShareThisList, style: PnText.meta),
                  ],
                ),
                onTap: () => Navigator.pop(context, ItemMenuAction.invite),
              )
            else
              Container(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                decoration: const BoxDecoration(border: Border(top: divider)),
                child: IgnorePointer(
                  ignoring: !widget.canShare,
                  child: Opacity(
                    opacity: widget.canShare ? 1 : 0.6,
                    child: VisibilityPicker(
                      note: widget.isNote,
                      shared: widget.shared,
                      theme: widget.theme,
                      members: widget.members,
                      partnerName: partner.name,
                      onChanged: (v) {
                        if (v != widget.shared) Navigator.pop(context, ItemMenuAction.toggleShared);
                      },
                    ),
                  ),
                ),
              ),
            // Why the choice above is greyed out, and Delete missing.
            if (partner != null && !widget.canShare && creator != null && creator.id != widget.meId)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(l10n.askAuthor(creator.name), style: PnText.meta),
              ),
            if (widget.pinned case final pinned?)
              row(
                icon: PnIcon(pinned ? PnIcons.pinOff : PnIcons.pin, color: PnColors.terraDark, size: 20),
                text: Text(
                  pinned ? l10n.unpinFromHome : l10n.pinToHome,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: PnColors.ink),
                ),
                onTap: () => Navigator.pop(context, ItemMenuAction.togglePin),
              ),
            if (widget.canDelete)
              row(
                icon: const PnIcon(PnIcons.trash, color: PnColors.danger, size: 18),
                text: Text(
                  widget.isNote ? l10n.deleteNote : l10n.deleteList,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: PnColors.danger),
                ),
                onTap: () => Navigator.pop(context, ItemMenuAction.delete),
              ),
          ],
        ),
      ],
    );
  }

  Member? _member(String id) {
    for (final m in widget.members) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// "You checked “Milk”", "Yoann edited the note", or, while alone,
/// "Checked “Milk”" / "Note edited".
String activityText(AppLocalizations l10n, Activity e, {required String meId, required bool solo, Member? actor}) {
  final verb = e.verb.name;
  final item = e.item;
  if (solo) {
    if (item == null) return e.isNote ? l10n.logSoloNote(verb) : l10n.logSoloList(verb);
    return l10n.logSolo(verb, l10n.quoted(item));
  }
  final what = item == null ? (e.isNote ? l10n.theNoteLower : l10n.theListLower) : l10n.quoted(item);
  if (e.actorId == meId) return l10n.logByYou(verb, what);
  return l10n.logByName(actor?.name ?? '?', verb, what);
}
