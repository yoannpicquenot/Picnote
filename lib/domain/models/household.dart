/// Someone in the household, shown as an initial on a colored avatar.
class Member {
  const Member({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final int color;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
}

/// An invitation, valid for 7 days. The other person joins by typing
/// [code].
class Invite {
  const Invite({required this.email, required this.code, this.resent = false});

  /// Empty when the code was given by hand rather than emailed.
  final String email;
  final String code;
  final bool resent;

  bool get byCode => email.isEmpty;
}

/// The household shares lists and notes between its members (2 at most).
class Household {
  const Household({required this.name, required this.members, this.invite});

  static const maxMembers = 2;

  final String name;
  final List<Member> members;
  final Invite? invite;

  bool get isFull => members.length >= maxMembers;

  /// The invitation sent by email and not accepted yet. A code given by hand
  /// does not count: it still works, but nobody is shown as invited.
  Invite? get pendingInvite => invite == null || invite!.byCode ? null : invite;

  /// Alone in the household: sharing switches become "Invite".
  bool get isSolo => members.length < 2;

  Member? member(String? id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// The other member, when there is one.
  Member? partnerOf(String meId) {
    for (final m in members) {
      if (m.id != meId) return m;
    }
    return null;
  }

  Household copyWith({String? name, List<Member>? members, Invite? Function()? invite}) => Household(
    name: name ?? this.name,
    members: members ?? this.members,
    invite: invite != null ? invite() : this.invite,
  );
}

/// What an invite code reveals before joining.
class HouseholdPreview {
  const HouseholdPreview({required this.name, required this.members});

  final String name;
  final List<Member> members;

  bool get isFull => members.length >= Household.maxMembers;
}
