/// Build-time configuration injected via --dart-define.
///
/// Build command:
///   flutter build apk --dart-define=XEBOKI_API_KEY=xbk_live_...
///
/// No location ID is needed at build time. The app calls GET /v1/pos/locations
/// at runtime to discover which branches have online ordering enabled. The
/// merchant controls this from the Manager app per-location toggle.
///
/// The API base URL is an SDK internal concern — never set it here.
class AppConfig {
  AppConfig._();

  // ── Xeboki credentials ────────────────────────────────────────────────────
  static const String apiKey = String.fromEnvironment(
    'XEBOKI_API_KEY',
    defaultValue: '',
  );

  // ── Environment ─────────────────────────────────────────────────────────────
  static const bool isProduction = String.fromEnvironment(
        'XEBOKI_ENV',
        defaultValue: 'production',
      ) ==
      'production';

  // ── Validation ──────────────────────────────────────────────────────────────
  static bool get isConfigured => apiKey.isNotEmpty;

  static void assertConfigured() {
    assert(
      isConfigured,
      '\n\n'
      '════════════════════════════════════════════════════════\n'
      '  XEBOKI_API_KEY is required.\n'
      '  Add --dart-define=XEBOKI_API_KEY=xbk_live_... to your\n'
      '  build/run command, or use setup.sh.\n'
      '════════════════════════════════════════════════════════\n',
    );
  }
}
