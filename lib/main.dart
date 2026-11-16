import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'config/supabase.dart';
import 'l10n/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/themes/theme.dart';
import 'ui/splash/widgets/splash_screen.dart';

/// Runs against Supabase:
/// `flutter run --dart-define-from-file=env.json` (see env.example.json).
///
/// The splash shows at once and stays while the session and its data load,
/// instead of a blank screen.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(_Booting(repositories: supabaseRepositories()));
}

/// The splash until [repositories] are ready and it has played once (a tap
/// skips that), then the app, faded in.
class _Booting extends StatefulWidget {
  const _Booting({required this.repositories});

  final Future<Repositories> repositories;

  @override
  State<_Booting> createState() => _BootingState();
}

class _BootingState extends State<_Booting> {
  Repositories? _ready;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    widget.repositories.then(
      (r) {
        if (mounted) setState(() => _ready = r);
      },
      // Missing env.json and the like: said loudly, not an endless splash.
      onError: (Object e, StackTrace s) => FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ready;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: ready != null && _played
          ? MultiProvider(
              key: const ValueKey('app'),
              providers: providers(ready),
              child: PicnoteApp(repositories: ready, splash: false),
            )
          : MaterialApp(
              key: const ValueKey('splash'),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: SplashScreen(onDone: () => setState(() => _played = true)),
            ),
    );
  }
}

void runPicnote(Repositories repositories, {bool splash = true}) {
  runApp(
    MultiProvider(
      providers: providers(repositories),
      child: PicnoteApp(repositories: repositories, splash: splash),
    ),
  );
}

class PicnoteApp extends StatefulWidget {
  const PicnoteApp({super.key, required this.repositories, this.splash = true});

  final Repositories repositories;
  final bool splash;

  @override
  State<PicnoteApp> createState() => _PicnoteAppState();
}

class _PicnoteAppState extends State<PicnoteApp> {
  late final GoRouter _router = router(widget.repositories.auth, widget.repositories.household, splash: widget.splash);
  StreamSubscription<String>? _opened;

  @override
  void initState() {
    super.initState();
    // A tapped notification opens its list or note.
    final push = widget.repositories.push;
    _opened = push.opened.listen(_router.go);
    push.takeLaunchRoute().then((route) {
      if (route != null && mounted) _router.go(route);
    });
  }

  @override
  void dispose() {
    _opened?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      // Quill's own strings: its copy / paste menu.
      localizationsDelegates: const [...AppLocalizations.localizationsDelegates, FlutterQuillLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
