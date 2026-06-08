import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/picnote_face.dart';
import '../models/app_state.dart';
import '../services/pair_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;
  String _partnerEmail = '';

  @override
  void initState() {
    super.initState();
    _checkExistingInvite();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkExistingInvite() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final email = await PairService.getPendingInviteEmail(uid);
    if (email != null && mounted) {
      setState(() { _partnerEmail = email; _sent = true; });
    }
  }

  Future<void> _sendInvite() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;

    setState(() { _loading = true; _error = null; });
    try {
      final pairedImmediately = await PairService.sendInvite(email);
      await context.read<AppState>().reload();

      if (pairedImmediately && mounted) {
        // Partner already had an account — go straight to home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        setState(() { _partnerEmail = email; _sent = true; _loading = false; });
      }
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _sent
                    ? _InviteSentState(
                        key: const ValueKey('sent'),
                        partnerEmail: _partnerEmail,
                        onResend: () => setState(() { _sent = false; _controller.clear(); }),
                      )
                    : _InviteInputState(
                        key: const ValueKey('input'),
                        controller: _controller,
                        loading: _loading,
                        error: _error,
                        onSend: _sendInvite,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteInputState extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onSend;

  const _InviteInputState({
    super.key,
    required this.controller,
    required this.loading,
    required this.error,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Who's your partner?", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          "We'll send them an invite to join your shared space.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        AutofillGroup(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: isDark ? AppColors.beigeCard : AppColors.brownDark),
            decoration: InputDecoration(
              hintText: "partner@email.com",
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.beigeCard.withOpacity(0.35)
                    : AppColors.brownDark.withOpacity(0.35),
              ),
              prefixIcon: Icon(Icons.favorite_outline,
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
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkCardLight : AppColors.charcoal,
              foregroundColor: isDark ? AppColors.beigeCard : AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send invite',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _InviteSentState extends StatelessWidget {
  final String partnerEmail;
  final VoidCallback onResend;

  const _InviteSentState({
    super.key,
    required this.partnerEmail,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite sent!', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'We sent an invite to $partnerEmail.\nThey\'ll join your space once they accept.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkCardLight : AppColors.charcoal,
              foregroundColor: isDark ? AppColors.beigeCard : AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Go to home',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onResend,
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
