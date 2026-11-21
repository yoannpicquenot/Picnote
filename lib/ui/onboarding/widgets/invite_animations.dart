import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/pn_icon.dart';

/// Step 08a, about 1.9 s before home: a paper plane flies off a peach disc,
/// then a green check pops with a ring around it, over "Invitation sent."
/// and the address.
class InviteSent extends StatefulWidget {
  const InviteSent({super.key, required this.title, required this.to, required this.email});

  final String title;

  /// "To {email}", with [email] in bold.
  final String to;
  final String email;

  @override
  State<InviteSent> createState() => _InviteSentState();
}

class _InviteSentState extends State<InviteSent> with SingleTickerProviderStateMixin {
  static const _ms = 1600.0;
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  Animation<double> _at(double from, double length, [Curve curve = Curves.linear]) => CurvedAnimation(
    parent: _c,
    curve: Interval(from / _ms, math.min(1, (from + length) / _ms), curve: curve),
  );

  late final _disc = _at(0, 260, Curves.easeOutBack);
  late final _plane = _at(120, 820, const Cubic(.5, 0, .7, .4));
  late final _ring = _at(900, 700, Curves.easeOut);
  late final _check = _at(860, 320, Curves.easeOutBack);
  late final _text = _at(880, 300, Curves.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// The plane: a small lift by 55 %, then off to the top right.
  Widget _flyingPlane(double t) {
    double lerp(double a, double b, double k) => a + (b - a) * k;
    final (dx, dy, turn, scale, opacity) = t < .55
        ? (lerp(0, 4, t / .55), lerp(0, -3, t / .55), lerp(0, -8, t / .55), 1.0, 1.0)
        : (
            lerp(4, 34, (t - .55) / .45),
            lerp(-3, -30, (t - .55) / .45),
            lerp(-8, -14, (t - .55) / .45),
            lerp(1, .6, (t - .55) / .45),
            1 - (t - .55) / .45,
          );
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: turn * math.pi / 180,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: const PnIcon(PnIcons.paperPlane, color: PnColors.terraDark, size: 32),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '${widget.title} ${widget.to}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Opacity(
                        opacity: _disc.value.clamp(0, 1),
                        child: Transform.scale(
                          scale: .85 + .15 * _disc.value,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(color: PnColors.peach, shape: BoxShape.circle),
                            child: SizedBox.expand(),
                          ),
                        ),
                      ),
                      if (_ring.value > 0 && _ring.value < 1)
                        Opacity(
                          opacity: .6 * (1 - _ring.value),
                          child: Transform.scale(
                            scale: .6 + 1.3 * _ring.value,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: PnColors.sage, width: 2),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      if (_plane.value < 1) _flyingPlane(_plane.value),
                      if (_check.value > 0)
                        Opacity(
                          opacity: _check.value.clamp(0, 1),
                          child: Transform.scale(
                            scale: .85 + .15 * _check.value,
                            child: Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: PnColors.sage, shape: BoxShape.circle),
                              child: const PnIcon(PnIcons.check, color: PnColors.snow, size: 26),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: _text.value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - _text.value)),
                    child: Column(
                      children: [
                        Text(widget.title, style: PnText.prompt, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            children: [
                              for (final (i, part) in widget.to.split(widget.email).indexed) ...[
                                if (i > 0)
                                  TextSpan(
                                    text: widget.email,
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: PnColors.ink),
                                  ),
                                TextSpan(text: part),
                              ],
                            ],
                          ),
                          style: PnText.sub,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 08b: the invite code in six large peach boxes that pop one after
/// the other once [code] is known.
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
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(18)),
          child: code == null || i >= code.length
              ? null
              : Text(
                  code[i],
                  style: const TextStyle(
                    fontFamily: PnFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    color: PnColors.terraDark,
                  ),
                ),
        ),
      ),
    );
  }
}
