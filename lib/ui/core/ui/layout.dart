import 'package:flutter/material.dart';

/// Room left at the bottom of scrolling screens for the floating bar.
const bottomBarClearance = 110.0;

/// Whether the floating bottom bar is showing (it hides inside a list, a
/// note…), so that toasts sit above it or at the bottom of the screen.
class BottomBarVisibility extends InheritedWidget {
  const BottomBarVisibility({super.key, required this.visible, required super.child});

  final bool visible;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BottomBarVisibility>()?.visible ?? false;

  @override
  bool updateShouldNotify(BottomBarVisibility oldWidget) => visible != oldWidget.visible;
}

/// Phone layout on tablets: content centered on 600 px at most, while
/// colored backgrounds stay full width.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Top, not Center: inside a screen-tall box, Center would also center
    // the content vertically.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600 + padding.horizontal),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Vertical list of [children] separated by [gap].
class Gap extends StatelessWidget {
  const Gap({
    super.key,
    required this.gap,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final double gap;
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, child) in children.indexed) ...[if (i > 0) SizedBox(height: gap), child],
      ],
    );
  }
}

/// Cards two by two, both cards of a row as tall as each other (the taller
/// one sets the height). With [firstWide], the first card takes a whole row.
class PairedGrid extends StatelessWidget {
  const PairedGrid({super.key, required this.children, this.spacing = 10, this.firstWide = false});

  final List<Widget> children;
  final double spacing;
  final bool firstWide;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[];
    var i = 0;
    if (firstWide && children.isNotEmpty) {
      rows.add([children.first]);
      i = 1;
    }
    for (; i < children.length; i += 2) {
      rows.add(children.sublist(i, i + 2 > children.length ? children.length : i + 2));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (r, row) in rows.indexed) ...[
          if (r > 0) SizedBox(height: spacing),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: row.first),
                if (row.length > 1) ...[SizedBox(width: spacing), Expanded(child: row[1])],
                // A lone card keeps half the width, unless it is the wide one.
                if (row.length == 1 && !(firstWide && r == 0)) ...[SizedBox(width: spacing), const Spacer()],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Closes the keyboard and waits until it is gone (half a second at most).
///
/// Call before leaving a page that opens out of a card: the screen growing
/// back while the card flies stretched it out of shape.
Future<void> closeKeyboard(BuildContext context) async {
  if (MediaQuery.viewInsetsOf(context).bottom == 0) return;
  FocusManager.instance.primaryFocus?.unfocus();
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    if (!context.mounted || MediaQuery.viewInsetsOf(context).bottom == 0) return;
  }
}
