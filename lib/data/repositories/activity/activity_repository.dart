import 'package:flutter/foundation.dart';

import '../../../domain/models/activity.dart';
import '../../../utils/result.dart';

/// Who has the app open right now, and who changed what. Changes are
/// read when asked for (opening a menu or the "who's here" panel), not kept
/// live.
abstract class ActivityRepository extends ChangeNotifier {
  /// Ids of the household members with the app open.
  Set<String> get online;

  /// The latest changes to a list or a note, newest first.
  Future<Result<List<Activity>>> latestFor({required bool isNote, required String id, int limit = 3});

  /// Each member's latest change, among the lists and notes the user sees.
  Future<Result<Map<String, Activity>>> latestByMember(List<String> memberIds);

  /// The user is done with list or note [id]: what they changed in it is
  /// sent to the housemates now, not a minute later.
  Future<void> release(String id);
}
