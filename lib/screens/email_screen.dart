import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/picnote_face.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _controller = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;
  String _email = '';
  double _faceTurns = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFace);
  }

  void _updateFace() {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (text.isEmpty || cursor < 0) {
      setState(() => _faceTurns = 0.0);
      return;
    }
    // Map cursor position (0 → text.length) to a small tilt (-0.04 → +0.04 turns)
    final progress = cursor / text.length.clamp(1, text.length);
    setState(() => _faceTurns = (progress - 0.5) * 0.08);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFace);
    _controller.dispose();
    super.dispose();
  }

  bool get _isGmail => _email.toLowerCase().endsWith('@gmail.com');

  Future<void> _sendLink() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;

    setState(() { _loading = true; _error = null; });

    try {
      final settings = ActionCodeSettings(
        url: 'https://picnote-b8c02.firebaseapp.com/__/auth/links',
        handleCodeInApp: true,
        androidPackageName: 'com.example.picnote',
        androidInstallApp: true,
        androidMinimumVersion: '21',
      );
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: settings,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_email', email);
      setState(() { _email = email; _sent = true; _loading = false; });
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? 'Firebase error: ${e.code}'; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openGmail() async {
    // Android intent URI — opens Gmail app directly, bypasses browser
    final intentUri = Uri.parse(
      'intent:#Intent;action=android.intent.action.MAIN;category=android.intent.category.LAUNCHER;package=com.google.android.gm;end',
    );
    if (await canLaunchUrl(intentUri)) {
      await launchUrl(intentUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse('mailto:'), mode: LaunchMode.externalApplication);
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
                    Center(
                      child: AnimatedRotation(
                        turns: _sent ? 0.0 : _faceTurns,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: Hero(
                          tag: 'picnote_face',
                          child: PicnoteFace(size: 120),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom panel — animates between input and sent states
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            child: Container(
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _sent ? _SentState(
                    key: const ValueKey('sent'),
                    email: _email,
                    isGmail: _isGmail,
                    onOpenGmail: _openGmail,
                    onBack: () => setState(() { _sent = false; _controller.clear(); }),
                  ) : _InputState(
                    key: const ValueKey('input'),
                    controller: _controller,
                    loading: _loading,
                    error: _error,
                    onContinue: _sendLink,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputState extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _InputState({
    super.key,
    required this.controller,
    required this.loading,
    required this.error,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your email?",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        AutofillGroup(
          child: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          autofillHints: const [AutofillHints.email],
          style: TextStyle(color: isDark ? AppColors.beigeCard : AppColors.brownDark),
          decoration: InputDecoration(
            hintText: 'email@example.com',
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.beigeCard.withOpacity(0.35)
                  : AppColors.brownDark.withOpacity(0.35),
            ),
            prefixIcon: Icon(Icons.mail_outline,
                color: isDark ? AppColors.brownMedium : AppColors.brown, size: 20),
            filled: true,
            fillColor: isDark ? AppColors.darkCardLight : AppColors.beigeCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorText: error,
          ),
        ),
        ), // AutofillGroup
        const SizedBox(height: 16),
        Row(
          children: [
            _CircleButton(icon: Icons.arrow_back, onTap: onBack, isDark: isDark),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkCardLight : AppColors.charcoal,
                    foregroundColor: isDark ? AppColors.beigeCard : AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continue',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SentState extends StatelessWidget {
  final String email;
  final bool isGmail;
  final VoidCallback onOpenGmail;
  final VoidCallback onBack;

  const _SentState({
    super.key,
    required this.email,
    required this.isGmail,
    required this.onOpenGmail,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check your inbox',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'A sign-in link was sent to $email.\nTap it to open the app directly.\n\nNot seeing it? Check your spam folder.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (isGmail) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onOpenGmail,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open Gmail',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA4335),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextButton(
          onPressed: onBack,
          child: Text(
            'Use a different email',
            style: TextStyle(
              color: isDark ? AppColors.brownMedium : AppColors.brown,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _CircleButton({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppColors.brownMedium : AppColors.brown,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}
