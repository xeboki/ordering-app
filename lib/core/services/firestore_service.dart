import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xeboki_ordering/core/types.dart';

/// Manages the secondary Firebase app for the ordering app.
///
/// # Why a secondary app?
/// The ordering app has no google-services.json and no hardcoded Firebase
/// project. The merchant's Pro Firebase credentials are fetched at runtime
/// via [OrderingClient.getFirebaseConfig] and used to initialise a named
/// Firebase app (separate from any default app the host might have).
///
/// # Lifecycle
/// [init] must be called once during app startup (after [BrandConfig.load]).
/// If `brand.features.firebaseAuth == false` it is a no-op.
/// After init, [auth] and [firestore] provide scoped instances.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  static const _appName = 'xeboki_ordering';

  FirebaseApp? _app;

  bool get isInitialised => _app != null;

  /// Initialise the secondary Firebase app from the ordering config.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> init(FirebaseOrderingConfig config) async {
    if (_app != null) return;
    try {
      // Re-use app if it already exists from a previous hot-restart
      _app = Firebase.app(_appName);
    } on FirebaseException {
      _app = await Firebase.initializeApp(
        name: _appName,
        options: FirebaseOptions(
          apiKey: config.apiKey,
          appId: config.appId,
          messagingSenderId: config.messagingSenderId,
          projectId: config.projectId,
          authDomain: config.authDomain,
          storageBucket: config.storageBucket,
          measurementId: config.measurementId,
        ),
      );
    }
  }

  /// Firebase Auth scoped to the merchant's Pro Firebase project.
  FirebaseAuth get auth {
    assert(_app != null, 'FirestoreService not initialised — call init() first');
    return FirebaseAuth.instanceFor(app: _app!);
  }

  /// Firestore scoped to the merchant's Pro Firebase project.
  FirebaseFirestore get firestore {
    assert(_app != null, 'FirestoreService not initialised — call init() first');
    return FirebaseFirestore.instanceFor(app: _app!);
  }

  /// Convenience: get fresh ID token from the currently signed-in Firebase user.
  /// Returns null if no user is signed in.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (!isInitialised) return null;
    return auth.currentUser?.getIdToken(forceRefresh);
  }

  /// Sign out from Firebase Auth (called as part of AuthNotifier.logout).
  Future<void> signOut() async {
    if (!isInitialised) return;
    await auth.signOut();
  }

  // ── Firestore order streaming ─────────────────────────────────────────────

  /// Real-time stream of an order document. Emits the raw Firestore data map.
  /// Returns null when the document doesn't exist yet.
  Stream<Map<String, dynamic>?> orderStream(String orderId) {
    return firestore.collection('orders').doc(orderId).snapshots().map(
      (snap) => snap.exists ? snap.data() : null,
    );
  }

  // ── FCM ───────────────────────────────────────────────────────────────────

  /// FCM instance. FirebaseMessaging does not support per-app isolation —
  /// it always uses the default app. Tokens are device-wide and are registered
  /// with the subscriber's Pro Firebase project via the Xeboki API.
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  /// Request notification permission and return the FCM token.
  /// Returns null when:
  ///  - Firebase not initialised
  ///  - Permission denied by the user
  Future<String?> getFcmToken() async {
    if (!isInitialised) return null;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
    return messaging.getToken();
  }
}
