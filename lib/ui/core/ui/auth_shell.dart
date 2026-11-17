import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/colors.dart';
import '../themes/theme.dart';
import 'mascot.dart';

/// Sign-in and onboarding frame: peach background, wordmark, a mascot that
/// reacts to the step, and a white card holding the step's content.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.mood, required this.stepKey, required this.children});

  final MascotMood mood;
  final Object stepKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PnColors.peach,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PICNOTE.', style: PnText.wordmark.copyWith(fontSize: 28, letterSpacing: 0.4)),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 360),
                              switchInCurve: Curves.easeOutBack,
                              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                              child: Face(mood, key: ValueKey(mood), height: 72),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: PnColors.snow,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 36 + MediaQuery.paddingOf(context).bottom),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(stepKey),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(height: 18), child],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step heading: prompt and optional explanation.
class StepHeader extends StatelessWidget {
  const StepHeader(this.prompt, {super.key, this.sub});

  final String prompt;
  final Widget? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt, style: PnText.prompt),
        if (sub != null) ...[const SizedBox(height: 8), DefaultTextStyle(style: PnText.sub, child: sub!)],
      ],
    );
  }
}

enum CodeBoxesState { idle, loading, error, locked }

/// Six boxes over a hidden field. Digits only, or letters and digits without
/// the look-alikes 0, O, 1 and I when [alphanumeric].
class CodeBoxes extends StatefulWidget {
  const CodeBoxes({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.state = CodeBoxesState.idle,
    this.alphanumeric = false,
    this.autofocus = true,
  });

  static const inviteAlphabet = 'ABCDEFGHJKLMNPRSTUVWXYZ23456789';

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final CodeBoxesState state;
  final bool alphanumeric;
  final bool autofocus;

  @override
  State<CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<CodeBoxes> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  final _menu = ContextMenuController();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(CodeBoxes old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _menu.remove();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// A long press offers Paste, for a code copied from the e-mail.
  void _showPasteMenu(Offset at) {
    Feedback.forLongPress(context);
    _focus.requestFocus();
    _menu.show(
      context: context,
      contextMenuBuilder: (_) => TapRegion(
        onTapOutside: (_) => _menu.remove(),
        child: AdaptiveTextSelectionToolbar.buttonItems(
          anchors: TextSelectionToolbarAnchors(primaryAnchor: at),
          buttonItems: [
            ContextMenuButtonItem(
              type: ContextMenuButtonType.paste,
              onPressed: () {
                _menu.remove();
                _paste();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final v = _clean(data?.text ?? '');
    if (!mounted || v.isEmpty) return;
    _controller.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
    widget.onChanged(v);
  }

  /// The code in [raw]. Pasted over what was there, or with words around
  /// it ("Ton code : 123456"), a run of exactly 6 characters wins.
  String _clean(String raw) {
    final text = widget.alphanumeric ? raw.toUpperCase() : raw;
    final char = widget.alphanumeric ? '[${CodeBoxes.inviteAlphabet}]' : '[0-9]';
    final chars = RegExp(char).allMatches(text).map((m) => m[0]!).toList();
    if (chars.length <= 6) return chars.join();
    final exact = RegExp('(?<!$char)$char{6}(?!$char)').firstMatch(text);
    return exact?[0] ?? chars.take(6).join();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final error = s == CodeBoxesState.error;
    final locked = s == CodeBoxesState.locked;
    final busy = s == CodeBoxesState.loading;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _menu.remove();
        _focus.requestFocus();
      },
      onLongPressStart: busy || locked ? null : (d) => _showPasteMenu(d.globalPosition),
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _box(i, error: error, locked: locked, busy: busy),
                ),
              ],
            ],
          ),
          // The hidden field takes keyboard input and one-time-code autofill;
          // taps and long presses go to the boxes, which own the Paste menu.
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  readOnly: busy || locked,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  keyboardType: widget.alphanumeric ? TextInputType.visiblePassword : TextInputType.number,
                  textCapitalization: widget.alphanumeric ? TextCapitalization.characters : TextCapitalization.none,
                  autofillHints: widget.alphanumeric ? null : const [AutofillHints.oneTimeCode],
                  decoration: InputDecoration(border: InputBorder.none, labelText: widget.label),
                  onChanged: (raw) {
                    // A whole code pasted after a started one replaces it.
                    final added = raw.startsWith(widget.value) ? raw.substring(widget.value.length) : '';
                    final pasted = _clean(added);
                    final v = pasted.length == 6 ? pasted : _clean(raw);
                    if (v != raw) {
                      _controller.value = TextEditingValue(
                        text: v,
                        selection: TextSelection.collapsed(offset: v.length),
                      );
                    }
                    widget.onChanged(v);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(int i, {required bool error, required bool locked, required bool busy}) {
    final ch = i < widget.value.length ? widget.value[i] : null;
    final cursor = _focus.hasFocus && !busy && !error && !locked && i == widget.value.length;
    final border = error
        ? PnColors.terraDark
        : locked
        ? PnColors.line
        : (ch != null || cursor)
        ? PnColors.terra
        : PnColors.peach;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: error ? PnColors.peach : (locked ? PnColors.cream : Colors.transparent),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
      child: ch != null
          ? _Blinking(
              enabled: busy,
              delay: i * 120,
              child: Text(
                ch,
                style: TextStyle(
                  fontFamily: PnFonts.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: error ? PnColors.terraDark : (locked ? PnColors.muted : PnColors.ink),
                ),
              ),
            )
          : cursor
          ? _Blinking(enabled: true, child: Container(width: 2, height: 22, color: PnColors.terra))
          : null,
    );
  }
}

class _Blinking extends StatefulWidget {
  const _Blinking({required this.enabled, required this.child, this.delay = 0});

  final bool enabled;
  final Widget child;
  final int delay;

  @override
  State<_Blinking> createState() => _BlinkingState();
}

class _BlinkingState extends State<_Blinking> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Blinking old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.enabled && !_c.isAnimating) {
      _c.value = (widget.delay % 1000) / 1000;
      _c.repeat();
    } else if (!widget.enabled) {
      _c.stop();
      _c.value = 0.5;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // 0.25 → 1 → 0.25, like the prototype's pnBlink.
        final t = widget.enabled ? 0.25 + 0.75 * (1 - (2 * _c.value - 1).abs()) : 1.0;
        return Opacity(opacity: t, child: child);
      },
      child: widget.child,
    );
  }
}
