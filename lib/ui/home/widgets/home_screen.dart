import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/list_stats.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/task_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/home_header.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/tab_stagger.dart';
import '../../core/ui/task_row.dart';
import '../view_models/home_viewmodel.dart';
import 'list_card.dart';
import 'pinned_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel, this.onCreateList});

  final HomeViewModel viewModel;

  /// Opens the "New list" sheet (from the empty-state card).
  final VoidCallback? onCreateList;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.viewModel.load,
      builder: (context, child) {
        final vm = widget.viewModel;
        // Data already on screen stays there while it refreshes.
        if (vm.load.running && vm.isEmpty) return const Center(child: CircularProgressIndicator(color: PnColors.terra));
        if (vm.load.error && vm.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.homeLoadError, style: PnText.sub),
                const SizedBox(height: 8),
                LinkButton(label: l10n.tryAgain, onPressed: widget.viewModel.load.execute),
              ],
            ),
          );
        }
        return child!;
      },
      child: ListenableBuilder(listenable: widget.viewModel, builder: (context, _) => _content(context, l10n)),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l10n) {
    final vm = widget.viewModel;
    final day = isDaytime();
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + homeHeaderTop, bottom: bottomBarClearance),
          child: ContentWidth(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Gap(
                  gap: 20,
                  children: [
                    const HomeHeaderGap(),
                    Gap(
                      gap: 8,
                      children: [
                        Text(l10n.greeting(vm.name), style: PnText.greeting),
                        Text(
                          vm.isEmpty ? l10n.shallWeStart : (day ? l10n.goodDay : l10n.goodNight),
                          style: PnText.lede,
                        ),
                      ],
                    ),
                    // While swiping, the blocks trail the title, one after another.
                    TabStagger(depth: 1, child: _lists(context, l10n)),
                    TabStagger(depth: 2, child: _section(context, l10n, l10n.todayTitle, vm.today, alwaysShow: true)),
                    if (vm.tomorrow.isNotEmpty)
                      TabStagger(depth: 3, child: _section(context, l10n, l10n.tomorrowTitle, vm.tomorrow)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _lists(BuildContext context, AppLocalizations l10n) {
    final vm = widget.viewModel;
    final shown = vm.visibleLists;
    return Gap(
      gap: 10,
      children: [
        if (shown.isNotEmpty)
          // A long press on a card lets the cards be rearranged.
          PinnedGrid(
            lists: shown,
            onReorder: vm.reorderPinned,
            // Pushed, so that going back pops it and the card shrinks back.
            onOpen: (list) => context.push(Routes.list(list.id)),
            cardBuilder: (list, i, onTap, {rise = true}) => ListCard(
              list: list,
              index: i,
              rise: rise,
              showPerso: !vm.isSolo,
              subtitle: _progress(l10n, vm.stats(list)),
              onTap: onTap,
            ),
          ),
        if (vm.listCount > shown.length)
          Center(
            child: Pressable(
              onTap: () => context.push(Routes.lists),
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.seeAllLists(vm.listCount), style: PnText.pill.copyWith(color: PnColors.terraDark)),
                    const SizedBox(width: 4),
                    const PnIcon(PnIcons.chevronRight, color: PnColors.terraDark, size: 16),
                  ],
                ),
              ),
            ),
          ),
        if (vm.listCount == 0) FirstListCard(onCreate: widget.onCreateList),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    AppLocalizations l10n,
    String title,
    List<Task> tasks, {
    bool alwaysShow = false,
  }) {
    final vm = widget.viewModel;
    final open = tasks.where((t) => !t.done).length;
    return Gap(
      gap: 6,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(title, style: PnText.section)),
            if (tasks.isNotEmpty)
              Text(
                _progress(l10n, ListStats(total: tasks.length, open: open)),
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: PnColors.muted),
              ),
          ],
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l10n.nothingPlanned, style: PnText.sub),
          ),
        for (final t in tasks)
          TaskRow(
            key: ValueKey(t.id),
            task: t,
            tag: _tag(vm.listOf(t)),
            // Checked from here, renamed or deleted from the list itself:
            // a swipe here goes to Notes.
            onToggle: () => vm.toggle(t),
          ),
      ],
    );
  }

  /// The task's list: opens it. Long names are cut short, so the task's
  /// title keeps the room.
  Widget? _tag(TaskList? list) {
    if (list == null) return null;
    final theme = ListTheme.of(list.color);
    return Pressable(
      // Pushed, as from its card: going back comes here.
      onTap: () => context.push(Routes.list(list.id)),
      semanticLabel: list.name,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: InfoPill(text: list.name, color: theme.fg, background: theme.bg),
      ),
    );
  }
}

String _progress(AppLocalizations l10n, ListStats s) => s.total == 0 ? l10n.listEmpty : l10n.listRemaining(s.open);
