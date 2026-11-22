import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/reminder.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/task_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/date_fields.dart';
import '../../core/ui/item_menu.dart';
import '../../core/ui/item_sheets.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/list_hero.dart';
import '../../core/ui/list_sheet.dart';
import '../../core/ui/mascot.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/popover.dart';
import '../../core/ui/sheet.dart';
import '../../core/ui/task_row.dart';
import '../../core/ui/toast.dart';
import '../../invite/widgets/invite_sheet.dart';
import '../view_models/list_viewmodel.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.viewModel, this.fromAllLists = false});

  final ListViewModel viewModel;

  /// Back goes to "All lists" instead of home.
  final bool fromAllLists;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  int _blinks = 0;
  int _hops = 0;
  MascotMood? _egg;
  final _taps = <DateTime>[];
  MascotMood? _lastMood;

  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();
  bool _editingTitle = false;
  final _pickerLink = LayerLink();
  final _pickerAnchor = GlobalKey();
  final _picker = OverlayPortalController();

  ListViewModel get vm => widget.viewModel;

  /// Putting the app away counts as leaving the list.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus && _editingTitle) _saveTitle();
    });
    _lifecycle = AppLifecycleListener(onHide: vm.release);
  }

  @override
  void dispose() {
    vm.release();
    _lifecycle.dispose();
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    await closeKeyboard(context);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.fromAllLists ? Routes.lists : Routes.home);
    }
  }

  /// Tap: blink. Three quick taps: wink and hop.
  void _tapMascot() {
    final now = DateTime.now();
    _taps
      ..removeWhere((t) => now.difference(t).inMilliseconds > 700)
      ..add(now);
    if (_taps.length >= 3) {
      _taps.clear();
      setState(() {
        _egg = MascotMood.wink;
        _hops++;
      });
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() => _egg = null);
      });
    } else {
      setState(() => _blinks++);
    }
  }

  Future<void> _deleteTask(Task task) async {
    final l10n = AppLocalizations.of(context);
    final deleted = await vm.deleteTask(task);
    if (deleted == null || !mounted) return;
    showToast(context, l10n.taskDeleted(task.title), onUndo: () => vm.restoreTask(deleted));
  }

  Future<void> _askShare(TaskList list) async {
    final partner = vm.partner;
    if (partner == null) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showPnSheet<bool>(
      context,
      ShareConfirmSheet(
        itemName: list.name,
        isList: true,
        makePersonal: list.isShared,
        partner: partner,
        members: vm.members,
      ),
    );
    if (ok != true) return;
    await vm.toggleShared();
    if (mounted) showToast(context, list.isShared ? l10n.nowPersonalList : l10n.sharedWith(partner.name));
  }

  // Each setting of the open list is changed on its own.

  void _startTitle() {
    final list = vm.list;
    if (list == null) return;
    setState(() {
      _titleController.text = list.name;
      _editingTitle = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editingTitle) _titleFocus.requestFocus();
    });
  }

  /// Enter or leaving the field saves. An empty name falls back to "List".
  void _saveTitle() {
    final list = vm.list;
    setState(() => _editingTitle = false);
    if (list == null) return;
    final typed = _titleController.text.trim();
    final name = typed.isEmpty ? AppLocalizations.of(context).defaultListName : typed;
    if (name != list.name) vm.update(list.copyWith(name: name));
  }

  /// Opening it closes the keyboard first, which would otherwise hide the
  /// bottom of the picker.
  void _togglePicker() {
    if (!_picker.isShowing) FocusManager.instance.primaryFocus?.unfocus();
    setState(_picker.toggle);
  }

  /// Latest changes, who sees it, delete.
  Future<void> _menu() async {
    final list = vm.list;
    if (list == null) return;
    final action = await showPnSheet<ItemMenuAction>(
      context,
      ItemMenuSheet(
        title: '${list.name}.',
        isNote: false,
        changes: vm.latestChanges(),
        meId: vm.meId,
        members: vm.members,
        shared: list.isShared,
        theme: ListTheme.of(list.color),
        creatorId: list.ownerId,
        pinned: list.pinned,
        // Room on home: the switch pins in place, the menu stays open.
        homeFull: vm.homeFull,
        onSetPinned: vm.setPinned,
      ),
    );
    if (!mounted) return;
    switch (action) {
      case ItemMenuAction.toggleShared:
        await _askShare(vm.list ?? list);
      case ItemMenuAction.invite:
        await showInviteSheet(context);
      case ItemMenuAction.togglePin:
        await _togglePin(vm.list ?? list);
      case ItemMenuAction.delete:
        await _deleteList();
      case null:
        break;
    }
  }

  /// From the menu only when pinning with home full (otherwise the menu's
  /// switch pins in place): all lists, in edit mode, to make room; done
  /// there, back here.
  Future<void> _togglePin(TaskList list) async {
    final l10n = AppLocalizations.of(context);
    if (list.pinned) {
      await vm.setPinned(false);
      if (mounted) showToast(context, l10n.unpinnedFromHome);
    } else if (vm.homeFull) {
      showToast(context, l10n.homeFull);
      await context.push(Routes.editLists(returnTo: list.id));
    } else {
      await vm.setPinned(true);
      if (mounted) showToast(context, l10n.pinnedToHome);
    }
  }

  Future<void> _day() async {
    final list = vm.list;
    if (list == null) return;
    final result = await showPnSheet<(DateTime?,)>(
      context,
      DaySheet(initial: list.day, theme: ListTheme.of(list.color)),
      editing: true,
    );
    final current = vm.list;
    if (result != null && current != null) await vm.update(current.copyWith(day: () => result.$1));
  }

  Future<void> _reminder() async {
    final list = vm.list;
    if (list == null) return;
    final result = await showPnSheet<(Reminder?,)>(
      context,
      ReminderSheet(
        initial: list.reminder,
        defaultTime: vm.defaultTime,
        theme: ListTheme.of(list.color),
        partnerName: list.isShared ? vm.partner?.name : null,
        day: list.day,
      ),
      editing: true,
    );
    final current = vm.list;
    if (result != null && current != null) await vm.update(current.copyWith(reminder: () => result.$1));
  }

  /// Deleted at once; the toast can bring it back.
  Future<void> _deleteList() async {
    final list = vm.list;
    if (list == null) return;
    final l10n = AppLocalizations.of(context);
    final deleted = await vm.deleteList();
    if (deleted == null || !mounted) return;
    showToast(context, l10n.listDeleted(list.name), onUndo: () => vm.restoreList(deleted));
    await _back();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final list = vm.list;
        if (list == null) return const SizedBox.shrink();
        final mood = vm.mood;
        if (_lastMood != null && mood == MascotMood.love && _lastMood != MascotMood.love) _hops++;
        _lastMood = mood;
        // Android back goes where the back link goes (home or all lists).
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: _body(context, list, _egg ?? mood),
        );
      },
    );
  }

  Widget _body(BuildContext context, TaskList list, MascotMood mood) {
    final l10n = AppLocalizations.of(context);
    final theme = ListTheme.of(list.color);
    final open = vm.openTasks;
    final done = vm.doneTasks;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header(context, l10n, list, theme, mood)),
        SliverPadding(
          padding: const EdgeInsets.only(top: 20),
          sliver: SliverReorderableList(
            itemCount: open.length,
            onReorderItem: vm.reorder,
            proxyDecorator: (child, index, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, child) => Transform.scale(
                scale: 1 + 0.035 * Curves.easeOutBack.transform(animation.value),
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PnColors.snow,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Color(0x4D583727), blurRadius: 36, offset: Offset(0, 18), spreadRadius: -14),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
              child: child,
            ),
            itemBuilder: (context, i) {
              final t = open[i];
              // Long-press anywhere on a task to drag it, or drag the dots.
              return ReorderableDelayedDragStartListener(
                key: ValueKey(t.id),
                index: i,
                enabled: open.length > 1,
                child: ContentWidth(
                  child: TaskRow(
                    task: t,
                    author: vm.authorOf(t),
                    background: Colors.transparent,
                    handle: open.length > 1
                        ? ReorderableDragStartListener(
                            index: i,
                            child: Semantics(label: l10n.dragToReorder, child: const Grip()),
                          )
                        : null,
                    onToggle: () => vm.toggle(t),
                    onRename: (title) => vm.rename(t, title),
                    onDelete: () => _deleteTask(t),
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: ContentWidth(
            child: Gap(
              gap: 6,
              children: [
                if ((vm.draft, vm.drafter) case (final draft?, final drafter?))
                  DraftTaskRow(text: draft.text, member: drafter),
                AddTaskRow(
                  key: ValueKey('add-${list.id}'),
                  autofocus: vm.taskCount == 0,
                  placeholder: vm.taskCount == 0 ? l10n.firstItemPlaceholder : l10n.addItem,
                  onAdd: vm.addTask,
                  onTyping: vm.typing,
                ),
                if (done.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 4),
                    child: Row(
                      children: [
                        Text(l10n.doneSection, style: PnText.label),
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(10)),
                          child: Text('${done.length}', style: PnText.tiny.copyWith(color: PnColors.terraDark)),
                        ),
                      ],
                    ),
                  ),
                for (final t in done)
                  TaskRow(
                    key: ValueKey(t.id),
                    task: t,
                    author: vm.authorOf(t),
                    onToggle: () => vm.toggle(t),
                    onRename: (title) => vm.rename(t, title),
                    onDelete: () => _deleteTask(t),
                  ),
                if (vm.taskCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(l10n.listHint, style: PnText.meta.copyWith(height: 1.4)),
                  ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n, TaskList list, ListTheme theme, MascotMood mood) {
    const chipBg = PnColors.translucentSnow;
    return Stack(
      children: [
        Positioned.fill(
          child: ListBackdrop(
            listId: list.id,
            color: theme.bg,
            radius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 4, bottom: 24),
          child: ContentWidth(
            child: Gap(
              gap: 14,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: BackLink(
                          label: widget.fromAllLists ? l10n.allLists : l10n.home,
                          onPressed: _back,
                          color: theme.fg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MenuDotsButton(label: l10n.listOptions, color: theme.fg, background: chipBg, onTap: _menu),
                  ],
                ),
                // Icon tile (opens the color + icon popover below this row),
                // the name (tap to rename), the mascot.
                LayoutBuilder(
                  builder: (context, c) => CompositedTransformTarget(
                    key: _pickerAnchor,
                    link: _pickerLink,
                    child: OverlayPortal(
                      controller: _picker,
                      overlayChildBuilder: (context) => _iconPopover(list, c.maxWidth + 8),
                      child: Row(
                        children: [
                          Semantics(
                            button: true,
                            label: l10n.changeIconAndColor,
                            child: Pressable(
                              onTap: _togglePicker,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: chipBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _picker.isShowing ? theme.fg : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Center(child: PnIcon.list(list.icon, color: theme.fg, size: 24)),
                                    Positioned(
                                      right: -5,
                                      bottom: -5,
                                      child: PickerBadge(color: theme.fg, open: _picker.isShowing),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _title(l10n, list, theme)),
                          const SizedBox(width: 12),
                          Semantics(
                            button: true,
                            label: l10n.mascot,
                            child: GestureDetector(
                              onTap: _tapMascot,
                              child: Mascot(
                                mood: mood,
                                color: theme.fg,
                                highlight: theme.bg,
                                height: 30,
                                blinks: _blinks,
                                hops: _hops,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Always shown; each pill opens its own sheet.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Semantics(
                      button: true,
                      label: l10n.deadline,
                      child: Pressable(
                        onTap: _day,
                        child: InfoPill(
                          text: list.day == null ? l10n.noDeadline : dateLabel(context, effectiveDay(list.day!)),
                          icon: PnIcons.calendar,
                          color: theme.fg,
                          background: PnColors.snow.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: l10n.reminder,
                      child: Pressable(
                        onTap: _reminder,
                        child: InfoPill(
                          text: list.reminder == null ? l10n.noReminder : reminderLabel(context, list.reminder!),
                          icon: PnIcons.bell,
                          color: theme.fg,
                          background: PnColors.snow.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The name, renamed in place: Enter or leaving the field saves.
  Widget _title(AppLocalizations l10n, TaskList list, ListTheme theme) {
    final style = PnText.screenTitle.copyWith(color: theme.fg);
    if (_editingTitle) {
      return TextField(
        controller: _titleController,
        focusNode: _titleFocus,
        style: style,
        maxLines: null,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: theme.fg,
        onSubmitted: (_) => _titleFocus.unfocus(),
        decoration: const InputDecoration.collapsed(hintText: null),
      );
    }
    return Semantics(
      button: true,
      label: l10n.renameList,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startTitle,
        child: ListTitle(listId: list.id, text: '${list.name}.', style: style),
      ),
    );
  }

  /// Color + icon picker under the title row. Each pick saves at once; a tap
  /// anywhere else closes it.
  Widget _iconPopover(TaskList list, double width) {
    return AnchoredPopover(
      link: _pickerLink,
      anchorKey: _pickerAnchor,
      onDismiss: _togglePicker,
      dx: -4,
      gap: 10,
      child: IconColorPicker(
        width: width,
        color: list.color,
        icon: list.icon,
        onColor: (c) => vm.update((vm.list ?? list).copyWith(color: c)),
        onIcon: (i) => vm.update((vm.list ?? list).copyWith(icon: i)),
      ),
    );
  }
}
