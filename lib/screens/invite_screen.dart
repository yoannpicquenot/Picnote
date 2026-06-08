import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/picnote_face.dart';
import '../models/app_state.dart';
import '../services/auth_service.dart';
import '../services/pair_service.dart';

class InviteScreen extends StatefulWidget {
  final String inviterEmail;
  final String inviteId;
  final String inviteeEmail;
  final String emailLink;

  const InviteScreen({
    super.key,
    required this.inviterEmail,
    required this.inviteId,
    required this.inviteeEmail,
    required this.emailLink,
  });

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _afterPairing() async {
    await context.read<AppState>().reload();
    // _AuthRouter stream handles navigation
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred == null) { setState(() => _loading = false); return; }
      await PairService.acceptInvite(widget.inviteId, cred.user!.uid);
      await _afterPairing();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _signInWithEmailLink() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailLink(
        email: widget.inviteeEmail,
        emailLink: widget.emailLink,
      );
      await AuthService.ensureUserDoc(cred.user!);
      await PairService.acceptInvite(widget.inviteId, cred.user!.uid);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_email');
      await _afterPairing();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Center(child: PicnoteFace(size: 140)),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          Container(
            width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You've been invited",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.inviterEmail} wants to share their space with you.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 12),
                  ],

                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _AuthButton(
                      label: 'Continue with email',
                      icon: Icons.mail_outline,
                      onTap: _signInWithEmailLink,
                    ),
                    const SizedBox(height: 12),
                    const _Divider(),
                    const SizedBox(height: 12),
                    _GoogleButton(onTap: _signInWithGoogle),
                  ],
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
  final IconData icon;
  final VoidCallback onTap;

  const _AuthButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkCardLight : AppColors.charcoal,
          foregroundColor: isDark ? AppColors.beigeCard : AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1);
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleIcon(),
            SizedBox(width: 12),
            Text('Continue with Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                  color: Color(0xFF3C4043), fontFamily: 'Roboto')),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20, height: 20,
    child: CustomPaint(painter: _GoogleIconPainter()),
  );
}

class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    void arc(Color c, double start, double sweep) {
      canvas.drawArc(
        Rect.fromLTWH(0, 0, w, w).deflate(w * 0.11),
        start * 3.14159 / 180, sweep * 3.14159 / 180, false,
        Paint()..color = c..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.22..strokeCap = StrokeCap.butt,
      );
    }
    arc(const Color(0xFF4285F4), -225, -90);
    arc(const Color(0xFFEA4335), -225, 90);
    arc(const Color(0xFFFBBC05), -135, 90);
    arc(const Color(0xFF34A853), -45, 90);
    canvas.drawRect(Rect.fromLTWH(w * 0.5, w * 0.38, w * 0.5, w * 0.24),
        Paint()..color = Colors.white);
    arc(const Color(0xFF4285F4), -10, -80);
  }
  @override
  bool shouldRepaint(_) => false;
}
