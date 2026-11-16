import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/household/household_repository.dart';
import '../ui/account/widgets/account_screen.dart';
import '../ui/all_lists/view_models/all_lists_viewmodel.dart';
import '../ui/all_lists/widgets/all_lists_screen.dart';
import '../ui/auth/view_models/auth_viewmodel.dart';
import '../ui/auth/widgets/auth_screen.dart';
import '../ui/home/view_models/home_viewmodel.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/list/view_models/list_viewmodel.dart';
import '../ui/list/widgets/list_screen.dart';
import '../ui/note/view_models/note_viewmodel.dart';
import '../ui/note/widgets/note_screen.dart';
import '../ui/notes/view_models/notes_viewmodel.dart';
import '../ui/notes/widgets/notes_screen.dart';
import '../ui/notifications/widgets/notifications_screen.dart';
import '../ui/onboarding/view_models/onboarding_viewmodel.dart';
import '../ui/onboarding/widgets/onboarding_screen.dart';
import '../ui/settings/view_models/settings_viewmodel.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/shell/view_models/shell_viewmodel.dart';
import '../ui/shell/widgets/app_shell.dart';
import '../ui/shell/view_models/header_viewmodel.dart';
import '../ui/shell/widgets/home_tabs.dart';
import '../ui/splash/widgets/splash_screen.dart';
import '../ui/core/themes/colors.dart';
import 'routes.dart';

/// Signed out → sign-in. Signed in without a name or a household →
/// onboarding (which then leaves on its own). Otherwise the app.
GoRouter router(AuthRepository authRepository, HouseholdRepository householdRepository, {bool splash = true}) =>
    GoRouter(
      initialLocation: splash ? Routes.splash : Routes.home,
      refreshListenable: Listenable.merge([authRepository, householdRepository]),
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (loc == Routes.splash) return null;
        final user = authRepository.user;
        if (user == null) return loc == Routes.auth ? null : Routes.auth;
        final onboarded = user.name.isNotEmpty && householdRepository.household != null;
        if (loc == Routes.onboarding) return null;
        if (!onboarded) return Routes.onboarding;
        if (loc == Routes.auth) return Routes.home;
        return null;
      },
      routes: [
        GoRoute(
          path: Routes.splash,
          pageBuilder: (context, state) =>
              _page(context, state, _Motion.fade, SplashScreen(onDone: () => context.go(Routes.home))),
        ),
        GoRoute(
          path: Routes.auth,
          pageBuilder: (context, state) => _page(
            context,
            state,
            _Motion.fade,
            _Owned(
              create: () => AuthViewModel(authRepository: authRepository),
              builder: (vm) => AuthScreen(viewModel: vm),
            ),
          ),
        ),
        GoRoute(
          path: Routes.onboarding,
          pageBuilder: (context, state) => _page(
            context,
            state,
            _Motion.fade,
            _Owned(
              create: () => OnboardingViewModel(
                authRepository: authRepository,
                householdRepository: householdRepository,
                listRepository: context.read(),
                noteRepository: context.read(),
              ),
              builder: (vm) => OnboardingScreen(viewModel: vm, onFinished: () => context.go(Routes.home)),
            ),
          ),
        ),
        ShellRoute(
          pageBuilder: (context, state, child) => _page(
            context,
            state,
            _Motion.fade,
            ChangeNotifierProvider(
              create: (context) => ShellViewModel(
                authRepository: authRepository,
                householdRepository: householdRepository,
                listRepository: context.read(),
                noteRepository: context.read(),
                settingsRepository: context.read(),
              ),
              child: Consumer<ShellViewModel>(
                builder: (context, vm, _) => AppShell(viewModel: vm, location: state.uri.path, child: child),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: Routes.home,
              pageBuilder: (context, state) => _tabs(context, state, 0, authRepository, householdRepository),
            ),
            GoRoute(
              path: Routes.lists,
              pageBuilder: (context, state) => _page(
                context,
                state,
                _Motion.deeper,
                _Owned(
                  create: () => AllListsViewModel(
                    listRepository: context.read(),
                    householdRepository: householdRepository,
                    editing: state.uri.queryParameters['edit'] == '1',
                  ),
                  builder: (vm) => AllListsScreen(viewModel: vm, returnTo: state.uri.queryParameters['back']),
                ),
              ),
            ),
            // A sibling of /lists, not a child: opened from home, the list sits
            // right on top of home and its card can grow into it.
            GoRoute(
              path: '${Routes.lists}/:id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return _page(
                  context,
                  state,
                  _Motion.card,
                  _Owned(
                    key: ValueKey(id),
                    create: () => ListViewModel(
                      listId: id,
                      listRepository: context.read(),
                      authRepository: authRepository,
                      householdRepository: householdRepository,
                      settingsRepository: context.read(),
                      activityRepository: context.read(),
                      liveRepository: context.read(),
                    ),
                    builder: (vm) =>
                        ListScreen(viewModel: vm, fromAllLists: state.uri.queryParameters['from'] == 'all'),
                  ),
                );
              },
            ),
            GoRoute(
              path: Routes.notes,
              pageBuilder: (context, state) => _tabs(context, state, 1, authRepository, householdRepository),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return _page(
                      context,
                      state,
                      _Motion.card,
                      _Owned(
                        key: ValueKey(id),
                        create: () => NoteViewModel(
                          noteId: id,
                          noteRepository: context.read(),
                          authRepository: authRepository,
                          householdRepository: householdRepository,
                          settingsRepository: context.read(),
                          activityRepository: context.read(),
                          liveRepository: context.read(),
                        ),
                        builder: (vm) => NoteScreen(viewModel: vm),
                      ),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: Routes.settings,
              pageBuilder: (context, state) => _page(
                context,
                state,
                _Motion.tab,
                _Owned(
                  create: () => _settings(context, authRepository, householdRepository),
                  builder: (vm) => SettingsScreen(viewModel: vm),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'account',
                  pageBuilder: (context, state) => _page(
                    context,
                    state,
                    _Motion.deeper,
                    _Owned(
                      create: () => _settings(context, authRepository, householdRepository),
                      builder: (vm) => AccountScreen(viewModel: vm),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'notifications',
                  pageBuilder: (context, state) => _page(
                    context,
                    state,
                    _Motion.deeper,
                    _Owned(
                      create: () => _settings(context, authRepository, householdRepository),
                      builder: (vm) => NotificationsScreen(viewModel: vm),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Lists (home) and Notes, one page for both routes: going from one to the
/// other moves the pager instead of opening a new page.
Page<void> _tabs(
  BuildContext context,
  GoRouterState state,
  int index,
  AuthRepository authRepository,
  HouseholdRepository householdRepository,
) => _page(
  context,
  state,
  _Motion.tab,
  key: const ValueKey('tabs'),
  _Owned(
    create: () => HeaderViewModel(
      activityRepository: context.read(),
      authRepository: authRepository,
      householdRepository: householdRepository,
      listRepository: context.read(),
      noteRepository: context.read(),
    ),
    builder: (header) => HomeTabs(
      viewModel: header,
      index: index,
      onSettled: (i) => context.go(i == 0 ? Routes.home : Routes.notes),
      pages: [
        _Owned(
          create: () => HomeViewModel(
            listRepository: context.read(),
            authRepository: authRepository,
            householdRepository: householdRepository,
            noteRepository: context.read(),
          ),
          builder: (vm) =>
              HomeScreen(viewModel: vm, onCreateList: () => startNewList(context, context.read<ShellViewModel>())),
        ),
        _Owned(
          create: () => NotesViewModel(noteRepository: context.read(), householdRepository: householdRepository),
          builder: (vm) => NotesScreen(viewModel: vm),
        ),
      ],
    ),
  ),
);

SettingsViewModel _settings(BuildContext context, AuthRepository auth, HouseholdRepository household) =>
    SettingsViewModel(
      authRepository: auth,
      householdRepository: household,
      settingsRepository: context.read(),
      listRepository: context.read(),
      noteRepository: context.read(),
    );

/// How a page enters (and leaves, in reverse).
enum _Motion {
  /// Soft fade: splash, sign-in, onboarding, the app.
  fade(Duration(milliseconds: 300)),

  /// Settings, and Lists or Notes coming back: a quick fade with a slight
  /// zoom.
  tab(Duration(milliseconds: 220)),

  /// One level deeper (all lists, account…): slides in from the right.
  deeper(Duration(milliseconds: 300)),

  /// A list or a note opening: a plain fade over its card.
  card(Duration(milliseconds: 280));

  const _Motion(this.duration);

  final Duration duration;
}

/// The page for [child], on the app background so the page below doesn't
/// show through. No animation when the phone asks for less motion.
Page<void> _page(BuildContext context, GoRouterState state, _Motion motion, Widget child, {LocalKey? key}) {
  final time = MediaQuery.disableAnimationsOf(context) ? Duration.zero : motion.duration;
  return CustomTransitionPage<void>(
    key: key ?? state.pageKey,
    transitionDuration: time,
    reverseTransitionDuration: time,
    child: ColoredBox(color: PnColors.cream, child: child),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final eased = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return switch (motion) {
        _Motion.fade || _Motion.card => FadeTransition(opacity: eased, child: child),
        _Motion.tab => FadeTransition(
          opacity: eased,
          child: ScaleTransition(scale: Tween(begin: 0.985, end: 1.0).animate(eased), child: child),
        ),
        _Motion.deeper => FadeTransition(
          opacity: eased,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(eased),
            child: child,
          ),
        ),
      };
    },
  );
}

/// Creates a view model once for the life of the screen and disposes it
/// with the screen, since view models listen to repositories.
class _Owned<T extends ChangeNotifier> extends StatefulWidget {
  const _Owned({super.key, required this.create, required this.builder});

  final T Function() create;
  final Widget Function(T viewModel) builder;

  @override
  State<_Owned<T>> createState() => _OwnedState<T>();
}

class _OwnedState<T extends ChangeNotifier> extends State<_Owned<T>> {
  late final T _viewModel = widget.create();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_viewModel);
}
