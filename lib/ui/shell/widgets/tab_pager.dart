import 'package:flutter/material.dart';

/// Lists and Notes side by side: a swipe drags both along with the
/// finger, and they snap into place when it lets go. [onSettled] tells
/// which page the swipe ended on; [index] (from the route) moves the pages
/// when a tab is picked another way. Both pages are kept, so each one
/// keeps its scroll position.
class TabPager extends StatefulWidget {
  const TabPager({super.key, required this.index, required this.pages, required this.onSettled});

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onSettled;

  @override
  State<TabPager> createState() => _TabPagerState();
}

class _TabPagerState extends State<TabPager> {
  late final _controller = PageController(initialPage: widget.index);

  @override
  void didUpdateWidget(TabPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == oldWidget.index || !_controller.hasClients) return;
    if (_controller.page?.round() == widget.index) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(widget.index);
    } else {
      _controller.animateToPage(
        widget.index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    // The pager's own scroll, once it comes to rest.
    if (n.depth == 0 && n is ScrollEndNotification) {
      final page = _controller.page?.round();
      if (page != null && page != widget.index) widget.onSettled(page);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
    onNotification: _onScroll,
    child: PageView(
      controller: _controller,
      children: [for (final page in widget.pages) _KeepAlive(child: page)],
    ),
  );
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
