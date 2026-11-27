import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/memo_task.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/memo_parts.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/task_row.dart';
import '../../core/ui/toast.dart';
import '../view_models/memo_viewmodel.dart';
import 'memo_sheet.dart';

/// The household's Pense-bête: a peach header, the tasks to do (each with
/// its reminder and whom it is for), "Add a task", then those done. Swipe
/// left to delete, with "Undo"; tap a task to change it.
class MemoScreen extends StatelessWidget {
  const MemoScreen({super.key, required this.viewModel});

  final MemoViewModel viewModel;

  /// Its card is on home only: back always goes there.
  void _back(BuildContext context) => context.canPop() ? context.pop() : context.go(Routes.home);

  Future<void> _edit(BuildContext context, [MemoTask? task]) async {
    final vm = viewModel;
    final saved = await showMemoSheet(
      context,
      initial: task,
      meId: vm.meId,
      partner: vm.partner,
      defaultHour: vm.defaultHour,
    );
    if (saved == null) return;
    task == null ? await vm.add(saved) : await vm.save(saved);
  }

  Future<void> _delete(BuildContext context, MemoTask task) async {
    final l10n = AppLocalizations.of(context);
    final deleted = await viewModel.delete(task);
    if (deleted == null || !context.mounted) return;
    showToast(context, l10n.memoDeleted(task.title), onUndo: () => viewModel.restore(deleted));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        final done = vm.done;
        Widget row(MemoTask t) => _MemoRow(
          key: ValueKey(t.id),
          task: t,
          members: vm.isSolo ? const [] : vm.members,
          onToggle: () => vm.toggle(t),
          onOpen: () => _edit(context, t),
          onDelete: () => _delete(context, t),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: PnColors.peach,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 4, bottom: 20),
                child: ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BackLink(label: l10n.home, onPressed: () => _back(context), color: memoTheme.fg),
                      ),
                      const SizedBox(height: 14),
                      Text(l10n.memoTitle, style: PnText.screenTitle.copyWith(fontSize: 34, color: memoTheme.fg)),
                    ],
                  ),
                ),
              ),
              ContentWidth(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final t in vm.open) row(t),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: AddRowButton(label: l10n.memoAddTask, onTap: () => _edit(context)),
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
                    for (final t in done) row(t),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A task: checkbox, title, its reminder and repeat on one grey line, and
/// whom it is for. Done, it is struck through, with nothing else.
class _MemoRow extends StatelessWidget {
  const _MemoRow({
    super.key,
    required this.task,
    required this.members,
    required this.onToggle,
    required this.onOpen,
    required this.onDelete,
  });

  final MemoTask task;

  /// Empty while alone: no avatar then.
  final List<Member> members;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = task;
    final meta = t.done ? null : memoMetaLine(context, t);
    return Dismissible(
      key: ValueKey('dismiss-${t.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: PnColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Text(l10n.delete, style: PnText.pill.copyWith(color: PnColors.snow)),
      ),
      child: Container(
        color: PnColors.cream,
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            // A finger-sized target around the box.
            SizedBox(
              width: 44,
              height: 44,
              child: Transform.translate(
                offset: const Offset(-8, 0),
                child: Center(
                  child: PnCheck(done: t.done, onTap: onToggle, label: t.done ? l10n.markNotDone : l10n.markDone),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                button: !t.done,
                label: t.done ? null : l10n.memoDetails(t.title),
                excludeSemantics: !t.done,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: t.done ? null : onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StrikeTitle(text: t.title, done: t.done),
                              if (meta != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const PnIcon(PnIcons.bell, color: PnColors.muted, size: 13),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        meta,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          color: PnColors.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!t.done && members.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          MemoWho(task: t, members: members),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
