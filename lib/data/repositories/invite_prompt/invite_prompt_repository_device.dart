import 'package:shared_preferences/shared_preferences.dart';

import 'invite_prompt_repository.dart';

/// Kept on the device, so the card stays away across restarts.
class InvitePromptRepositoryDevice extends InvitePromptRepository {
  InvitePromptRepositoryDevice._(this._prefs);

  static const _key = 'invite_prompt_dismissed';

  final SharedPreferencesWithCache _prefs;

  static Future<InvitePromptRepositoryDevice> create() async => InvitePromptRepositoryDevice._(
    await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {_key})),
  );

  @override
  bool get dismissed => _prefs.getBool(_key) ?? false;

  @override
  Future<void> dismiss() async {
    await _prefs.setBool(_key, true);
    notifyListeners();
  }

  @override
  Future<void> reset() async {
    await _prefs.remove(_key);
    notifyListeners();
  }
}
