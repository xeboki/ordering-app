import 'dart:convert';
import 'package:http/http.dart' as http;

/// Backend-for-Frontend transport for the Ordering App.
///
/// The app no longer holds an xbk_ key. It signs into the tenant Firebase, and
/// this transport exchanges that ID token for a short storefront session
/// (POST {bffBaseUrl}/api/mobile/v1/session), caches it, and sends it as a
/// Bearer on every call to the BFF — which is the only thing that talks to the
/// gateway. On a 401 the session is refreshed once from a fresh ID token.
///
/// Drop-in shape: `request<T>(method, path, {query, body, fromJson})` mirrors the
/// old gateway _Http so porting OrderingClient methods is mechanical — change
/// each path from `/v1/pos/<x>` to the BFF's `/<x>` (see the mapping in the
/// migration note at the bottom of this file).
///
/// CONTRACT NOTE (must be honoured when porting parsers): the BFF returns the
/// TS-SDK-*mapped* (camelCase) shapes, not the gateway's snake_case. Any model
/// `fromJson` that currently reads snake_case gateway fields must be updated to
/// the camelCase BFF fields. This is the part that needs on-device QA —
/// especially the Stripe payment path.
class BffClient {
  BffClient({
    required this.bffBaseUrl,
    required this.storeSlug,
    required this.idTokenProvider,
  });

  /// e.g. https://mystore.xeboki.store  (no trailing slash needed)
  final String bffBaseUrl;

  /// The store this app belongs to.
  final String storeSlug;

  /// Returns a fresh Firebase ID token (e.g. FirestoreService.getIdToken).
  final Future<String?> Function({bool forceRefresh}) idTokenProvider;

  final http.Client _client = http.Client();
  String? _session;

  String get _base => '${bffBaseUrl.replaceAll(RegExp(r'/+$'), '')}/api/mobile/v1';

  Future<void> _ensureSession({bool force = false}) async {
    if (_session != null && !force) return;
    final idToken = await idTokenProvider(forceRefresh: force);
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Not signed in — a Firebase session is required.');
    }
    final res = await _client.post(
      Uri.parse('$_base/session'),
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'store': storeSlug, 'idToken': idToken}),
    );
    if (res.statusCode != 200) {
      throw StateError('Session exchange failed (${res.statusCode}).');
    }
    _session = (jsonDecode(res.body) as Map<String, dynamic>)['session'] as String?;
    if (_session == null) throw StateError('Session exchange returned no session.');
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_session != null) 'Authorization': 'Bearer $_session',
      };

  Future<T> request<T>(
    String method,
    String path, {
    Map<String, String?>? query,
    Map<String, dynamic>? body,
    required T Function(dynamic) fromJson,
    bool retried = false,
  }) async {
    await _ensureSession();

    final params = query?.entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value!))
        .toList();
    final uri = Uri.parse('$_base$path').replace(
      queryParameters:
          params != null && params.isNotEmpty ? Map.fromEntries(params) : null,
    );
    final encoded = body != null ? jsonEncode(body) : null;

    http.Response res;
    switch (method) {
      case 'GET':
        res = await _client.get(uri, headers: _headers);
      case 'POST':
        res = await _client.post(uri, headers: _headers, body: encoded);
      case 'PATCH':
        res = await _client.patch(uri, headers: _headers, body: encoded);
      case 'PUT':
        res = await _client.put(uri, headers: _headers, body: encoded);
      case 'DELETE':
        res = await _client.delete(uri, headers: _headers);
      default:
        throw ArgumentError('Unknown method: $method');
    }

    // Session expired → refresh once from a fresh ID token and retry.
    if (res.statusCode == 401 && !retried) {
      _session = null;
      await _ensureSession(force: true);
      return request<T>(method, path,
          query: query, body: body, fromJson: fromJson, retried: true);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'HTTP ${res.statusCode}';
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['error'] != null) message = j['error'].toString();
      } catch (_) {}
      throw BffException(res.statusCode, message);
    }

    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    return fromJson(decoded);
  }
}

class BffException implements Exception {
  BffException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => 'BffException($status): $message';
}

// ─── Migration note: OrderingClient path → BFF path ───────────────────────────
// fetchStoreConfig        GET  /store
// listLocations           GET  /locations
// listCategories          GET  /categories
// listProducts            GET  /catalog?category=&q=&sort=&page=&per_page=&instock=
// getProductBySlug        GET  /product/{slug}
// getUpsells              (fold into product payload or add a /upsells route if needed)
// listMealDeals           GET  /meal-deals?location=
// listDiscounts           GET  /discounts?code=
// lookupGiftCard          POST /giftcard            { code }
// validateDiscount        POST /discount            { code, orderTotal }
// createOrder             POST /orders              { items, orderType, ... }
// getOrder                GET  /orders/{id}
// listOrders              GET  /orders
// requestReturn           POST /orders/{id}/returns { reason, notes }
// getDeliveryZones        GET  /delivery/zones?location=
// validatePostcode        POST /delivery/validate-postcode { postcode, location }
// getDeliveryTracking     GET  /orders/{id}/tracking
// getLoyaltyConfig        (add /loyalty/config BFF route if the app needs it)
// customer auth           handled by Firebase sign-in + POST /session (no register/login/firebaseVerify calls)
// createStripePaymentIntent / confirmStripePayment / payOrder:
//   add /orders/{id}/stripe/intent, /orders/{id}/stripe/confirm, /orders/{id}/pay
//   BFF routes (ownership-checked) before porting the payment path — DEVICE QA REQUIRED.
