abstract final class Routes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const notes = '/notes';
  static const lists = '/lists';
  static const settings = '/settings';
  static const account = '/settings/account';
  static const notifications = '/settings/notifications';

  static String list(String id) => '/lists/$id';

  static String note(String id) => '/notes/$id';
}
