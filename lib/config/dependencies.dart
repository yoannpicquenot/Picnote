import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/activity/activity_repository.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/household/household_repository.dart';
import '../data/repositories/invite_prompt/invite_prompt_repository.dart';
import '../data/repositories/list/list_repository.dart';
import '../data/repositories/live/live_repository.dart';
import '../data/repositories/memo/memo_repository.dart';
import '../data/repositories/note/note_repository.dart';
import '../data/repositories/push/push_repository.dart';
import '../data/repositories/settings/settings_repository.dart';

/// Every repository the app needs, created once at startup.
class Repositories {
  const Repositories({
    required this.auth,
    required this.household,
    required this.lists,
    required this.memos,
    required this.notes,
    required this.settings,
    required this.activity,
    required this.live,
    required this.invitePrompt,
    this.push = const PushRepositoryNone(),
  });

  final AuthRepository auth;
  final HouseholdRepository household;
  final ListRepository lists;

  /// The household's Pense-bête.
  final MemoRepository memos;
  final NoteRepository notes;
  final SettingsRepository settings;
  final ActivityRepository activity;
  final LiveRepository live;
  final InvitePromptRepository invitePrompt;

  /// Not provided to the widget tree: only the app itself opens what a
  /// tapped notification points to.
  final PushRepository push;
}

/// Exposes [repositories] to the widget tree, for the router and screens.
List<SingleChildWidget> providers(Repositories repositories) => [
  ChangeNotifierProvider<AuthRepository>.value(value: repositories.auth),
  ChangeNotifierProvider<HouseholdRepository>.value(value: repositories.household),
  ChangeNotifierProvider<ListRepository>.value(value: repositories.lists),
  ChangeNotifierProvider<MemoRepository>.value(value: repositories.memos),
  ChangeNotifierProvider<NoteRepository>.value(value: repositories.notes),
  ChangeNotifierProvider<SettingsRepository>.value(value: repositories.settings),
  ChangeNotifierProvider<ActivityRepository>.value(value: repositories.activity),
  ChangeNotifierProvider<LiveRepository>.value(value: repositories.live),
  ChangeNotifierProvider<InvitePromptRepository>.value(value: repositories.invitePrompt),
];
