import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MenuSheet extends StatelessWidget {
  final VoidCallback? onSettings;

  const MenuSheet({super.key, this.onSettings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 12, 24, 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.beigeCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.beigeCard.withOpacity(0.2)
                    : AppColors.brownDark.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          _MenuRow(
            icon: Icons.tune_rounded,
            label: 'Parameters',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              onSettings?.call();
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardLight : AppColors.beige,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.brownMedium : AppColors.brown,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.beigeCard : AppColors.brownDark,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark
                  ? AppColors.beigeCard.withOpacity(0.3)
                  : AppColors.brownDark.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
