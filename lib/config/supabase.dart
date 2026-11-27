import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/activity/activity_repository_supabase.dart';
import '../data/repositories/auth/auth_repository_supabase.dart';
import '../data/repositories/household/household_repository_supabase.dart';
import '../data/repositories/invite_prompt/invite_prompt_repository_device.dart';
import '../data/repositories/list/list_repository_supabase.dart';
import '../data/repositories/live/live_repository_supabase.dart';
import '../data/repositories/memo/memo_repository_supabase.dart';
import '../data/repositories/note/note_repository_supabase.dart';
import '../data/repositories/push/push_repository.dart';
import '../data/repositories/push/push_repository_supabase.dart';
import '../data/repositories/settings/settings_repository_supabase.dart';
import '../data/services/push_service.dart';
import 'dependencies.dart';
import 'env.dart';

/// Repositories backed by Supabase, with the saved session (if any) and its
/// data already loaded.
Future<Repositories> supabaseRepositories() async {
  if (!Env.hasSupabase) {
    throw StateError('Supabase settings missing: build with --dart-define-from-file=env.json (see env.example.json).');
  }
  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);
  final client = Supabase.instance.client;

  final auth = AuthRepositorySupabase(client);
  final household = HouseholdRepositorySupabase(client);
  final lists = ListRepositorySupabase(client);
  final memos = MemoRepositorySupabase(client);
  final notes = NoteRepositorySupabase(client);
  final settings = SettingsRepositorySupabase(client);
  final activity = ActivityRepositorySupabase(client);
  final live = LiveRepositorySupabase(client);
  final pushService = await PushService.start();
  final push = pushService == null ? const PushRepositoryNone() : PushRepositorySupabase(client, pushService);

  // Lists and notes listen on a channel per household, so that the two
  // members can tell each other to refetch.
  String? watching;
  Future<void> ready = Future.value();
  Future<void> watchContent() {
    final userId = auth.user?.id;
    final householdId = household.householdId;
    if (watching == '$userId/$householdId') return ready;
    watching = '$userId/$householdId';
    final scope = householdId ?? 'user-$userId';
    return ready = Future.wait([
      lists.watch(userId, topic: 'lists:$scope'),
      memos.watch(householdId == null ? null : userId, topic: 'memos:$scope'),
      notes.watch(userId, topic: 'notes:$scope'),
      activity.watch(userId, householdId),
      live.watch(userId, householdId),
    ]);
  }

  auth.onUserChanged = (user) async {
    // Not awaited: the permission prompt must not hold the app back.
    unawaited(push.switchUser(user?.id));
    await Future.wait([household.watch(user?.id, topic: 'household:${user?.id}'), settings.switchUser(user?.id)]);
    await watchContent();
  };
  // Joining, leaving or being removed changes which shared rows are visible.
  household.addListener(watchContent);

  await auth.init();
  return Repositories(
    auth: auth,
    household: household,
    lists: lists,
    memos: memos,
    notes: notes,
    settings: settings,
    activity: activity,
    live: live,
    invitePrompt: await InvitePromptRepositoryDevice.create(),
    push: push,
  );
}
