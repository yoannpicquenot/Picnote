import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../widgets/picnote_face.dart';
import 'add_task_sheet.dart';
import 'change_partner_email_sheet.dart';
import 'menu_sheet.dart';
import 'settings_screen.dart';
import 'task_detail_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; // 0 = Tasks, 1 = Memos
  bool _menuOpen = false;

  void _openMenu() {
    setState(() => _menuOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuSheet(
        onSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _menuOpen = false);
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Having a good night?';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with face decoration
            ClipRect(
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Face decoration â€” top-right, partially clipped
                    Positioned(
                      right: -16,
                      top: -8,
                      child: Opacity(
                        opacity: isDark ? 0.18 : 0.12,
                        child: const PicnoteFace(size: 220),
                      ),
                    ),
                    // Greeting text & banners
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi ${state.currentUser},',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 30,
                            ),
                          ),
                          Text(
                            _greeting(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                            ),
                          ),

                          // Waiting for partner banner (real-time)
                          _WaitingBanner(),

                          // Partner note banner
                          if (state.hasUnreadNote) ...[
                            const SizedBox(height: 14),
                            _NoteBanner(
                              partner: state.partnerUser,
                              preview: state.partnerNotePreview ?? '',
                              onDismiss: state.dismissNote,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Task list
            Expanded(
              child: _tab == 0
                  ? _TasksView(state: state, isDark: isDark)
                  : _MemosView(state: state, isDark: isDark),
            ),

            // Bottom nav
            _BottomBar(
              selectedIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              isDark: isDark,
              isMenuOpen: _menuOpen,
              onMenuTap: _openMenu,
              onAdd: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTaskSheet(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Partner note banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NoteBanner extends StatelessWidget {
  final String partner;
  final String preview;
  final VoidCallback onDismiss;
  final bool isDark;

  const _NoteBanner({
    required this.partner,
    required this.preview,
    required this.onDismiss,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardLight : AppColors.beigeCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.brownMedium.withOpacity(0.3)
              : AppColors.brown.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 16,
            color: isDark ? AppColors.brownMedium : AppColors.brown,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$partner $preview',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: isDark
                ? AppColors.beigeCard.withOpacity(0.4)
                : AppColors.brownDark.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Tasks view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum _ItemKind { todayHeader, tomorrowHeader, task }

class _Item {
  final _ItemKind kind;
  final Task? task;
  const _Item.header(_ItemKind k) : kind = k, task = null;
  const _Item.task(Task t) : kind = _ItemKind.task, task = t;
  bool get isHeader => kind != _ItemKind.task;
  TaskSection get section =>
      kind == _ItemKind.tomorrowHeader ? TaskSection.tomorrow : TaskSection.today;
}

class _TasksView extends StatefulWidget {
  final AppState state;
  final bool isDark;

  const _TasksView({required this.state, required this.isDark});

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  List<_Item> _buildItems() {
    final items = <_Item>[];
    final today = widget.state.todayTasks;
    final tomorrow = widget.state.tomorrowTasks;
    if (today.isNotEmpty) {
      items.add(const _Item.header(_ItemKind.todayHeader));
      for (final t in today) items.add(_Item.task(t));
    }
    if (tomorrow.isNotEmpty) {
      items.add(const _Item.header(_ItemKind.tomorrowHeader));
      for (final t in tomorrow) items.add(_Item.task(t));
    }
    return items;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final items = _buildItems();
    if (items[oldIndex].isHeader) return;

    final movedTask = items[oldIndex].task!;
    final item = items.removeAt(oldIndex);

    // Don't drop on a header â€” push past it
    if (newIndex < items.length && items[newIndex].isHeader) newIndex++;
    newIndex = newIndex.clamp(0, items.length);

    items.insert(newIndex, item);

    // Determine new section by finding the nearest preceding header
    TaskSection newSection = TaskSection.today;
    for (int i = newIndex; i >= 0; i--) {
      if (items[i].isHeader) {
        newSection = items[i].section;
        break;
      }
    }

    // Ordered tasks after reorder, filtered to new section
    final allTasks = items.where((x) => !x.isHeader).map((x) => x.task!).toList();
    final sectionTasks = allTasks
        .where((t) => t.section == newSection || t.id == movedTask.id)
        .toList();

    final movedIdx = sectionTasks.indexWhere((t) => t.id == movedTask.id);
    final prev = movedIdx > 0 ? sectionTasks[movedIdx - 1] : null;
    final next = movedIdx < sectionTasks.length - 1 ? sectionTasks[movedIdx + 1] : null;

    final double newSortOrder;
    if (prev == null && next == null) {
      newSortOrder = DateTime.now().millisecondsSinceEpoch.toDouble();
    } else if (prev == null) {
      newSortOrder = next!.sortOrder - 1000;
    } else if (next == null) {
      newSortOrder = prev.sortOrder + 1000;
    } else {
      newSortOrder = (prev.sortOrder + next.sortOrder) / 2;
    }

    widget.state.reorderTask(movedTask.id, newSection, newSortOrder);
  }

  void _openDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task, state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No tasks yet.\nTap + to add one.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ReorderableListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      children: [
        for (int i = 0; i < items.length; i++)
          if (items[i].isHeader)
            _SectionHeader(
              key: ValueKey(items[i].kind),
              label: items[i].kind == _ItemKind.todayHeader ? 'Today.' : 'Tomorrow.',
              isDark: widget.isDark,
            )
          else
            ReorderableDelayedDragStartListener(
              key: ValueKey(items[i].task!.id),
              index: i,
              child: _TaskTile(
                task: items[i].task!,
                isDark: widget.isDark,
                onTap: () => _openDetail(items[i].task!),
              ),
            ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({super.key, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isToday = label.startsWith('Today');
    return Padding(
      padding: EdgeInsets.only(left: 52, top: isToday ? 4 : 28, bottom: 14),
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: isDark ? AppColors.brownMedium : AppColors.brown,
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final bool isDark;
  final VoidCallback onTap;

  const _TaskTile({
    super.key,
    required this.task,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final dimColor = isDark
        ? AppColors.beigeCard.withOpacity(0.35)
        : AppColors.brownDark.withOpacity(0.35);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => state.toggleTask(task.id),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.completed ? AppColors.brown : Colors.transparent,
                      border: task.completed
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.beigeCard.withOpacity(0.4)
                                  : AppColors.brownDark.withOpacity(0.3),
                              width: 1.5,
                            ),
                    ),
                    child: task.completed
                        ? const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: dimColor,
                          color: task.completed ? dimColor : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Last modified by ${task.lastModifiedBy} ${task.timeAgo}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Chevron tap target
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardLight
                        : AppColors.brownDark.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: isDark
                        ? AppColors.beigeCard.withOpacity(0.4)
                        : AppColors.brownDark.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 40,
          color: isDark
              ? AppColors.white.withOpacity(0.05)
              : AppColors.brownDark.withOpacity(0.06),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Memos view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MemosView extends StatelessWidget {
  final AppState state;
  final bool isDark;
  const _MemosView({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (state.memos.isEmpty) {
      return Center(
        child: Text(
          'No memos yet.\nTap + to add one.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: state.memos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final memo = state.memos[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.beigeCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                memo.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Last edited by ${memo.lastModifiedBy}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

// â”€â”€â”€ Bottom bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  final VoidCallback onMenuTap;
  final bool isDark;
  final bool isMenuOpen;

  const _BottomBar({
    required this.selectedIndex,
    required this.onTap,
    required this.onAdd,
    required this.onMenuTap,
    required this.isDark,
    required this.isMenuOpen,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.brownMedium : AppColors.brownDark;
    final menuColor = isMenuOpen
        ? accent
        : accent.withOpacity(0.55);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.beigeCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          // Menu icon
          GestureDetector(
            onTap: onMenuTap,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Icon(
                isMenuOpen ? Icons.keyboard_arrow_down_rounded : Icons.menu_rounded,
                key: ValueKey(isMenuOpen),
                color: menuColor,
                size: 26,
              ),
            ),
          ),

          const Spacer(),

          // Tab group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TabItem(
                label: 'Tasks',
                selected: selectedIndex == 0,
                onTap: () => onTap(0),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _TabItem(
                label: 'Memos',
                selected: selectedIndex == 1,
                onTap: () => onTap(1),
                isDark: isDark,
              ),
            ],
          ),

          const Spacer(),

          // Add button â€” rounded rectangle
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Selected pill: charcoal (dark) in dark mode, brownDark in light
    final pillColor = isDark ? AppColors.charcoal : AppColors.brownDark;
    final unselectedColor = isDark
        ? AppColors.brownMedium.withOpacity(0.7)
        : AppColors.brownDark.withOpacity(0.45);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? pillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : unselectedColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _WaitingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox();
        if (data['partnerId'] != null) return const SizedBox(); // paired â€” hide

        final pairId = data['pairId'] as String?;
        if (pairId == null) return const SizedBox(); // no space created yet

        final inviteEmail = data['inviteEmail'] as String?;

        // â”€â”€ Email invite pending â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (inviteEmail != null) {
          return _buildRow(
            context,
            leading: const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: 'Waiting for $inviteEmail to join...',
            trailing: Icon(
              Icons.edit_outlined,
              size: 14,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ChangePartnerEmailSheet(currentEmail: inviteEmail),
            ),
          );
        }

        // â”€â”€ Space created, no partner yet â€” show shareable code â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('pairs').doc(pairId).get(),
          builder: (context, pairSnap) {
            final code = (pairSnap.data?.data() as Map<String, dynamic>?)?['code'] as String?;
            if (code == null) return const SizedBox();
            return _buildCodeBanner(context, code);
          },
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required Widget leading,
    required String label,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brownMedium.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brownMedium.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBanner(BuildContext context, String code) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmtCode = '${code.substring(0, 3)} Â· ${code.substring(3)}';
    final accent = isDark ? AppColors.brownMedium : AppColors.brownDark;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.brownMedium.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brownMedium.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite your partner',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmtCode,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            // Copy button
            _IconAction(
              icon: Icons.copy_outlined,
              tooltip: 'Copy',
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            // Share button
            _IconAction(
              icon: Icons.share_outlined,
              tooltip: 'Share',
              onTap: () => Share.share(
                'Join my Picnote family space! Enter the code $code in the app. ðŸ¡',
                subject: 'Join my Picnote space',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.brownMedium.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 15,
          color: isDark ? AppColors.brownMedium : AppColors.brownDark,
        ),
      ),
    );
  }
}

