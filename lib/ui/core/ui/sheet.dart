import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/theme.dart';
import 'buttons.dart';

/// Opens [sheet] (usually a [PnSheet]) from the bottom, phone-width on tablets.
/// It opens on the root navigator so it covers the floating bottom bar.
///
/// An [editing] sheet (with fields to fill in) can't be swiped away, so a
/// stray swipe doesn't lose what was typed; a tap outside still closes it.
Future<T?> showPnSheet<T>(BuildContext context, Widget sheet, {bool editing = false}) async {
  openSheets.value++;
  try {
    return await showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      enableDrag: !editing,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: PnColors.snow,
      barrierColor: PnColors.scrim,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _SheetDrag(enabled: !editing, child: sheet),
    );
  } finally {
    openSheets.value--;
  }
}

/// How many [showPnSheet] sheets are open: the bottom bar hides meanwhile.
final openSheets = ValueNotifier<int>(0);

/// Whether the open sheet can be swiped away (and so shows a grab handle).
class _SheetDrag extends InheritedWidget {
  const _SheetDrag({required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_SheetDrag>()?.enabled ?? true;

  @override
  bool updateShouldNotify(_SheetDrag oldWidget) => enabled != oldWidget.enabled;
}

/// Sheet layout: grab handle, title, optional subtitle, scrolling body,
/// optional fixed footer. The same rhythm for every sheet: title, 8 px,
/// subtitle, 20 px, content; 32 px at the bottom (16 above a footer, 32
/// under it). An explanation belongs in [subtitle], not in the content.
class PnSheet extends StatelessWidget {
  const PnSheet({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.titleColor = PnColors.terra,
    this.footer,
    this.gap = 18,
  });

  final String title;
  final String? subtitle;
  final Color titleColor;
  final List<Widget> children;
  final Widget? footer;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // Above the keyboard when it is up, else above the system navigation bar.
    final bottom = keyboard > 0 ? keyboard : MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_SheetDrag.of(context)) ...[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: PnColors.line, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else
                  const SizedBox(height: 10),
                Text(title, style: PnText.sheetTitle.copyWith(color: titleColor, height: 1.15)),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: PnText.sub.copyWith(height: 1.4)),
                ],
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, footer != null ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, child) in children.indexed) ...[if (i > 0) SizedBox(height: gap), child],
                ],
              ),
            ),
          ),
          if (footer != null) Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, keyboard > 0 ? 12 : 32), child: footer),
        ],
      ),
    );
  }
}

/// Confirmation before something hard to undo: bullet points, an optional
/// highlighted line, a red action and "Cancel". Pops `true` when confirmed.
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.title,
    required this.lines,
    required this.confirmLabel,
    required this.cancelLabel,
    this.highlight,
    this.danger = true,
  });

  final String title;
  final List<String> lines;
  final String confirmLabel;
  final String cancelLabel;
  final String? highlight;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return PnSheet(
      title: title,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PnButton(
            label: confirmLabel,
            kind: danger ? PnButtonKind.danger : PnButtonKind.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 6),
          PnButton(label: cancelLabel, kind: PnButtonKind.tertiary, onPressed: () => Navigator.pop(context, false)),
        ],
      ),
      gap: 12,
      children: [
        for (final line in lines)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 8, right: 10),
                decoration: const BoxDecoration(color: PnColors.terra, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(line, style: const TextStyle(fontSize: 15, height: 1.4, color: PnColors.ink)),
              ),
            ],
          ),
        if (highlight != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: PnColors.roseBg, borderRadius: BorderRadius.circular(16)),
            child: Text(
              highlight!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.35, color: PnColors.danger),
            ),
          ),
      ],
    );
  }
}
