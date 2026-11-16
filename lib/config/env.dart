/// Build-time settings, passed with `--dart-define-from-file=env.json`
/// (see env.example.json).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The publishable key: safe to ship in the app, row level security
  /// protects the data.
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
