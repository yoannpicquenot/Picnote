/// Push notifications on this phone: the housemate created or changed a
/// shared list or note.
abstract class PushRepository {
  const PushRepository();

  /// The route of each notification tapped while the app runs.
  Stream<String> get opened;

  /// The route of the notification whose tap launched the app, once.
  Future<String?> takeLaunchRoute();

  /// Signs this phone up for [userId]'s notifications, or out of them.
  Future<void> switchUser(String? userId);
}

/// No push: tests, the demo, and where Firebase is not set up.
class PushRepositoryNone extends PushRepository {
  const PushRepositoryNone();

  @override
  Stream<String> get opened => const Stream.empty();

  @override
  Future<String?> takeLaunchRoute() async => null;

  @override
  Future<void> switchUser(String? userId) async {}
}
