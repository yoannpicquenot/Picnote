import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB94040)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final googleUser = await GoogleSignIn(
      serverClientId: '1055647633275-o9cf4k3731hma4pm5o44bfajmvqj1d2d.apps.googleusercontent.com',
    ).signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    await GoogleSignIn().disconnect();
    await user.delete();

    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Account deleted'),
        content: const Text('Your account has been permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      size: 28,
                      color: isDark
                          ? AppColors.beigeCard.withOpacity(0.7)
                          : AppColors.brownDark.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Parameters',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Account section
                  _SectionLabel(label: 'Account', isDark: isDark),
                  const SizedBox(height: 10),

                  _SettingsCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Email',
                          value: user?.email ?? '—',
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _InfoRow(
                          label: 'UID',
                          value: _shortUid(user?.uid),
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _ActionRow(
                          label: 'Delete account',
                          icon: Icons.delete_forever_rounded,
                          color: const Color(0xFFB94040),
                          isDark: isDark,
                          onTap: () => _deleteAccount(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Danger zone
                  _SectionLabel(label: 'Session', isDark: isDark),
                  const SizedBox(height: 10),

                  _SettingsCard(
                    isDark: isDark,
                    child: _ActionRow(
                      label: 'Sign out',
                      icon: Icons.logout_rounded,
                      color: const Color(0xFFB94040),
                      isDark: isDark,
                      onTap: () => _signOut(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortUid(String? uid) {
    if (uid == null) return '—';
    return '${uid.substring(0, 8)}…';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.beigeCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.beigeCard : AppColors.brownDark,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark
          ? AppColors.white.withOpacity(0.06)
          : AppColors.brownDark.withOpacity(0.08),
    );
  }
}
