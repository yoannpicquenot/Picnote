import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/theme.dart';
import 'buttons.dart';
import 'pn_icon.dart';

/// Two [ChoiceCard]s side by side, as tall as the taller one.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow(this.first, this.second, {super.key});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: first),
          const SizedBox(width: 10),
          Expanded(child: second),
        ],
      ),
    );
  }
}

/// A white card with a visual and a title: "Create a household" / "Join a
/// household", "By email" / "By code".
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({super.key, required this.visual, required this.title, required this.onTap});

  final Widget visual;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pressed ? PnColors.choicePressed : PnColors.snow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PnColors.peachLine, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: Align(alignment: Alignment.centerLeft, child: visual),
            ),
            const SizedBox(height: 14),
            Text(title, style: PnText.cardTitle.copyWith(fontSize: 19, color: PnColors.terraDark)),
          ],
        ),
      ),
    );
  }
}

/// A 44 px peach disc holding an icon, for the choice cards.
class IconDisc extends StatelessWidget {
  const IconDisc(this.icon, {super.key, this.size = 22});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: PnColors.peach, shape: BoxShape.circle),
      child: PnIcon(icon, color: PnColors.terraDark, size: size),
    );
  }
}
