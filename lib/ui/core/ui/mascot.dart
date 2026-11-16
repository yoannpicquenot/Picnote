import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../themes/colors.dart';
import 'mascot_data.dart';

export 'mascot_data.dart' show MascotMood;

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// A static mascot face, as used for decoration (auth, empty states).
class Face extends StatelessWidget {
  const Face(
    this.mood, {
    super.key,
    required this.height,
    this.color = PnColors.terra,
    this.highlight = PnColors.peach,
  });

  final MascotMood mood;
  final double height;
  final Color color;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final svg = mascotSvgs[mood]!;
    final markup =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${svg.width} ${svg.height}" fill="none" overflow="visible">'
        '${svg.body.replaceAll('currentColor', _hex(color)).replaceAll('HIGHLIGHT', _hex(highlight))}</svg>';
    return SvgPicture.string(markup, height: height, width: height * svg.width / svg.height);
  }
}

/// The list mascot: crossfades between moods, blinks when [blinks] changes and
/// hops when [hops] changes.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    required this.mood,
    required this.color,
    required this.highlight,
    this.height = 30,
    this.blinks = 0,
    this.hops = 0,
    this.alignment = Alignment.centerRight,
  });

  final MascotMood mood;
  final Color color;
  final Color highlight;
  final double height;
  final int blinks;
  final int hops;
  final Alignment alignment;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));

  static final _blinkCurve = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.08), weight: 45),
    TweenSequenceItem(tween: ConstantTween(0.08), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 0.08, end: 1), weight: 45),
  ]);
  static final _hopCurve = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -9), weight: 30),
    TweenSequenceItem(tween: Tween(begin: -9, end: 0), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0, end: -3), weight: 20),
    TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 25),
  ]);

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (widget.blinks != old.blinks) _blink.forward(from: 0);
    if (widget.hops != old.hops) _hop.forward(from: 0);
  }

  @override
  void dispose() {
    _blink.dispose();
    _hop.dispose();
    super.dispose();
  }

  Widget _face(MascotMood mood) {
    final face = Face(mood, height: widget.height, color: widget.color, highlight: widget.highlight);
    // Eyes sit in the top half: squash a clipped copy of it to blink.
    return AnimatedBuilder(
      key: ValueKey(mood),
      animation: _blink,
      builder: (context, _) {
        final scale = _blink.isAnimating ? _blinkCurve.evaluate(_blink) : 1.0;
        if (scale == 1.0) return face;
        return Stack(
          children: [
            ClipRect(clipper: const _Band(0.55, 1), child: face),
            ClipRect(
              clipper: const _Band(0, 0.55),
              child: Transform(
                alignment: const Alignment(0, -0.45),
                transform: Matrix4.diagonal3Values(1, scale, 1),
                child: face,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hop,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _hop.isAnimating ? _hopCurve.evaluate(_hop) : 0), child: child),
      child: SizedBox(
        width: widget.height * 1.9,
        height: widget.height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutBack,
          layoutBuilder: (current, previous) => Stack(alignment: widget.alignment, children: [...previous, ?current]),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(animation), child: child),
          ),
          child: _face(widget.mood),
        ),
      ),
    );
  }
}

class _Band extends CustomClipper<Rect> {
  const _Band(this.top, this.bottom);

  final double top;
  final double bottom;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-size.width, size.height * top, size.width * 2, size.height * bottom);

  @override
  bool shouldReclip(_Band old) => old.top != top || old.bottom != bottom;
}
