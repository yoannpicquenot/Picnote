import 'package:flutter/material.dart';

/// Floats [child] by the widget that [link] targets (and [anchorKey] marks):
/// below it when it fits on screen, else above it. It follows the anchor
/// when it moves. A tap anywhere else calls [onDismiss].
///
/// Use as the `overlayChildBuilder` result of an [OverlayPortal].
class AnchoredPopover extends StatefulWidget {
  const AnchoredPopover({
    super.key,
    required this.link,
    required this.anchorKey,
    required this.onDismiss,
    required this.child,
    this.dx = 0,
    this.gap = 8,
  });

  final LayerLink link;
  final GlobalKey anchorKey;
  final VoidCallback onDismiss;
  final Widget child;

  /// Horizontal shift from the anchor's left edge.
  final double dx;

  /// Space between the anchor and the popover.
  final double gap;

  @override
  State<AnchoredPopover> createState() => _AnchoredPopoverState();
}

class _AnchoredPopoverState extends State<AnchoredPopover> {
  final _childKey = GlobalKey();
  bool _above = false;

  /// Hidden until measured, so it never shows on the wrong side.
  bool _placed = false;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _place());
    final media = MediaQuery.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onDismiss),
        ),
        CompositedTransformFollower(
          link: widget.link,
          targetAnchor: _above ? Alignment.topLeft : Alignment.bottomLeft,
          followerAnchor: _above ? Alignment.bottomLeft : Alignment.topLeft,
          offset: Offset(widget.dx, _above ? -widget.gap : widget.gap),
          child: Opacity(
            opacity: _placed ? 1 : 0,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_placed),
              tween: Tween(begin: media.disableAnimations || !_placed ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.94 + 0.06 * t,
                  alignment: _above ? Alignment.bottomLeft : Alignment.topLeft,
                  child: child,
                ),
              ),
              child: Material(key: _childKey, type: MaterialType.transparency, child: widget.child),
            ),
          ),
        ),
      ],
    );
  }

  /// Picks the side with room for the popover, the one with more room if
  /// neither has enough.
  void _place() {
    if (!mounted) return;
    final anchor = widget.anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final popover = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchor == null || popover == null || !anchor.hasSize || !popover.hasSize) return;
    final media = MediaQuery.of(context);
    final top = anchor.localToGlobal(Offset.zero).dy;
    final bottom = top + anchor.size.height;
    final height = popover.size.height + widget.gap;
    final roomBelow = media.size.height - media.viewInsets.bottom - media.padding.bottom - bottom;
    final roomAbove = top - media.padding.top;
    final above = height > roomBelow && roomAbove > roomBelow;
    if (above != _above || !_placed) {
      setState(() {
        _above = above;
        _placed = true;
      });
    }
  }
}
