import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/theme.dart';

/// The invite code in six large peach boxes that pop one after the other
/// once [code] is known, for the "Give them this code." sheet.
class InviteCodeBoxes extends StatefulWidget {
  const InviteCodeBoxes({super.key, required this.code, required this.label});

  final String? code;
  final String label;

  @override
  State<InviteCodeBoxes> createState() => _InviteCodeBoxesState();
}

class _InviteCodeBoxesState extends State<InviteCodeBoxes> with SingleTickerProviderStateMixin {
  // Box i pops for 320 ms from 120 + 60 i ms.
  static const _ms = 120 + 5 * 60 + 320.0;
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 740));

  @override
  void initState() {
    super.initState();
    if (widget.code != null) _c.forward();
  }

  @override
  void didUpdateWidget(InviteCodeBoxes old) {
    super.didUpdateWidget(old);
    if (old.code == null && widget.code != null) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code;
    return Semantics(
      container: true,
      label: code == null ? null : widget.label,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            children: [
              for (var i = 0; i < 6; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: _box(i, code))],
            ],
          ),
        ),
      ),
    );
  }

  Widget _box(int i, String? code) {
    final t = code == null
        ? 0.0
        : Interval((120 + i * 60) / _ms, (440 + i * 60) / _ms, curve: Curves.easeOutBack).transform(_c.value);
    // Room is kept while the code loads, so nothing jumps when it arrives.
    return Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.scale(
        scale: .85 + .15 * t,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(16)),
          child: code == null || i >= code.length
              ? null
              : Text(
                  code[i],
                  style: const TextStyle(
                    fontFamily: PnFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    color: PnColors.terraDark,
                  ),
                ),
        ),
      ),
    );
  }
}
