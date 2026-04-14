import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/services/firestore_service.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

// ── Firebase initialisation provider ─────────────────────────────────────────

/// Fetches the merchant's Pro Firebase config from the API and initialises
/// the secondary Firebase app. Only runs when `firebase_auth == true`.
///
/// Downstream providers (auth, Firestore stream) should depend on this.
/// UI can watch this to show a loading state during cold-start init.
final firebaseInitProvider =
    AsyncNotifierProvider<_FirebaseInitNotifier, bool>(
  _FirebaseInitNotifier.new,
);

class _FirebaseInitNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final brand = BrandConfig.instance;
    if (!brand.features.firebaseAuth) return false;

    // Already initialised (e.g. hot restart)
    if (FirestoreService.instance.isInitialised) return true;

    final client = ref.read(orderingClientProvider);
    final config = await client.getFirebaseConfig();
    await FirestoreService.instance.init(config);
    return true;
  }

  Future<void> reinitialise() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(orderingClientProvider);
      final config = await client.getFirebaseConfig();
      await FirestoreService.instance.init(config);
      return true;
    });
  }
}

// ── Convenience selector ──────────────────────────────────────────────────────

/// True once Firebase is ready (or when firebase_auth flag is off — no-op path).
final firebaseReadyProvider = Provider<bool>((ref) {
  if (!BrandConfig.instance.features.firebaseAuth) return true;
  return ref.watch(firebaseInitProvider).valueOrNull ?? false;
});

// ── FCM token registration ────────────────────────────────────────────────────

/// Requests FCM permission and registers the token against the logged-in
/// customer whenever Firebase is ready and the customer is authenticated.
///
/// Watch this provider in the root widget so it runs for the app's lifetime.
/// It is a no-op when firebase_auth is disabled or no customer is signed in.
final fcmRegistrationProvider = FutureProvider<void>((ref) async {
  // firebase_messaging has no Windows/Linux plugin — skip silently.
  if (!kIsWeb &&
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }

  final ready = ref.watch(firebaseReadyProvider);
  final auth  = ref.watch(authProvider);
  if (!ready || auth == null) { return; }

  final token = await FirestoreService.instance.getFcmToken();
  if (token == null) { return; }

  final client = ref.read(orderingClientProvider);
  await client.registerCustomerFcmToken(auth.customer.id, token);
});
