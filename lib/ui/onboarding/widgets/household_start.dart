import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';

/// Step 06, "Your household.": create or join.
///
/// On the first visit, the title then the subtitle (large) fade in, a bar
/// fills for 4.5 s while the back button stays disabled, then the bar folds
/// away, the subtitle shrinks and the white panel grows to make room for the
/// two choices. Coming back, everything is already in place.
class HouseholdStart extends StatefulWidget {
  const HouseholdStart({
    super.key,
    required this.title,
    required this.sub,
    required this.choices,
    required this.backLabel,
    required this.onBack,
    required this.playIntro,
    required this.onIntroDone,
  });

  final String title;
  final String sub;
  final Widget choices;
  final String backLabel;
  final VoidCallback onBack;
  final bool playIntro;
  final VoidCallback onIntroDone;

  /// When the choices arrive.
  static const introLength = Duration(milliseconds: 5800);

  @override
  State<HouseholdStart> createState() => _HouseholdStartState();
}

class _HouseholdStartState extends State<HouseholdStart> with SingleTickerProviderStateMixin {
  static const _ease = Cubic(.22, 1, .36, 1);
  static const _ms = 5800.0;

  late final _intro = AnimationController(vsync: this, duration: HouseholdStart.introLength);
  late bool _ready = !widget.playIntro;

  @override
  void initState() {
    super.initState();
    if (_ready) {
      _intro.value = 1;
      return;
    }
    _intro.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _ready = true);
      widget.onIntroDone();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Fades in from 8 px below and a 6 px blur, for 1.4 s from [startMs].
  Animation<double> _soft(double startMs) => CurvedAnimation(
    parent: _intro,
    curve: Interval(startMs / _ms, (startMs + 1400) / _ms, curve: _ease),
  );

  Widget _softIn(Animation<double> t, Widget child) => AnimatedBuilder(
    animation: t,
    child: child,
    builder: (context, child) {
      final v = t.value;
      final blur = 6 * (1 - v);
      final moved = Transform.translate(
        offset: Offset(0, 8 * (1 - v)),
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      );
      return blur < 0.05
          ? moved
          : ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: moved,
            );
    },
  );

  @override
  Widget build(BuildContext context) {
    // Returning visits skip every transition.
    final animate = widget.playIntro;
    Duration d(int ms) => animate ? Duration(milliseconds: ms) : Duration.zero;
    final sub = _soft(1300);
    final fill = CurvedAnimation(parent: _intro, curve: const Interval(1300 / _ms, 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _softIn(_soft(200), Text(widget.title, style: PnText.prompt)),
        const SizedBox(height: 8),
        _softIn(
          sub,
          AnimatedDefaultTextStyle(
            duration: d(900),
            curve: _ease,
            style: _ready ? PnText.sub : PnText.sub.copyWith(fontSize: 22, height: 1.3),
            child: Text(widget.sub),
          ),
        ),
        // The loading bar, under the subtitle until the choices arrive.
        ClipRect(
          child: AnimatedAlign(
            duration: d(700),
            curve: _ease,
            alignment: Alignment.topCenter,
            heightFactor: _ready ? 0 : 1,
            child: AnimatedOpacity(
              duration: d(400),
              curve: Curves.easeOut,
              opacity: _ready ? 0 : 1,
              child: _softIn(
                sub,
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 4,
                      child: ColoredBox(
                        color: PnColors.peach,
                        child: AnimatedBuilder(
                          animation: fill,
                          builder: (context, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: fill.value,
                            child: const ColoredBox(color: PnColors.terra),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // The panel grows to make room, then the choices rise into it.
        ClipRect(
          child: AnimatedAlign(
            duration: d(900),
            curve: _ease,
            alignment: Alignment.topCenter,
            heightFactor: _ready ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_ready,
              child: ExcludeSemantics(
                excluding: !_ready,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _ready ? 1 : 0),
                  duration: d(1050),
                  builder: (context, t, child) {
                    // Opacity over 0.7 s after 0.3 s, rise over 0.8 s after 0.25 s.
                    final fade = const Interval(300 / 1050, 1000 / 1050, curve: Curves.easeOut).transform(t);
                    final rise = const Interval(250 / 1050, 1, curve: _ease).transform(t);
                    return Opacity(
                      opacity: fade,
                      child: Transform.translate(offset: Offset(0, 14 * (1 - rise)), child: child),
                    );
                  },
                  child: Padding(padding: const EdgeInsets.only(top: 18), child: widget.choices),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [BackSquare(label: widget.backLabel, onPressed: _ready ? widget.onBack : null)],
        ),
      ],
    );
  }
}
