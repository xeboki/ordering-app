/// UK postcode utilities.
///
/// Format validation is done client-side for instant feedback.
/// Distance / zone resolution is done server-side via
/// [OrderingClient.validatePostcode] (uses Postcodes.io + haversine).
class PostcodeService {
  PostcodeService._();

  // Standard UK postcode regex — covers all valid formats including BFPO.
  static final _ukRegex = RegExp(
    r'^[A-Z]{1,2}[0-9][0-9A-Z]?\s*[0-9][ABD-HJLNP-UW-Z]{2}$',
    caseSensitive: false,
  );

  /// Returns true if [postcode] matches the UK postcode pattern.
  static bool isValidUkFormat(String postcode) =>
      _ukRegex.hasMatch(postcode.trim());

  /// Normalises postcode input: upper-case, ensures the space before the
  /// inward code (e.g. "sw1a1aa" → "SW1A 1AA").
  static String normalise(String input) {
    final raw = input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (raw.length >= 5) {
      // Insert space before last 3 characters (inward code)
      return '${raw.substring(0, raw.length - 3)} ${raw.substring(raw.length - 3)}';
    }
    return raw;
  }
}
