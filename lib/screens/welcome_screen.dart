import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/picnote_face.dart';
import '../services/auth_service.dart';
import 'email_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top area — logo + mascot
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PICNOTE.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 36,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Hero(
                        tag: 'picnote_face',
                        child: PicnoteFace(size: 160),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom panel
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : const Color(0xFFF0E0D0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AuthButton(
                    label: 'Continue with email',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmailScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  _GoogleButton(
                    onTap: () async {
                      try {
                        await AuthService.signInWithGoogle();
                        // _AuthRouter stream handles navigation automatically
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sign-in failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AuthButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkCardLight : AppColors.charcoal,
          foregroundColor: isDark ? AppColors.beigeCard : AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          side: const BorderSide(color: Color(0xFFDADCE0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleG(),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3C4043),
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Draw the four colored arcs of the Google "G"
    void drawArc(Color color, double start, double sweep, {bool filled = false}) {
      final paint = Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = w * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(w * 0.11),
        _rad(start),
        _rad(sweep),
        false,
        paint,
      );
    }

    drawArc(const Color(0xFF4285F4), -225, -90);  // blue — top
    drawArc(const Color(0xFFEA4335), -225, 90);   // red — top-right
    drawArc(const Color(0xFFFBBC05), -135, 90);   // yellow — bottom-right
    drawArc(const Color(0xFF34A853), -45, 90);    // green — bottom-left

    // White cutout for the "G" bar (horizontal right half)
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.5, h * 0.38, w * 0.5, h * 0.24), barPaint);

    // Redraw blue arc over the bar area
    drawArc(const Color(0xFF4285F4), -10, -80);
  }

  double _rad(double deg) => deg * 3.14159265 / 180;

  @override
  bool shouldRepaint(_) => false;
}
