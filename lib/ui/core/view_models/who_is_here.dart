import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../domain/models/activity.dart';
import '../../../domain/models/household.dart';
import '../../../utils/result.dart';

/// A member's latest change, with the name of the list or note it was
/// made to (null once that is gone, empty for an untitled note).
typedef MemberActivity = ({Activity activity, String? itemName});

/// Data behind the "who's here" panel of the home and notes headers: who
/// has the app open, and each member's latest change.
class WhoIsHere {
  WhoIsHere({
    required this._activityRepository,
    required this._householdRepository,
    required this._listRepository,
    required this._noteRepository,
    required this.meId,
  });

  final ActivityRepository _activityRepository;
  final HouseholdRepository _householdRepository;
  final ListRepository _listRepository;
  final NoteRepository _noteRepository;
  final String meId;

  List<Member> get members => _householdRepository.household?.members ?? const [];

  /// The user is always here; the others when their app is open.
  bool isHere(Member m) => m.id == meId || _activityRepository.online.contains(m.id);

  Future<Map<String, MemberActivity>> latest() async {
    final result = await _activityRepository.latestByMember([for (final m in members) m.id]);
    if (result is! Ok<Map<String, Activity>>) return const {};
    return {
      for (final MapEntry(:key, :value) in result.value.entries) key: (activity: value, itemName: _nameOf(value)),
    };
  }

  String? _nameOf(Activity a) {
    if (a.isNote) {
      for (final n in _noteRepository.notes) {
        if (n.id == a.itemId) return n.title;
      }
    } else {
      for (final l in _listRepository.lists) {
        if (l.id == a.itemId) return l.name;
      }
    }
    return null;
  }
}
