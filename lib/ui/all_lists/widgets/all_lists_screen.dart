import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/task_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/date_fields.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/rise_in.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/task_row.dart';
import '../../core/ui/toast.dart';
import '../view_models/all_lists_viewmodel.dart';

class AllListsScreen extends StatelessWidget {
  const AllListsScreen({super.key, required this.viewModel, this.returnTo});

  final AllListsViewModel viewModel;

  /// Opened from a list to make room on home: "OK" goes back to it.
  final String? returnTo;

  void _toggleEditing(BuildContext context) {
    final back = returnTo;
    if (viewModel.editing && back != null) {
      context.canPop() ? context.pop() : context.go(Routes.list(back));
      return;
    }
    viewModel.toggleEditing();
  }

  Future<void> _delete(BuildContext context, TaskList list) async {
    final l10n = AppLocalizations.of(context);
    final deleted = await viewModel.delete(list);
    if (deleted == null || !context.mounted) return;
    showToast(context, l10n.listDeleted(list.name), onUndo: () => viewModel.restore(deleted));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        final pinned = vm.pinned;
        final others = vm.others;
        Widget row(TaskList list, int i, {Widget? handle}) => RiseIn.staggered(
          key: ValueKey(list.id),
          index: i,
          child: _Row(
            list: list,
            editing: vm.editing,
            // Can't pin more once home is full.
            canPin: list.pinned || !vm.homeFull,
            subtitle: _subtitle(context, l10n, vm, list),
            showPerso: !vm.isSolo,
            onOpen: () => context.push('${Routes.list(list.id)}?from=all'),
            onPin: () => vm.setPinned(list, !list.pinned),
            onDelete: () => _delete(context, list),
            handle: handle,
          ),
        );
        return SingleChildScrollView(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 4, bottom: bottomBarClearance),
          child: ContentWidth(
            child: Gap(
              gap: 16,
              children: [
                Row(
                  children: [
                    BackLink(
                      label: l10n.home,
                      onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
                    ),
                    const Spacer(),
                    Pressable(
                      onTap: () => _toggleEditing(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: vm.editing ? PnColors.peach : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          vm.editing ? l10n.ok : l10n.edit,
                          style: PnText.pill.copyWith(color: PnColors.terraDark),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(child: Text(l10n.allListsTitle, style: PnText.screenTitle)),
                    Text(
                      '${vm.lists.length}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: PnColors.muted),
                    ),
                  ],
                ),
                if (vm.lists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.noListsYet, style: PnText.sub),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHead(title: l10n.pinnedTitle, count: '${pinned.length}/$maxPinnedLists'),
                      // While editing, the pinned lists can be rearranged:
                      // their order is home's.
                      if (vm.editing && pinned.length > 1)
                        ReorderableList(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: pinned.length,
                          onReorderItem: vm.reorderPinned,
                          proxyDecorator: (child, index, animation) => AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) => Transform.scale(
                              scale: 1 + 0.02 * Curves.easeOutBack.transform(animation.value),
                              child: Material(
                                color: Colors.transparent,
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x4D583727),
                                        blurRadius: 36,
                                        offset: Offset(0, 18),
                                        spreadRadius: -14,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                ),
                              ),
                            ),
                            child: child,
                          ),
                          // A long press anywhere on the row, or a drag
                          // on the dots, moves it.
                          itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
                            key: ValueKey('reorder-${pinned[i].id}'),
                            index: i,
                            child: row(
                              pinned[i],
                              i,
                              handle: ReorderableDragStartListener(
                                index: i,
                                child: Semantics(
                                  label: l10n.dragToReorder,
                                  // A finger-sized target around the dots.
                                  child: const ColoredBox(
                                    color: Colors.transparent,
                                    child: SizedBox(width: 44, height: 48, child: Center(child: Grip())),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        for (final (i, list) in pinned.indexed) row(list, i),
                      if (pinned.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(l10n.pinHint, style: PnText.sub),
                        ),
                      _SectionHead(title: l10n.otherListsTitle, count: '${others.length}'),
                      if (vm.editing && vm.homeFull && others.isNotEmpty)
                        Text(l10n.homeFull, style: PnText.meta.copyWith(fontWeight: FontWeight.w400, height: 1.4)),
                      for (final (i, list) in others.indexed) row(list, i + pinned.length),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _subtitle(BuildContext context, AppLocalizations l10n, AllListsViewModel vm, TaskList list) {
    final s = vm.stats(list);
    final progress = s.total == 0 ? l10n.listEmpty : l10n.listRemaining(s.open);
    final day = list.day;
    return day == null ? progress : '$progress, ${dateLabel(context, effectiveDay(day)).toLowerCase()}';
  }
}

/// "Pinned." 2/4, "Other lists." 5.
class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, required this.count});

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(title, style: PnText.section.copyWith(fontSize: 22, letterSpacing: -0.44))),
          Text(
            count,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: PnColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.list,
    required this.editing,
    required this.canPin,
    required this.subtitle,
    required this.showPerso,
    required this.onOpen,
    required this.onPin,
    required this.onDelete,
    this.handle,
  });

  final TaskList list;
  final bool editing;
  final bool canPin;
  final String subtitle;
  final bool showPerso;
  final VoidCallback onOpen;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  /// Drags the row to rearrange the pinned lists.
  final Widget? handle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = ListTheme.of(list.color);
    // Deleted with the trash button, in edit mode: no swipe.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: PnColors.cream,
        border: Border(bottom: BorderSide(color: PnColors.snow, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: editing ? null : onOpen,
              scale: 0.99,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(16)),
                    child: PnIcon.list(list.icon, color: t.fg, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: PnColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle, overflow: TextOverflow.ellipsis, style: PnText.meta),
                      ],
                    ),
                  ),
                  if (!editing) ...[
                    if (!list.isShared && showPerso) ...[
                      PersoMark(label: l10n.listPersonal, color: PnColors.muted),
                      const SizedBox(width: 8),
                    ],
                    const PnIcon(PnIcons.chevronRight, color: PnColors.muted, size: 18),
                  ],
                ],
              ),
            ),
          ),
          if (editing) ...[
            const SizedBox(width: 12),
            _EditButton(
              label: list.pinned ? l10n.unpinNamed(list.name) : l10n.pinNamed(list.name),
              filled: !list.pinned,
              onTap: canPin ? onPin : null,
              child: PnIcon(list.pinned ? PnIcons.pinOff : PnIcons.pin, color: PnColors.terraDark, size: 20),
            ),
            const SizedBox(width: 8),
            _EditButton(
              label: l10n.deleteNamed(list.name),
              filled: false,
              onTap: onDelete,
              child: const PnIcon(PnIcons.trash, color: PnColors.danger, size: 20),
            ),
            if (handle != null) handle!,
          ],
        ],
      ),
    );
  }
}

/// 40×40 button of a row in edit mode: peach, or outlined in peach. Faded
/// when [onTap] is null.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.label, required this.filled, required this.onTap, required this.child});

  final String label;
  final bool filled;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0.6, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Pressable(
          onTap: onTap,
          scale: 0.94,
          semanticLabel: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? PnColors.peach : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: filled ? null : Border.all(color: PnColors.peach, width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
