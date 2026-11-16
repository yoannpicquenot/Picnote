import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/household.dart';
import '../../../utils/result.dart';
import '../synced_repository.dart';
import 'household_repository.dart';

/// Household, members and invitation from Supabase. Joining, leaving and
/// invitations go through the SQL functions of supabase/migrations, which
/// enforce the 2-member limit.
class HouseholdRepositorySupabase extends HouseholdRepository with SyncedRepository {
  HouseholdRepositorySupabase(this.client);

  @override
  final SupabaseClient client;

  String? _id;
  Household? _household;

  /// Changes when the user creates, joins or leaves a household.
  String? get householdId => _id;

  @override
  Household? get household => _household;

  @override
  List<String> get watchedTables => const ['households', 'household_members', 'invites', 'profiles'];

  @override
  void clear() {
    _id = null;
    _household = null;
  }

  @override
  Future<void Function()> fetch() async {
    final membership = await client
        .from('household_members')
        .select('household_id')
        .eq('user_id', userId!)
        .maybeSingle();
    final id = membership?['household_id'] as String?;
    if (id == null) return () => clear();
    final (household, members, invite) = await (
      client.from('households').select('name').eq('id', id).single(),
      client
          .from('household_members')
          .select('user_id, profiles(name, color)')
          .eq('household_id', id)
          .order('joined_at', ascending: true),
      client.from('invites').select('email, code, resent').eq('household_id', id).maybeSingle(),
    ).wait;
    return () {
      _id = id;
      _household = Household(
        name: household['name'] as String,
        members: [
          for (final m in members)
            Member(
              id: m['user_id'] as String,
              name: m['profiles']['name'] as String,
              color: m['profiles']['color'] as int,
            ),
        ],
        invite: invite == null
            ? null
            : Invite(
                email: invite['email'] as String,
                code: invite['code'] as String,
                resent: invite['resent'] as bool,
              ),
      );
    };
  }

  /// Calls a SQL function, then refetches.
  Future<Result<T>> _call<T>(String function, [Map<String, dynamic>? params]) async {
    try {
      final value = await client.rpc<T>(function, params: params);
      await refresh();
      return Result.ok(value);
    } on PostgrestException catch (e) {
      return Result.error(switch (e.code) {
        'P0002' => HouseholdFullException(),
        'P0003' => InvalidInviteException(),
        _ => e,
      });
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> create(String name, Member me) => _call<String>('create_household', {'household_name': name});

  @override
  Future<Result<HouseholdPreview>> lookUpInvite(String code) async {
    try {
      final preview = await client.rpc<Map<String, dynamic>?>('look_up_invite', params: {'invite_code': code});
      if (preview == null) return Result.error(InvalidInviteException());
      return Result.ok(
        HouseholdPreview(
          name: preview['name'] as String,
          members: [
            for (final m in (preview['members'] as List).cast<Map<String, dynamic>>())
              Member(id: m['id'] as String, name: m['name'] as String, color: m['color'] as int),
          ],
        ),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> join(String code, Member me) => _call<void>('join_household', {'invite_code': code});

  @override
  Future<Result<void>> rename(String name) async {
    final id = _id;
    if (id == null) return Result.error(Exception('No household'));
    try {
      await client.from('households').update({'name': name}).eq('id', id);
      await refresh();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  /// The profile row is already up to date (see the auth repository).
  @override
  Future<Result<void>> updateMember(Member me) => refresh();

  @override
  Future<Result<void>> sendInvite(String email) => _call<String>('send_invite', {'invite_email': email});

  @override
  Future<Result<void>> resendInvite() => _call<void>('resend_invite');

  @override
  Future<Result<void>> cancelInvite() => _call<void>('cancel_invite');

  @override
  Future<Result<void>> removeMember(String memberId) => _call<void>('remove_member', {'member': memberId});

  @override
  Future<Result<void>> leave() => _call<void>('leave_household');
}
