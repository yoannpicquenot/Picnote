abstract final class Routes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const lists = '/lists';
  static const notes = '/notes';
  static const memos = '/pense-bete';
  static const settings = '/settings';
  static const account = '/settings/account';
  static const notifications = '/settings/notifications';

  /// The bottom bar's tabs, in their order.
  static const tabs = [home, lists, notes];

  static String list(String id) => '/lists/$id';

  /// All lists on their own page, in edit mode, to make room on home; "OK"
  /// goes back to [returnTo], the list being pinned.
  static String editLists({required String returnTo}) => '/lists-edit?back=$returnTo';

  static String note(String id) => '/notes/$id';
}
