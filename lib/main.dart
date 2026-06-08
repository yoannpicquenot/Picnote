import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'models/app_state.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/invite_screen.dart';
import 'services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PicnoteApp(),
    ),
  );
}

class PicnoteApp extends StatefulWidget {
  const PicnoteApp({super.key});

  @override
  State<PicnoteApp> createState() => _PicnoteAppState();
}

class _PicnoteAppState extends State<PicnoteApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _listenForIncomingLinks();
  }

  void _listenForIncomingLinks() {
    AppLinks().uriLinkStream.listen((uri) async {
      final link = uri.toString();
      if (!FirebaseAuth.instance.isSignInWithEmailLink(link)) return;

      final continueUrlRaw = Uri.parse(link).queryParameters['continueUrl'];
      String? inviteId;
      String? inviterEmail;
      String? inviteeEmail;

      if (continueUrlRaw != null) {
        final continueUri = Uri.parse(continueUrlRaw);
        inviteId = continueUri.queryParameters['inviteId'];
        inviterEmail = continueUri.queryParameters['inviterEmail'];
      }

      if (inviteId != null) {
        // Invite link — fetch invite data and show invite screen
        try {
          final snap = await FirebaseFirestore.instance
              .collection('invites')
              .doc(inviteId)
              .get();
          inviteeEmail = snap.data()?['toEmail'] as String?;
          inviterEmail ??= snap.data()?['fromEmail'] as String? ?? '';
        } catch (_) {}

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => InviteScreen(
              inviterEmail: inviterEmail ?? '',
              inviteId: inviteId!,
              inviteeEmail: inviteeEmail ?? '',
              emailLink: link,
            ),
          ),
          (_) => false,
        );
      } else {
        // Regular sign-in link
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('pending_email');
        if (email == null) return;
        try {
          final cred = await FirebaseAuth.instance.signInWithEmailLink(
            email: email,
            emailLink: link,
          );
          await AuthService.ensureUserDoc(cred.user!);
          await prefs.remove('pending_email');
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PICNOTE.',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: const _AuthRouter(),
    );
  }
}

class _AuthRouter extends StatelessWidget {
  const _AuthRouter();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final user = snapshot.data;
        if (user == null) return const WelcomeScreen();

        return FutureBuilder<String>(
          future: AuthService.getRoute(user.uid),
          builder: (context, snap) {
            if (!snap.hasData) return const _Splash();
            return switch (snap.data!) {
              'paired'  => const HomeScreen(),
              'waiting' => const HomeScreen(),
              _         => const OnboardingScreen(),
            };
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
