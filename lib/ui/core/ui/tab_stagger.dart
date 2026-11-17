import 'package:flutter/widgets.dart';

/// Where a page of the Lists / Notes pager is: its [index], and the
/// pager's [controller], for [TabStagger].
class TabPagePosition extends InheritedWidget {
  const TabPagePosition({super.key, required this.controller, required this.index, required super.child});

  final PageController controller;
  final int index;

  @override
  bool updateShouldNotify(TabPagePosition oldWidget) => controller != oldWidget.controller || index != oldWidget.index;
}

/// A part of a Lists or Notes page that trails the page as it is swiped:
/// [depth] of the way behind it. The title (0) arrives first, then each
/// block after it (a little more each), all in place once the page is.
class TabStagger extends StatelessWidget {
  const TabStagger({super.key, required this.depth, required this.child});

  /// Steps behind the page: 0 moves with it, each step trails 10% of the
  /// page's width further.
  final int depth;
  final Widget child;

  static const _step = 0.1;

  @override
  Widget build(BuildContext context) {
    final position = context.dependOnInheritedWidgetOfExactType<TabPagePosition>();
    if (position == null || depth == 0) return child;
    final controller = position.controller;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Always a Transform, so that what is inside keeps its state.
        var dx = 0.0;
        if (controller.hasClients && controller.position.haveDimensions) {
          // How far the page is from the middle: -1 to the left, 1 to the right.
          final away = (position.index - (controller.page ?? position.index.toDouble())).clamp(-1.0, 1.0);
          dx = away * controller.position.viewportDimension * _step * depth;
        }
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}
