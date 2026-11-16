import 'package:flutter/material.dart';

import '../../../domain/models/household.dart';
import '../../../l10n/app_localizations.dart';
import '../themes/colors.dart';
import 'avatar.dart';
import 'buttons.dart';
import 'layout.dart';

/// Dark message above the bottom bar, or at the bottom of the screen where
/// the bar is hidden. With [onUndo] it stays 10 s and shows a
/// countdown line; it can be swiped away either way.
///
/// [action] renames the "Undo" button; such a toast asks something, so its
/// text wraps instead of being cut. [aboveBar] overrides where it sits,
/// for callers above the bar's [BottomBarVisibility].
void showToast(
  BuildContext context,
  String text, {
  VoidCallback? onUndo,
  Member? from,
  String? action,
  bool? aboveBar,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final overBar = aboveBar ?? BottomBarVisibility.of(context);
  const duration = Duration(seconds: 10);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: onUndo != null ? duration : const Duration(seconds: 4),
      dismissDirection: DismissDirection.horizontal,
      margin: EdgeInsets.fromLTRB(16, 0, 16, overBar ? 92 : 12),
      padding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Stack(
          // Centered in its 52 px: the text sat at the top.
          alignment: Alignment.centerLeft,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  if (from != null) ...[Avatar.of(from, size: 22), const SizedBox(width: 8)],
                  Expanded(
                    child: action != null
                        ? Text(text, style: const TextStyle(height: 1.3))
                        : Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (action != null) const SizedBox(width: 12),
                  if (onUndo != null)
                    Pressable(
                      onTap: () {
                        messenger.hideCurrentSnackBar();
                        onUndo();
                      },
                      scale: 0.94,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          action ?? l10n.undo,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PnColors.night),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (onUndo != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: duration,
                  builder: (context, t, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: t,
                      child: Container(height: 3, color: PnColors.peach.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Message at the top of the screen, over any sheet: for news about what a
/// sheet shows (the invitation was sent again). Goes after 3 s.
void showTopToast(BuildContext context, String text) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopToast(text: text, onDone: entry.remove),
  );
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({required this.text, required this.onDone});

  final String text;
  final VoidCallback onDone;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    await _controller.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _controller, curve: const Cubic(0.2, 0.8, 0.3, 1));
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: t,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(t),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440, minHeight: 52),
                child: Material(
                  color: PnColors.night,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0x521C120D), blurRadius: 12, offset: Offset(3, 4))],
                    ),
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: PnColors.peach),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
