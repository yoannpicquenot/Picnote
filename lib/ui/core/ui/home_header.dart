import 'package:flutter/material.dart';

import '../../../domain/models/household.dart';
import '../../../l10n/app_localizations.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import '../view_models/who_is_here.dart';
import 'avatar.dart';
import 'buttons.dart';
import 'edited_label.dart';
import 'mascot.dart';
import 'pn_icon.dart';
import 'popover.dart';

/// Daytime is 7:00–20:00: the watermark is awake and the greeting says "day".
bool isDaytime([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  return h >= 7 && h < 20;
}

/// Big faint mascot floating behind the home and notes tabs. Winks when the
/// wordmark is tapped.
class Watermark extends StatefulWidget {
  const Watermark({super.key, required this.winking});

  final bool winking;

  @override
  State<Watermark> createState() => _WatermarkState();
}

class _WatermarkState extends State<Watermark> with SingleTickerProviderStateMixin {
  late final _float = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect reduced motion (and let widget tests settle).
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = isDaytime();
    final mood = widget.winking ? MascotMood.wink : (day ? MascotMood.happy : MascotMood.sleepy);
    return IgnorePointer(
      child: Opacity(
        opacity: 0.08,
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, child) {
            final t = _float.value;
            final y = -4 * (1 - (2 * t - 1) * (2 * t - 1));
            return Transform.translate(offset: Offset(0, y), child: child);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Face(mood, key: ValueKey(mood), height: day ? 170 : 140),
          ),
        ),
      ),
    );
  }
}

/// "PICNOTE." wordmark, offline badge and the household's avatars. The
/// avatars are a single button opening the "who's here" panel (with a
/// dashed "+" while alone).
class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    required this.whoIsHere,
    required this.onWordmark,
    required this.onInvite,
    required this.onSettings,
    this.offline = false,
  });

  final WhoIsHere whoIsHere;
  final VoidCallback onWordmark;
  final VoidCallback onInvite;
  final VoidCallback onSettings;
  final bool offline;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final _link = LayerLink();
  final _anchor = GlobalKey();
  final _panel = OverlayPortalController();

  void _toggle() => setState(_panel.toggle);

  void _close(VoidCallback then) {
    setState(_panel.hide);
    then();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final who = widget.whoIsHere;
    final members = who.members;
    return LayoutBuilder(
      builder: (context, c) => CompositedTransformTarget(
        key: _anchor,
        link: _link,
        child: OverlayPortal(
          controller: _panel,
          overlayChildBuilder: (context) => AnchoredPopover(
            link: _link,
            anchorKey: _anchor,
            onDismiss: _toggle,
            gap: 10,
            child: SizedBox(
              width: c.maxWidth,
              child: _WhoIsHerePanel(
                whoIsHere: who,
                onInvite: () => _close(widget.onInvite),
                onSettings: () => _close(widget.onSettings),
              ),
            ),
          ),
          child: Row(
            children: [
              Pressable(
                onTap: widget.onWordmark,
                child: Text(l10n.appTitle, style: PnText.wordmark),
              ),
              if (widget.offline) ...[const SizedBox(width: 8), _OfflineBadge(label: l10n.offline)],
              const Spacer(),
              // One button for the whole group, a little wider than the
              // avatars so the open state shows a peach backdrop.
              Transform.translate(
                offset: const Offset(4, 0),
                child: Pressable(
                  onTap: _toggle,
                  semanticLabel: l10n.householdAndSettings,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _panel.isShowing ? PnColors.peach : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: _AvatarGroup(whoIsHere: who, members: members),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlapping avatars, the others faded while away, and a dashed "+"
/// while alone.
class _AvatarGroup extends StatelessWidget {
  const _AvatarGroup({required this.whoIsHere, required this.members});

  final WhoIsHere whoIsHere;
  final List<Member> members;

  static const _size = 32.0;

  @override
  Widget build(BuildContext context) {
    final invite = members.length < Household.maxMembers;
    final count = members.length + (invite ? 1 : 0);
    const step = _size - 8;
    return SizedBox(
      width: _size + step * (count - 1),
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, m) in members.indexed)
            Positioned(
              left: step * i,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: PnColors.cream, spreadRadius: 3)],
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: whoIsHere.isHere(m) ? 1 : 0.4,
                  child: Avatar.of(m, size: _size),
                ),
              ),
            ),
          if (invite)
            Positioned(
              left: step * members.length + 2,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: PnColors.cream, spreadRadius: 3)],
                ),
                child: const DashedPlus(size: _size, background: PnColors.cream),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
      decoration: BoxDecoration(color: PnColors.terraDark, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: PnColors.peach, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: PnText.tiny.copyWith(color: PnColors.snow)),
        ],
      ),
    );
  }
}

/// Each member with their latest change, then "Invite someone" (while
/// alone) and "Settings".
class _WhoIsHerePanel extends StatefulWidget {
  const _WhoIsHerePanel({required this.whoIsHere, required this.onInvite, required this.onSettings});

  final WhoIsHere whoIsHere;
  final VoidCallback onInvite;
  final VoidCallback onSettings;

  @override
  State<_WhoIsHerePanel> createState() => _WhoIsHerePanelState();
}

class _WhoIsHerePanelState extends State<_WhoIsHerePanel> {
  late final _latest = widget.whoIsHere.latest();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final who = widget.whoIsHere;
    final members = who.members;
    Widget link(Widget leading, String label, VoidCallback onTap) => Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: PnText.pill.copyWith(fontSize: 14, color: PnColors.terraDark)),
            ),
            const PnIcon(PnIcons.chevronRight, color: PnColors.terraDark, size: 16),
          ],
        ),
      ),
    );
    return Semantics(
      label: l10n.whosHere,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: PnColors.snow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x2E583727), blurRadius: 40, offset: Offset(0, 8))],
        ),
        child: FutureBuilder(
          future: _latest,
          builder: (context, snapshot) {
            final latest = snapshot.data ?? const <String, MemberActivity>{};
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in members)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(opacity: who.isHere(m) ? 1 : 0.4, child: Avatar.of(m, size: 30)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.id == who.meId ? l10n.memberYou(m.name) : m.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: PnColors.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(_line(context, l10n, m, latest[m.id]), style: PnText.meta.copyWith(height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: PnColors.line,
                ),
                if (members.length < Household.maxMembers)
                  link(
                    const DashedPlus(size: 18, background: PnColors.snow, color: PnColors.terraDark, strokeWidth: 1.5),
                    l10n.inviteSomeone,
                    widget.onInvite,
                  ),
                link(const PnIcon(PnIcons.user, color: PnColors.terraDark, size: 18), l10n.settings, widget.onSettings),
              ],
            );
          },
        ),
      ),
    );
  }

  /// "You edited “Groceries”, 5 h ago", "Edited a note, 45 min ago".
  String _line(BuildContext context, AppLocalizations l10n, Member m, MemberActivity? latest) {
    if (latest == null) return l10n.nothingChangedYet;
    final a = latest.activity;
    final name = latest.itemName;
    final what = name == null
        ? (a.isNote ? l10n.aNoteLower : l10n.aListLower)
        : l10n.quoted(name.isEmpty ? l10n.untitled : name);
    final ago = editedLabel(context, a.at);
    return m.id == widget.whoIsHere.meId ? l10n.youEditedAgo(what, ago) : l10n.theyEditedAgo(what, ago);
  }
}
