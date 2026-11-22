import 'package:flutter/material.dart';

import '../../../domain/models/activity.dart';
import '../../../domain/models/household.dart';
import '../../../l10n/app_localizations.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'avatar.dart';
import 'controls.dart';
import 'edited_label.dart';
import 'pn_icon.dart';
import 'settings_rows.dart';
import 'sheet.dart';

/// What was picked in an [ItemMenuSheet].
enum ItemMenuAction { toggleShared, invite, togglePin, delete }

/// "⋯" menu of an open list or note, in the language of the settings: a
/// card of actions (pinned to home, shared, or "Invite someone" while
/// alone, delete), then its 3 latest changes and who created it. Pops the
/// [ItemMenuAction] picked.
///
/// What only its creator may change (sharing, deleting a note the other
/// wrote) stays visible, greyed, with the reason.
///
/// The pin switch works in place, through [onSetPinned], while home has
/// room; pinning with home full pops [ItemMenuAction.togglePin] instead, to
/// make room first.
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
    this.homeFull = false,
    this.onSetPinned,
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

  /// Home already shows [maxPinnedLists] lists: pinning needs room first.
  final bool homeFull;

  /// Pins or unpins the list without leaving the menu.
  final Future<void> Function(bool pinned)? onSetPinned;

  /// False on a shared note written by the other member.
  final bool canShare;
  final bool canDelete;

  @override
  State<ItemMenuSheet> createState() => _ItemMenuSheetState();
}

class _ItemMenuSheetState extends State<ItemMenuSheet> {
  /// The switch, ahead of the list's own state while it saves.
  late bool? _pinned = widget.pinned;

  Future<void> _togglePin() async {
    final pinned = _pinned;
    final onSetPinned = widget.onSetPinned;
    if (pinned == null) return;
    if ((!pinned && widget.homeFull) || onSetPinned == null) {
      Navigator.pop(context, ItemMenuAction.togglePin);
      return;
    }
    setState(() => _pinned = !pinned);
    await onSetPinned(!pinned);
  }

  bool get isNote => widget.isNote;
  String get meId => widget.meId;
  List<Member> get members => widget.members;
  bool get shared => widget.shared;
  String? get creatorId => widget.creatorId;
  bool get canShare => widget.canShare;
  bool get canDelete => widget.canDelete;
  Future<List<Activity>> get changes => widget.changes;

  Member? get _partner {
    for (final m in members) {
      if (m.id != meId) return m;
    }
    return null;
  }

  Member? _member(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final partner = _partner;
    final creator = creatorId == null ? null : _member(creatorId!);
    // Created by the other member: what only they may do is greyed, with why.
    final reservedTo = creator != null && creator.id != meId ? creator : null;
    void pick(ItemMenuAction a) => Navigator.pop(context, a);
    final deleteTitle = isNote ? l10n.deleteNote : l10n.deleteList;
    return PnSheet(
      title: widget.title,
      children: [
        SettingsCard(
          children: [
            if (_pinned case final pinned?)
              SettingsRow(
                icon: PnIcons.pin,
                title: l10n.pinnedOnHome,
                subtitle: pinned ? l10n.pinnedToHomeSub : l10n.onlyInAllLists,
                trailing: PnToggle(on: pinned),
                onTap: _togglePin,
              ),
            if (partner == null)
              SettingsRow(
                icon: PnIcons.plus,
                title: l10n.inviteSomeone,
                subtitle: isNote ? l10n.toShareThisNote : l10n.toShareThisList,
                onTap: () => pick(ItemMenuAction.invite),
              )
            else
              SettingsRow(
                icon: PnIcons.users,
                title: isNote ? l10n.sharedNote : l10n.sharedList,
                subtitle: !canShare && reservedTo != null
                    ? l10n.reservedToCreatorShare(reservedTo.name)
                    : shared
                    ? l10n.partnerSeesAndEdits(partner.name)
                    : l10n.onlyYouSeeIt,
                trailing: PnToggle(on: shared),
                dimmed: !canShare,
                onTap: () => pick(ItemMenuAction.toggleShared),
              ),
            if (canDelete)
              SettingsRow(
                icon: PnIcons.trash,
                title: deleteTitle,
                danger: true,
                onTap: () => pick(ItemMenuAction.delete),
              )
            else if (partner != null && reservedTo != null)
              SettingsRow(
                icon: PnIcons.trash,
                title: deleteTitle,
                subtitle: l10n.reservedToCreatorDelete(reservedTo.name),
                danger: true,
                dimmed: true,
              ),
          ],
        ),
        FutureBuilder(
          future: changes,
          builder: (context, snapshot) {
            final latest = snapshot.data ?? const <Activity>[];
            if (latest.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.latestChanges, style: PnText.label),
                  for (final e in latest.take(3)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (partner != null)
                          if (_member(e.actorId) case final m?) ...[Avatar.of(m, size: 20), const SizedBox(width: 10)],
                        Expanded(
                          child: Text(
                            activityText(l10n, e, meId: meId, solo: partner == null, actor: _member(e.actorId)),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
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
                  if (partner != null && creator != null) ...[
                    const SizedBox(height: 14),
                    const SoftDivider(),
                    const SizedBox(height: 10),
                    Text(creator.id == meId ? l10n.createdByYou : l10n.createdBy(creator.name), style: PnText.meta),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
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
