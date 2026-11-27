import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/theme.dart';
import 'pn_icon.dart';

/// Shrinks slightly while pressed, like every Picnote tap target: 0.98 for
/// buttons, 0.97 for cards, 0.94 for small squares. [builder], instead of
/// [child], also gets whether it is pressed, for the pressed color.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, this.child, this.builder, this.scale = 0.97, this.semanticLabel})
    : assert(child != null || builder != null);

  final VoidCallback? onTap;
  final Widget? child;
  final Widget Function(BuildContext context, bool pressed)? builder;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap != null && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.builder?.call(context, _down) ?? widget.child,
        ),
      ),
    );
  }
}

/// Primary: night. Secondary: snow with terraDark text. Tonal: peach with
/// terraDark text. Tertiary: text only. Danger: red.
enum PnButtonKind { primary, secondary, tonal, danger, tertiary }

/// Full-width action. Disabled when [onPressed] is null (grey, not faded).
class PnButton extends StatelessWidget {
  const PnButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = PnButtonKind.primary,
    this.icon,
    this.compact = false,
    this.background,
    this.foreground,
  });

  /// Colored with a list theme (ink background, tint text).
  const PnButton.themed({
    super.key,
    required this.label,
    required this.onPressed,
    required Color this.background,
    required Color this.foreground,
    this.compact = false,
  }) : kind = PnButtonKind.primary,
       icon = null;

  final String label;
  final VoidCallback? onPressed;
  final PnButtonKind kind;
  final String? icon;
  final bool compact;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (bg, fg) = !enabled
        ? (PnColors.grey500, PnColors.muted)
        : switch (kind) {
            PnButtonKind.primary => (background ?? PnColors.night, foreground ?? PnColors.peach),
            PnButtonKind.secondary => (PnColors.snow, foreground ?? PnColors.terraDark),
            PnButtonKind.tonal => (PnColors.peach, foreground ?? PnColors.terraDark),
            PnButtonKind.danger => (PnColors.danger, PnColors.snow),
            PnButtonKind.tertiary => (Colors.transparent, foreground ?? PnColors.ink),
          };
    return Pressable(
      onTap: onPressed,
      scale: 0.98,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: compact ? 44 : 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? pressedColor(bg) : bg,
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[PnIcon(icon!, color: fg, size: 20), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: compact ? 15 : 16, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pressed state of a button whose resting color is [bg]: night
/// darkens to terraPressed, snow to cream100, peach to its pressed tone,
/// red to a deeper red, nothing to peach; a list's own color darkens.
Color pressedColor(Color bg) {
  if (bg == PnColors.night) return PnColors.terraPressed;
  if (bg == PnColors.snow) return PnColors.cream100;
  if (bg == PnColors.peach) return PnColors.tonalPressed;
  if (bg == PnColors.danger) return PnColors.dangerPressed;
  if (bg == Colors.transparent) return PnColors.peach;
  return Color.lerp(bg, Colors.black, 0.28)!;
}

/// Square back button of the onboarding screens. Faded while [onPressed] is
/// null.
class BackSquare extends StatelessWidget {
  const BackSquare({super.key, required this.onPressed, required this.label});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      scale: 0.94,
      semanticLabel: label,
      builder: (context, pressed) => AnimatedOpacity(
        opacity: onPressed == null ? 0.45 : 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? PnColors.tonalPressed : PnColors.peach,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const PnIcon(PnIcons.chevronRight, color: PnColors.terraDark, size: 22, turns: 2),
        ),
      ),
    );
  }
}

/// "‹ Home": back link at the top of a screen.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, required this.onPressed, this.color = PnColors.terraDark});

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PnIcon(PnIcons.chevronRight, color: color, size: 20, turns: 2),
            const SizedBox(width: 6),
            // Shortened with "…" when the row is tight (large system text).
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PnText.pill.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small text action ("Change email", "Later").
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onPressed, this.color = PnColors.terraDark});

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label, style: PnText.pill.copyWith(color: onPressed == null ? PnColors.muted : color)),
      ),
    );
  }
}

/// 36px rounded square holding an icon or three dots ("Options").
class IconChip extends StatelessWidget {
  const IconChip({super.key, required this.onPressed, required this.background, required this.child, this.label});

  final VoidCallback? onPressed;
  final Color background;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      scale: 0.94,
      semanticLabel: label,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? pressedColor(background) : background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }
}

/// "+ New list", "+ New note": a small night pill at the top right of the
/// Lists and Notes tabs.
class NewPill extends StatelessWidget {
  const NewPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        height: 36,
        padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
        decoration: BoxDecoration(color: PnColors.night, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PnIcon(PnIcons.plus, color: PnColors.peach, size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PnText.pill.copyWith(color: PnColors.peach),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
