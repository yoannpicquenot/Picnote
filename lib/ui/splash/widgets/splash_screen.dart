import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/mascot.dart';

/// Launch screen: the mascots cycle while loading. Tap to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone, this.duration = const Duration(milliseconds: 2900)});

  final VoidCallback onDone;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _moods = [MascotMood.cheerful, MascotMood.happy, MascotMood.joy, MascotMood.wink, MascotMood.love];

  int _i = 0;
  late final Timer _cycle;
  late final Timer _done;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _cycle = Timer.periodic(const Duration(milliseconds: 480), (_) => setState(() => _i = (_i + 1) % _moods.length));
    _done = Timer(widget.duration, _leave);
  }

  void _leave() {
    if (_left) return;
    _left = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _cycle.cancel();
    _done.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _leave,
      child: Scaffold(
        backgroundColor: PnColors.terra,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: Mascot(
                  mood: _moods[_i],
                  color: PnColors.peach,
                  highlight: PnColors.terra,
                  height: 78,
                  alignment: Alignment.center,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'PICNOTE.',
                style: PnText.wordmark.copyWith(fontSize: 30, letterSpacing: 0.6, color: PnColors.peach),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
