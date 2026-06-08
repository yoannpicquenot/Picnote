import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import 'add_task_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; // 0 = Tasks, 1 = Memos

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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hi ${state.currentUser},',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 30,
                          ),
                        ),
                      ],
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

// ─── Partner note banner ────────────────────────────────────────────────────

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

// ─── Tasks view ─────────────────────────────────────────────────────────────

class _TasksView extends StatelessWidget {
  final AppState state;
  final bool isDark;

  const _TasksView({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (state.todayTasks.isNotEmpty) ...[
          _SectionHeader(label: 'Today.', isDark: isDark),
          const SizedBox(height: 8),
          ...state.todayTasks.map((t) => _TaskTile(task: t, isDark: isDark)),
        ],
        if (state.tomorrowTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(label: 'Tomorrow.', isDark: isDark),
          const SizedBox(height: 8),
          ...state.tomorrowTasks.map((t) => _TaskTile(task: t, isDark: isDark)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: isDark ? AppColors.brownMedium : AppColors.brown,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final bool isDark;

  const _TaskTile({required this.task, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.beigeCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: GestureDetector(
          onTap: () => state.toggleTask(task.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.completed
                  ? AppColors.brown
                  : Colors.transparent,
              border: Border.all(
                color: task.completed
                    ? AppColors.brown
                    : (isDark
                        ? AppColors.beigeCard.withOpacity(0.3)
                        : AppColors.brownDark.withOpacity(0.3)),
                width: 1.5,
              ),
            ),
            child: task.completed
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed
                ? (isDark
                    ? AppColors.beigeCard.withOpacity(0.4)
                    : AppColors.brownDark.withOpacity(0.4))
                : null,
          ),
        ),
        subtitle: Text(
          'Last modified by ${task.lastModifiedBy} ${task.timeAgo}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: isDark
              ? AppColors.beigeCard.withOpacity(0.3)
              : AppColors.brownDark.withOpacity(0.3),
        ),
      ),
    );
  }
}

// ─── Memos view ──────────────────────────────────────────────────────────────

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

// ─── Bottom bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  final bool isDark;

  const _BottomBar({
    required this.selectedIndex,
    required this.onTap,
    required this.onAdd,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.beigeCard,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.white.withOpacity(0.06)
                : AppColors.brownDark.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu icon
          Icon(
            Icons.menu,
            color: isDark
                ? AppColors.beigeCard.withOpacity(0.5)
                : AppColors.brownDark.withOpacity(0.4),
          ),
          const Spacer(),

          // Tasks tab
          _TabItem(
            label: 'Tasks',
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Memos tab
          _TabItem(
            label: 'Memos',
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
            isDark: isDark,
          ),

          const Spacer(),

          // Add button
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.brownMedium : AppColors.brownDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.brownMedium : AppColors.brownDark)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.white
                : (isDark
                    ? AppColors.beigeCard.withOpacity(0.5)
                    : AppColors.brownDark.withOpacity(0.5)),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
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
        if (data['partnerId'] != null) return const SizedBox(); // paired, no banner
        final inviteEmail = data['inviteEmail'] as String?;
        if (inviteEmail == null) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.only(top: 14),
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
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Waiting for $inviteEmail to join...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
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
