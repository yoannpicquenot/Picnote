import 'dart:async';

import '../../../domain/models/household.dart';
import '../../../utils/result.dart';
import 'household_repository.dart';

/// In-memory fake for development.
///
/// Demo invite code: [demoCode]. When [partnerJoinsAfter] is set, the invited
/// partner joins on their own that long after an invitation is sent.
class HouseholdRepositoryLocal extends HouseholdRepository {
  HouseholdRepositoryLocal({this._household, this.partnerJoinsAfter = const Duration(seconds: 5)});

  static const demoCode = 'K7H2M9';
  static const partner = Member(id: 'yoann', name: 'Yoann', color: 0xFF3F7063);

  final Duration? partnerJoinsAfter;

  Household? _household;
  Timer? _joinTimer;

  @override
  Household? get household => _household;

  void _set(Household? household) {
    _household = household;
    notifyListeners();
  }

  @override
  Future<Result<void>> create(String name, Member me) async {
    _set(Household(name: name, members: [me]));
    return const Result.ok(null);
  }

  @override
  Future<Result<HouseholdPreview>> lookUpInvite(String code) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (code != demoCode) return Result.error(InvalidInviteException());
    return const Result.ok(HouseholdPreview(name: 'Maison Saint-Rambert', members: [partner]));
  }

  @override
  Future<Result<void>> join(String code, Member me) async {
    final preview = await lookUpInvite(code);
    switch (preview) {
      case Error():
        return Result.error(preview.error);
      case Ok():
        if (preview.value.isFull) return Result.error(HouseholdFullException());
        _set(Household(name: preview.value.name, members: [...preview.value.members, me]));
        return const Result.ok(null);
    }
  }

  @override
  Future<Result<void>> rename(String name) async {
    final h = _household;
    if (h == null) return Result.error(Exception('No household'));
    _set(h.copyWith(name: name));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> updateMember(Member me) async {
    final h = _household;
    if (h == null) return const Result.ok(null);
    _set(h.copyWith(members: [for (final m in h.members) m.id == me.id ? me : m]));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> sendInvite(String email) async {
    final h = _household;
    if (h == null) return Result.error(Exception('No household'));
    if (h.isFull) return Result.error(HouseholdFullException());
    _set(
      h.copyWith(
        invite: () => Invite(email: email, code: demoCode),
      ),
    );
    _scheduleJoin();
    return const Result.ok(null);
  }

  @override
  Future<Result<String>> createInviteCode() async {
    final h = _household;
    if (h == null) return Result.error(Exception('No household'));
    if (h.isFull) return Result.error(HouseholdFullException());
    final invite = h.invite;
    if (invite != null) return Result.ok(invite.code);
    _set(
      h.copyWith(
        invite: () => const Invite(email: '', code: demoCode),
      ),
    );
    _scheduleJoin();
    return const Result.ok(demoCode);
  }

  @override
  Future<Result<void>> resendInvite() async {
    final h = _household;
    final invite = h?.invite;
    if (h == null || invite == null) return Result.error(Exception('No invite'));
    _set(
      h.copyWith(
        invite: () => Invite(email: invite.email, code: invite.code, resent: true),
      ),
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> cancelInvite() async {
    _joinTimer?.cancel();
    final h = _household;
    if (h != null) _set(h.copyWith(invite: () => null));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> removeMember(String memberId) async {
    final h = _household;
    if (h == null) return Result.error(Exception('No household'));
    _set(h.copyWith(members: h.members.where((m) => m.id != memberId).toList()));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> leave() async {
    _joinTimer?.cancel();
    _set(null);
    return const Result.ok(null);
  }

  void _scheduleJoin() {
    final delay = partnerJoinsAfter;
    if (delay == null) return;
    _joinTimer?.cancel();
    _joinTimer = Timer(delay, () {
      final h = _household;
      if (h == null || h.invite == null || h.isFull) return;
      _set(h.copyWith(members: [...h.members, partner], invite: () => null));
    });
  }

  @override
  void dispose() {
    _joinTimer?.cancel();
    super.dispose();
  }
}
