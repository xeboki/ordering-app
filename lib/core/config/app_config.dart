/// Build-time configuration injected via --dart-define.
///
/// Build command:
///   flutter build apk \
///     --dart-define=XEBOKI_API_KEY=xbk_live_... \
///     --dart-define=XEBOKI_LOCATION_ID=loc_abc
///
/// The API base URL is an SDK internal concern — never set it here.
/// For development, create a run configuration with the two dart-defines above.
class AppConfig {
  AppConfig._();

  // ── Xeboki credentials ────────────────────────────────────────────────────
  static const String apiKey = String.fromEnvironment(
    'XEBOKI_API_KEY',
    defaultValue: '',
  );

  static const String locationId = String.fromEnvironment(
    'XEBOKI_LOCATION_ID',
    defaultValue: '',
  );

  // ── Environment ─────────────────────────────────────────────────────────────
  static const bool isProduction = String.fromEnvironment(
        'XEBOKI_ENV',
        defaultValue: 'production',
      ) ==
      'production';

  // ── Validation ──────────────────────────────────────────────────────────────
  static bool get isConfigured =>
      apiKey.isNotEmpty && locationId.isNotEmpty;

  static void assertConfigured() {
    assert(
      isConfigured,
      '\n\n'
      '════════════════════════════════════════════════════════\n'
      '  XEBOKI_API_KEY and XEBOKI_LOCATION_ID are required.\n'
      '  Add --dart-define flags to your build/run command.\n'
      '  See .env.example for details.\n'
      '════════════════════════════════════════════════════════\n',
    );
  }
}
