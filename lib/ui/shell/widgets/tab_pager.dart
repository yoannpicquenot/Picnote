import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../core/themes/colors.dart';
import '../../core/ui/home_header.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/tab_stagger.dart';

/// Where the tabs' pager stands: 0 on Home, 1 on Lists, 2 on Notes, in
/// between while swiping. The bottom bar's tabs follow it.
final tabsPosition = ValueNotifier<double>(0);

/// Home, Lists and Notes side by side: a swipe drags them along with the
/// finger, and they snap into place when it lets go. [onSettled] tells
/// which page the swipe ended on; [index] (from the route) moves the pages
/// when a tab is picked another way. Every page is kept, so each one keeps
/// its scroll position.
///
/// [header] and [backdrop] are shared by the pages and do not swipe. The
/// header stays put at the top; the backdrop follows the page's vertical
/// scroll, blending two pages' scroll while a swipe is under way. Each page
/// leaves room for the header with [HomeHeaderGap].
class TabPager extends StatefulWidget {
  const TabPager({
    super.key,
    required this.index,
    required this.pages,
    required this.onSettled,
    required this.header,
    required this.backdrop,
  });

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onSettled;

  /// Drawn over the pages, at the top of the content column.
  final Widget header;

  /// Drawn behind the pages, from the same place as [header].
  final Widget backdrop;

  @override
  State<TabPager> createState() => _TabPagerState();
}

class _TabPagerState extends State<TabPager> {
  late final _controller = PageController(initialPage: widget.index)..addListener(_moved);

  @override
  void initState() {
    super.initState();
    _publish(widget.index.toDouble());
  }

  void _moved() {
    if (_controller.position.haveDimensions) _publish(_controller.page ?? widget.index.toDouble());
  }

  /// Tells the bottom bar where the pager is: after the frame when that
  /// comes while building or laying out (the page opening, the screen
  /// turning), where the bar may not be rebuilt.
  void _publish(double page) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => tabsPosition.value = page);
    } else {
      tabsPosition.value = page;
    }
  }

  /// Each page's vertical scroll.
  late final _scrolls = List<double>.filled(widget.pages.length, 0);
  final _scrolled = ValueNotifier<int>(0);

  /// Each page's own vertical scroll position, once it has one.
  late final _positions = List<ScrollPosition?>.filled(widget.pages.length, null);

  double _headerHeight = 0;

  /// A drag that started on the header, handed to the pager or the page.
  Drag? _drag;

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
        duration: const Duration(milliseconds: 280),
        curve: const Cubic(0.2, 0.8, 0.3, 1),
      );
    }
  }

  @override
  void dispose() {
    _drag?.cancel();
    _controller.dispose();
    _scrolled.dispose();
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

  /// Page [i]'s own vertical scroll, not a field inside it.
  bool _onPageScroll(int i, Notification n) {
    final (depth, metrics, context) = switch (n) {
      ScrollNotification() => (n.depth, n.metrics, n.context),
      ScrollMetricsNotification() => (n.depth, n.metrics, n.context),
      _ => (-1, null, null),
    };
    if (depth != 0 || metrics == null || metrics.axis != Axis.vertical) return false;
    if (context != null) _positions[i] = Scrollable.maybeOf(context)?.position;
    if (_scrolls[i] != metrics.pixels) {
      _scrolls[i] = metrics.pixels;
      _scrolled.value++;
    }
    return false;
  }

  int get _shown => (_controller.hasClients ? _controller.page?.round() : null) ?? widget.index;

  /// The header is drawn over the pages, so drags that start on it are
  /// passed on: sideways to the pager, up and down to the shown page.
  void _startDrag(DragStartDetails details, ScrollPosition? position) {
    _drag?.cancel();
    _drag = position?.drag(details, () => _drag = null);
  }

  Widget _passDrags(Widget child) => GestureDetector(
    onHorizontalDragStart: (d) => _startDrag(d, _controller.hasClients ? _controller.position : null),
    onVerticalDragStart: (d) => _startDrag(d, _positions[_shown]),
    onHorizontalDragUpdate: (d) => _drag?.update(d),
    onVerticalDragUpdate: (d) => _drag?.update(d),
    onHorizontalDragEnd: (d) => _drag?.end(d),
    onVerticalDragEnd: (d) => _drag?.end(d),
    onHorizontalDragCancel: () => _drag?.cancel(),
    onVerticalDragCancel: () => _drag?.cancel(),
    child: child,
  );

  /// The scroll the header follows: the shown page's, or a mix of both
  /// pages' while swiping.
  double get _scroll {
    final page = _controller.hasClients && _controller.position.haveDimensions
        ? _controller.page ?? widget.index.toDouble()
        : widget.index.toDouble();
    final clamped = page.clamp(0, _scrolls.length - 1).toDouble();
    final lo = clamped.floor();
    final hi = clamped.ceil();
    return _scrolls[lo] + (_scrolls[hi] - _scrolls[lo]) * (clamped - lo);
  }

  void _onHeaderSize(Size size) {
    if (size.height != _headerHeight) setState(() => _headerHeight = size.height);
  }

  /// [child] where the pages start their content, moved up by their scroll.
  Widget _follow(Widget child) => AnimatedBuilder(
    animation: Listenable.merge([_controller, _scrolled]),
    builder: (context, child) => Transform.translate(offset: Offset(0, -_scroll), child: child),
    child: Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + homeHeaderTop),
      child: ContentWidth(child: child),
    ),
  );

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(left: 0, right: 0, top: 0, child: IgnorePointer(child: _follow(widget.backdrop))),
      Positioned.fill(
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: HomeHeaderSpace(
            height: _headerHeight,
            child: PageView(
              controller: _controller,
              children: [
                for (final (i, page) in widget.pages.indexed)
                  NotificationListener<Notification>(
                    onNotification: (n) => _onPageScroll(i, n),
                    child: TabPagePosition(
                      controller: _controller,
                      index: i,
                      child: _KeepAlive(child: page),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      // Fixed: neither swiping nor scrolling moves it. Once the page is
      // scrolled, it passes under it, fading out on a cream backdrop that
      // shows only then.
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: _passDrags(
          Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_controller, _scrolled]),
                    builder: (context, child) => AnimatedOpacity(
                      opacity: _scroll > 4 ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: child,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.82, 1],
                          colors: [PnColors.cream, PnColors.cream, PnColors.cream.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + homeHeaderTop, bottom: 14),
                child: ContentWidth(
                  child: _SizeReporter(onSize: _onHeaderSize, child: widget.header),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
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

/// Tells [onSize] the size of [child] after each layout that changes it.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter renderObject) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    final reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
  }
}
