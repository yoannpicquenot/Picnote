import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/colors.dart';
import '../themes/theme.dart';
import 'buttons.dart';
import 'pn_icon.dart';

/// Rounded text field with a peach outline that turns terracotta on focus,
/// or stays terracotta with a message below on error. Never red.
class PnTextField extends StatefulWidget {
  const PnTextField({
    super.key,
    this.controller,
    this.hint,
    this.error,
    this.autofocus = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.tall = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? hint;
  final String? error;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool tall;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  /// Lets password managers (Google, Dashlane…) fill the field.
  final Iterable<String>? autofillHints;

  @override
  State<PnTextField> createState() => _PnTextFieldState();
}

class _PnTextFieldState extends State<PnTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    final border = error != null || _focus.hasFocus ? PnColors.terra : PnColors.peach;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: widget.tall ? 52 : 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: PnColors.snow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(fontSize: 16, color: PnColors.ink),
            decoration: InputDecoration.collapsed(
              hintText: widget.hint,
              hintStyle: const TextStyle(fontSize: 16, color: PnColors.placeholder),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: PnColors.terraDark),
            ),
          ),
      ],
    );
  }
}

/// Round-cornered checkbox that pops when checked.
/// Runs [onTap], with a short, discreet tick when it checks the item (not
/// when it unchecks it). The phone's touch-feedback setting applies.
void checkTapped({required bool done, required VoidCallback onTap}) {
  if (!done) HapticFeedback.lightImpact();
  onTap();
}

class PnCheck extends StatelessWidget {
  const PnCheck({
    super.key,
    required this.done,
    required this.onTap,
    required this.label,
    this.color = PnColors.terra,
    this.ink = PnColors.peach,
  });

  final bool done;
  final VoidCallback? onTap;
  final String label;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: done,
      label: label,
      child: GestureDetector(
        onTap: onTap == null ? null : () => checkTapped(done: done, onTap: onTap!),
        behavior: HitTestBehavior.opaque,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(done),
          tween: Tween(begin: done ? 0.8 : 1, end: 1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: done ? null : Border.all(color: color, width: 2),
            ),
            child: done ? PnIcon(PnIcons.check, color: ink, size: 16) : null,
          ),
        ),
      ),
    );
  }
}

/// Task title with a terracotta line drawn across when done.
class StrikeTitle extends StatelessWidget {
  const StrikeTitle({
    super.key,
    required this.text,
    required this.done,
    this.color = PnColors.ink,
    this.strike = PnColors.terra,
  });

  final String text;
  final bool done;
  final Color color;
  final Color strike;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: PnText.body.copyWith(color: done ? PnColors.muted : color),
          child: Text(text),
        ),
        Positioned.fill(
          left: -16,
          right: -16,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: done ? 1 : 0),
              duration: const Duration(milliseconds: 220),
              builder: (context, t, _) => FractionallySizedBox(
                widthFactor: t == 0 ? 0.0001 : t,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(color: strike, borderRadius: BorderRadius.circular(1)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// iOS-like switch, display only: the row around it handles taps.
class PnToggle extends StatelessWidget {
  const PnToggle({super.key, required this.on, this.color = PnColors.terra});

  final bool on;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: on ? color : PnColors.line, borderRadius: BorderRadius.circular(14)),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: PnColors.snow,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x331C120D), blurRadius: 3, offset: Offset(0, 1))],
          ),
        ),
      ),
    );
  }
}

/// Round chip with optional leading icon (day, reminder, tags).
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.text, required this.color, required this.background, this.icon});

  final String text;
  final Color color;
  final Color background;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[PnIcon(icon!, color: color, size: 12), const SizedBox(width: 5)],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: PnText.tiny.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable pill of a chip row (dates, times).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.bg,
    required this.fg,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? fg : bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(label, style: PnText.pill.copyWith(color: selected ? bg : fg)),
          ],
        ),
      ),
    );
  }
}

/// Lock + "Personal" on cards of personal lists and notes.
class PersoMark extends StatelessWidget {
  const PersoMark({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PnIcon(PnIcons.lock, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: PnText.tiny.copyWith(color: color)),
      ],
    );
  }
}

/// Peach information box ("No connection", "Too many tries").
class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.text,
    this.icon = PnIcons.info,
    this.background = PnColors.peach,
    this.color = PnColors.terraDark,
  });

  final String text;
  final String icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          PnIcon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// "⋯" at the top of an open list or note: opens its menu.
class MenuDotsButton extends StatelessWidget {
  const MenuDotsButton({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: label,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small chevron in a white circle on the corner of an icon tile that opens
/// the color and icon picker. Points up while the picker is open.
class PickerBadge extends StatelessWidget {
  const PickerBadge({super.key, required this.color, required this.open});

  final Color color;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PnColors.snow,
        shape: BoxShape.circle,
        border: Border.all(color: PnColors.line),
      ),
      child: PnIcon(PnIcons.chevronRight, color: color, size: 12, turns: open ? 3 : 1),
    );
  }
}
