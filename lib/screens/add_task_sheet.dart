import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';

class AddTaskSheet extends StatefulWidget {
  final AppState state;
  const AddTaskSheet({super.key, required this.state});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _controller = TextEditingController();
  TaskSection _section = TaskSection.today;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.beigeCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.beigeCard.withOpacity(0.2)
                    : AppColors.brownDark.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'New task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(
              color: isDark ? AppColors.beigeCard : AppColors.brownDark,
            ),
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.beigeCard.withOpacity(0.35)
                    : AppColors.brownDark.withOpacity(0.35),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkCardLight : AppColors.beige,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Section toggle
          Row(
            children: [
              _SectionChip(
                label: 'Today',
                selected: _section == TaskSection.today,
                onTap: () => setState(() => _section = TaskSection.today),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _SectionChip(
                label: 'Tomorrow',
                selected: _section == TaskSection.tomorrow,
                onTap: () => setState(() => _section = TaskSection.tomorrow),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  widget.state.addTask(_controller.text.trim(), _section);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.brownMedium : AppColors.brownDark,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add task',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _SectionChip({
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.brownMedium : AppColors.brownDark)
              : (isDark ? AppColors.darkCardLight : AppColors.beige),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.white
                : (isDark
                    ? AppColors.beigeCard.withOpacity(0.6)
                    : AppColors.brownDark.withOpacity(0.6)),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
