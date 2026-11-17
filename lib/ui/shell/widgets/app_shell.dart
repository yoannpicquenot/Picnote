import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/task_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../core/themes/colors.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/list_sheet.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/sheet.dart';
import '../../core/ui/toast.dart';
import '../view_models/shell_viewmodel.dart';
import 'tab_pager.dart';

/// "New list" sheet, then opens the created list.
Future<void> startNewList(BuildContext context, ShellViewModel viewModel) async {
  final draft = await showPnSheet<TaskList>(
    context,
    ListSheet(members: viewModel.members, partnerName: viewModel.partner?.name, defaultColor: viewModel.nextColor),
    editing: true,
  );
  if (draft == null) return;
  final id = await viewModel.createList(draft);
  // Pushed: going back pops it, and its new card on home shrinks back.
  if (id != null && context.mounted) context.push(Routes.list(id));
}

/// "New note" sheet, then opens the created note.
Future<void> startNewNote(BuildContext context, ShellViewModel viewModel) async {
  final draft = await showPnSheet<NoteDraft>(
    context,
    NoteSheet(members: viewModel.members, partnerName: viewModel.partner?.name),
    editing: true,
  );
  if (draft == null) return;
  final id = await viewModel.createNote(title: draft.title, shared: draft.shared);
  if (id != null && context.mounted) context.go(Routes.note(id));
}

/// Lists / Notes tabs around a raised "+" in a floating bar. The "+" opens
/// a menu to create a list or a note. The bar slides away inside a list or
/// a note, while a sheet is open and while the keyboard is up.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.viewModel, required this.location, required this.child});

  final ShellViewModel viewModel;
  final String location;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _ease = Cubic(0.2, 0.8, 0.3, 1);

  bool _addOpen = false;
  StreamSubscription<TaskList>? _completed;
  StreamSubscription<Creation>? _partnerCreated;
  bool _barHidden = false;
  bool _scrolled = false;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _completed = widget.viewModel.completedPinned.listen(_offerUnpin);
    _partnerCreated = widget.viewModel.partnerCreated.listen(_tellCreated);
    _lifecycle = AppLifecycleListener(onResume: () => widget.viewModel.archiveStaleTasks());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _completed?.cancel();
    _partnerCreated?.cancel();
    super.dispose();
  }

  /// A pinned list is done: offer to free its place on home. Doing
  /// nothing keeps it pinned.
  void _offerUnpin(TaskList list) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showToast(
      context,
      l10n.listDoneUnpin(list.name),
      action: l10n.unpin,
      onUndo: () => widget.viewModel.unpin(list),
      aboveBar: !_barHidden,
    );
  }

  /// The housemate created or changed a list or a note: say so, with a way
  /// to open it, unless it is open already.
  void _tellCreated(Creation created) {
    if (!mounted) return;
    final route = created.isNote ? Routes.note(created.id) : Routes.list(created.id);
    if (created.edited && _location == route) return;
    final l10n = AppLocalizations.of(context);
    final name = created.name.trim().isEmpty ? l10n.untitled : created.name;
    final who = created.author.name;
    showToast(
      context,
      switch ((created.isNote, created.edited)) {
        (true, false) => l10n.partnerCreatedNote(who, name),
        (false, false) => l10n.partnerCreatedList(who, name),
        (true, true) => l10n.partnerEditedNote(who, name),
        (false, true) => l10n.partnerEditedList(who, name),
      },
      from: created.author,
      action: l10n.see,
      onUndo: () => context.go(route),
      aboveBar: !_barHidden,
    );
  }

  String get _location => widget.location;

  /// A list or a note is open.
  bool get _inItem => (_location.startsWith('${Routes.lists}/') || _location.startsWith('${Routes.notes}/'));

  /// Settings select no tab; all lists belong to Lists.
  int get _tab {
    if (_location.startsWith(Routes.settings)) return -1;
    return _location.startsWith(Routes.notes) ? 1 : 0;
  }

  void _setAdd(bool open) {
    if (open != _addOpen) setState(() => _addOpen = open);
  }

  void _pick(bool note) {
    _setAdd(false);
    note ? startNewNote(context, widget.viewModel) : startNewList(context, widget.viewModel);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _addOpen = false;
      // A new page starts at the top.
      _scrolled = false;
    }
  }

  /// The page's own vertical scroll (inside the Lists / Notes pager, one
  /// level down), not a field inside it. A swipe between the two tabs
  /// closes the "+" menu.
  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.horizontal && n is ScrollStartNotification) _setAdd(false);
    if (n.depth <= 1 && n.metrics.axis == Axis.vertical) {
      final scrolled = n.metrics.pixels > 4;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ValueListenableBuilder(
      valueListenable: openSheets,
      builder: (context, sheets, _) {
        final hidden = _inItem || sheets > 0 || MediaQuery.viewInsetsOf(context).bottom > 0;
        _barHidden = hidden;
        return PopScope(
          // Android back closes the "+" menu first, then goes back to home,
          // and stops there: it never leaves the app.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_addOpen) {
              _setAdd(false);
            } else if (_location != Routes.home) {
              context.go(Routes.home);
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: BottomBarVisibility(visible: !hidden, child: widget.child),
                  ),
                ),
                // Content scrolled up fades out under the status bar.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: MediaQuery.paddingOf(context).top + 28,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _scrolled ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, 0.55, 1],
                            colors: [PnColors.cream, PnColors.cream, PnColors.cream.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120 + bottomInset,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: hidden ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, 0.58],
                            colors: [PnColors.cream.withValues(alpha: 0), PnColors.cream],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_addOpen && !hidden)
                  Positioned.fill(
                    child: _AddMenu(
                      bottom: 108 + bottomInset,
                      onClose: () => _setAdd(false),
                      items: [
                        (PnIcons.list, l10n.newList, () => _pick(false)),
                        (PnIcons.document, l10n.newNote, () => _pick(true)),
                      ],
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: _ease,
                  left: 0,
                  right: 0,
                  bottom: hidden ? -(120 + bottomInset) : 12 + bottomInset,
                  child: IgnorePointer(
                    ignoring: hidden,
                    child: AnimatedOpacity(
                      opacity: hidden ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 484),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ValueListenableBuilder(
                              valueListenable: tabsPosition,
                              builder: (context, position, _) => _BottomBar(
                                tab: _tab,
                                // On Lists or Notes, the tabs follow the pager as
                                // it is swiped, not just once it has settled.
                                position: _location == Routes.home || _location == Routes.notes ? position : null,
                                tabs: [(PnIcons.list, l10n.tabLists), (PnIcons.document, l10n.tabNotes)],
                                onTab: (i) {
                                  _setAdd(false);
                                  context.go(i == 0 ? Routes.home : Routes.notes);
                                },
                                addOpen: _addOpen,
                                onAdd: () => _setAdd(!_addOpen),
                                addLabel: l10n.add,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.tab,
    this.position,
    required this.tabs,
    required this.onTab,
    required this.addOpen,
    required this.onAdd,
    required this.addLabel,
  });

  /// -1 when no tab is selected (settings).
  final int tab;

  /// The pager's position between the two tabs, when it shows: each tab is
  /// then as selected as the pager is close to its page.
  final double? position;
  final List<(String, String)> tabs;
  final ValueChanged<int> onTab;
  final bool addOpen;
  final VoidCallback onAdd;
  final String addLabel;

  static const _height = 68.0;

  /// How far the "+" rises above the bar.
  static const _rise = 15.0;

  @override
  Widget build(BuildContext context) {
    Widget tabButton(int i) {
      final (icon, label) = tabs[i];
      final p = position;
      final target = p == null ? (tab == i ? 1.0 : 0.0) : (1 - (p - i).abs()).clamp(0.0, 1.0);
      return Expanded(
        child: Semantics(
          selected: target > 0.5,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTab(i),
            // Follows the pager as is; eases in when it changes otherwise
            // (to or from settings).
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: target),
              duration: p == null ? const Duration(milliseconds: 200) : Duration.zero,
              builder: (context, on, _) {
                final color = Color.lerp(PnColors.muted, PnColors.terraDark, on)!;
                return SizedBox(
                  height: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PnIcon(icon, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                          fontWeight: on > 0.5 ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Opacity(
                        opacity: on,
                        child: Transform.scale(
                          scale: on,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(color: PnColors.terraDark, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Taller than the bar so the raised "+" can be tapped above it.
    return SizedBox(
      height: _height + _rise,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _height,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: PnColors.snow,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: PnColors.shadow, blurRadius: 40, offset: Offset(0, 8))],
              ),
              child: Row(children: [tabButton(0), const SizedBox(width: 80), tabButton(1)]),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Tooltip(
                message: addLabel,
                child: Semantics(
                  expanded: addOpen,
                  child: Pressable(
                    onTap: onAdd,
                    scale: 0.94,
                    semanticLabel: addLabel,
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: PnColors.night,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Color(0x521C120D), blurRadius: 12, offset: Offset(3, 4)),
                          BoxShadow(color: PnColors.snow, spreadRadius: 5),
                        ],
                      ),
                      child: AnimatedRotation(
                        turns: addOpen ? 0.125 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: _AppShellState._ease,
                        child: const PnIcon(PnIcons.plus, color: PnColors.peach, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "New list" / "New note", over a light scrim above the bar. A tap on
/// the scrim closes it.
class _AddMenu extends StatelessWidget {
  const _AddMenu({required this.bottom, required this.onClose, required this.items});

  final double bottom;
  final VoidCallback onClose;
  final List<(String, String, VoidCallback)> items;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, t, menu) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: ColoredBox(color: Color.fromRGBO(28, 18, 13, 0.25 * t)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 484),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Opacity(
                    opacity: t,
                    child: Transform.scale(scale: 0.94 + 0.06 * t, alignment: Alignment.bottomCenter, child: menu),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: PnColors.snow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x2E583727), blurRadius: 40, offset: Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (icon, label, onTap) in items)
              Pressable(
                onTap: onTap,
                scale: 0.98,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      PnIcon(icon, color: PnColors.terraDark, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: PnColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
