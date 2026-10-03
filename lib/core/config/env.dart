/// Build-time configuration passed with
/// `--dart-define-from-file=env/supabase.json` (see README).
///
/// Without these values the app runs in demo mode: everything stays on the
/// device and account features are hidden.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Publishable ("anon") key – safe in the app only because every table
  /// has row level security (see `supabase/migrations`).
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static bool get hasBackend =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  /// Keep in sync with `version` in pubspec.yaml.
  static const String appVersion = '0.4.0';
}
