import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/task_list.dart';
import '../../core/ui/layout.dart';

/// Builds the card of [list], [index]-th on home. [onTap] opens it, or
/// stops arranging. [rise] is false for the copy under the finger.
typedef PinnedCardBuilder = Widget Function(TaskList list, int index, VoidCallback onTap, {bool rise});

/// Home's pinned lists, two by two. A long press on a card makes them all
/// wiggle: the card under the finger, then any other, can be dragged to
/// another place in the grid, the others making room. A tap anywhere stops.
class PinnedGrid extends StatefulWidget {
  const PinnedGrid({
    super.key,
    required this.lists,
    required this.cardBuilder,
    required this.onOpen,
    required this.onReorder,
  });

  final List<TaskList> lists;
  final PinnedCardBuilder cardBuilder;
  final ValueChanged<TaskList> onOpen;

  /// The ids of [lists], in their new order.
  final ValueChanged<List<String>> onReorder;

  @override
  State<PinnedGrid> createState() => _PinnedGridState();
}

class _PinnedGridState extends State<PinnedGrid> with SingleTickerProviderStateMixin {
  bool _arranging = false;

  /// While a card is dragged: where each one stands now.
  List<String>? _order;

  /// Each card keeps its state (and its drag) as it moves to another row.
  final _keys = <String, GlobalKey>{};

  /// The size of the card picked up, for its copy under the finger.
  Size? _liftedSize;

  late final _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  List<String> get _ids => _order ?? [for (final l in widget.lists) l.id];

  void _start() {
    if (!_arranging) {
      _arranging = true;
      if (!MediaQuery.disableAnimationsOf(context)) _wiggle.repeat();
    }
    setState(() => _order = _ids);
  }

  void _stop() {
    _wiggle.stop();
    _wiggle.value = 0;
    setState(() => _arranging = false);
  }

  /// The dragged card [id] takes the place of the card at [index].
  void _moveTo(String id, int index) {
    final order = _order;
    if (order == null) return;
    final from = order.indexOf(id);
    if (from < 0 || from == index) return;
    setState(() => order.insert(index, order.removeAt(from)));
  }

  void _drop() {
    final order = _order;
    if (order == null) return;
    final before = [for (final l in widget.lists) l.id];
    // Saved first: the lists come back in their new order, with no jump.
    if (order.join() != before.join()) widget.onReorder(order);
    setState(() => _order = null);
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final l in widget.lists) l.id: l};
    final shown = [for (final id in _ids) ?byId[id]];
    return TapRegion(
      onTapOutside: _arranging ? (_) => _stop() : null,
      child: PairedGrid(children: [for (final (i, list) in shown.indexed) _slot(list, i)]),
    );
  }

  Widget _slot(TaskList list, int index) {
    final key = _keys.putIfAbsent(list.id, GlobalKey.new);
    final card = widget.cardBuilder(list, index, _arranging ? _stop : () => widget.onOpen(list));
    return KeyedSubtree(
      key: key,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          _moveTo(details.data, index);
          return true;
        },
        builder: (context, _, _) => LongPressDraggable<String>(
          data: list.id,
          // Once arranging, a short press is enough to pick a card up.
          delay: _arranging ? const Duration(milliseconds: 150) : kLongPressTimeout,
          hapticFeedbackOnStart: true,
          onDragStarted: () {
            _liftedSize = key.currentContext?.size;
            _start();
          },
          onDragEnd: (_) => _drop(),
          feedback: _Lifted(size: () => _liftedSize, child: widget.cardBuilder(list, index, () {}, rise: false)),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: _Wiggle(animation: _wiggle, index: index, child: card),
        ),
      ),
    );
  }
}

/// A card tilting back and forth, each a little out of step with the
/// others.
class _Wiggle extends StatelessWidget {
  const _Wiggle({required this.animation, required this.index, required this.child});

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Transform.rotate(
      angle: animation.isAnimating ? 0.012 * math.sin(2 * math.pi * (animation.value + index * 0.3)) : 0,
      child: child,
    ),
    child: child,
  );
}

/// The card under the finger: slightly bigger, raised by a shadow, the
/// size it had in the grid.
class _Lifted extends StatelessWidget {
  const _Lifted({required this.size, required this.child});

  /// Read once the drag has started.
  final Size? Function() size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = this.size();
    return Transform.scale(
      scale: 1.05,
      child: SizedBox(
        width: size?.width,
        height: size?.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Color(0x4D583727), blurRadius: 36, offset: Offset(0, 18), spreadRadius: -14),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
