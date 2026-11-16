import 'package:flutter/material.dart';

/// Fades [child] in while it rises by 10 px, after [delay]: cards appearing
/// one after the other. Shown at once when the phone asks for less motion.
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, required this.child, this.delay = Duration.zero});

  /// [index]-th item of a list, 50 ms after the previous one.
  RiseIn.staggered({super.key, required this.child, required int index})
    : delay = Duration(milliseconds: 50 * index.clamp(0, 8));

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = const Duration(milliseconds: 340) + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
