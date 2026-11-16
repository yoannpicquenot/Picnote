import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/colors.dart';

/// Material's selection handles, larger and in terracotta, so that a
/// finger can grab them. Their touch area grows with them.
class PnSelectionControls extends MaterialTextSelectionControls {
  static const _size = 30.0;

  @override
  Size getHandleSize(double textLineHeight) => const Size(_size, _size);

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textHeight, [VoidCallback? onTap]) {
    final handle = SizedBox.square(
      dimension: _size,
      child: CustomPaint(painter: _HandlePainter(PnColors.terra)),
    );
    // Drawn pointing up-left: the end handle as is, the start one turned
    // to point up-right, the caret's turned to point straight up.
    return switch (type) {
      TextSelectionHandleType.left => Transform.rotate(angle: math.pi / 2, child: handle),
      TextSelectionHandleType.right => handle,
      TextSelectionHandleType.collapsed => Transform.rotate(angle: math.pi / 4, child: handle),
    };
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) => switch (type) {
    TextSelectionHandleType.left => const Offset(_size, 0),
    TextSelectionHandleType.right => Offset.zero,
    TextSelectionHandleType.collapsed => const Offset(_size / 2, -4),
  };
}

final pnSelectionControls = PnSelectionControls();

/// A circle with its top-left quarter squared off.
class _HandlePainter extends CustomPainter {
  _HandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.width / 2;
    canvas
      ..drawCircle(Offset(radius, radius), radius, paint)
      ..drawRect(Rect.fromLTWH(0, 0, radius, radius), paint);
  }

  @override
  bool shouldRepaint(_HandlePainter old) => old.color != color;
}

/// The drop under the caret, to slide it with a finger.
class CaretHandle extends StatelessWidget {
  const CaretHandle({super.key});

  /// Android's own size: it hides no more text than it has to.
  static const size = 22.0;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: math.pi / 4,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _HandlePainter(PnColors.terra)),
    ),
  );
}
