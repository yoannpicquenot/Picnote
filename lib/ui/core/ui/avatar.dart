import 'package:flutter/material.dart';

import '../../../domain/models/household.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'pn_icon.dart';

/// Initial on a colored circle. No photos.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initial, required this.color, this.size = 16, this.ring});

  Avatar.of(Member member, {Key? key, double size = 16, Color? ring})
    : this(key: key, initial: member.initial, color: Color(member.color), size: size, ring: ring);

  final String initial;
  final Color color;
  final double size;

  /// Outline in the color behind the avatar, to separate overlapping ones.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final ringWidth = size >= 30 ? 3.0 : 2.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: ring == null ? null : [BoxShadow(color: ring!, spreadRadius: ringWidth)],
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: size >= 56 ? PnFonts.display : null,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.5,
          height: 1,
          color: PnColors.snow,
        ),
      ),
    );
  }
}

/// Overlapping avatars of the household members.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.members, this.size = 22, required this.ring, this.overlap = 6});

  final List<Member> members;
  final double size;
  final Color ring;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final step = size - overlap;
    return SizedBox(
      width: size + step * (members.length - 1),
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, m) in members.indexed)
            Positioned(
              left: step * i,
              child: Avatar.of(m, size: size, ring: ring),
            ),
        ],
      ),
    );
  }
}

/// Dashed "+" avatar standing for the person to invite.
class DashedPlus extends StatelessWidget {
  const DashedPlus({
    super.key,
    required this.size,
    this.background = PnColors.snow,
    this.color = PnColors.terra,
    this.strokeWidth = 2,
  });

  final double size;
  final Color background;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedCircle(color, strokeWidth),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: PnIcon(PnIcons.plus, color: color, size: size * (size < 24 ? 0.56 : 0.45)),
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  _DashedCircle(this.color, this.width);

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - width / 2);
    const dashes = 14;
    const step = 2 * 3.14159265 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * step, step / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => old.color != color || old.width != width;
}
