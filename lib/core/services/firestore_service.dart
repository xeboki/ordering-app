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

  // ── Catalog ───────────────────────────────────────────────────────────────

  /// All active categories ordered by sortOrder.
  Future<List<OrderingCategory>> getCategories({String? locationId}) async {
    Query<Map<String, dynamic>> q = firestore
        .collection('categories')
        .where('is_active', isEqualTo: true)
        .orderBy('sort_order');
    if (locationId != null) {
      q = q.where('location_id', isEqualTo: locationId);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => OrderingCategory.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Paginated products, optionally filtered by category and/or search term.
  Future<List<OrderingProduct>> getProducts({
    String? categoryId,
    String? search,
    String? locationId,
    int limit = 40,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = firestore
        .collection('products')
        .where('is_active', isEqualTo: true)
        .orderBy('name')
        .limit(limit);
    if (categoryId != null) {
      q = q.where('category_id', isEqualTo: categoryId);
    }
    if (locationId != null) {
      q = q.where('location_id', isEqualTo: locationId);
    }
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    var products = snap.docs
        .map((d) => OrderingProduct.fromJson({...d.data(), 'id': d.id}))
        .toList();

    // Client-side search filter (Firestore doesn't support full-text)
    if (search != null && search.trim().isNotEmpty) {
      final lower = search.trim().toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(lower) ||
              (p.description?.toLowerCase().contains(lower) ?? false))
          .toList();
    }
    return products;
  }

  /// Single product by document ID.
  Future<OrderingProduct?> getProduct(String id) async {
    final doc = await firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;
    return OrderingProduct.fromJson({...doc.data()!, 'id': doc.id});
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  /// Real-time stream of a single order document.
  Stream<Map<String, dynamic>?> orderStream(String orderId) {
    return firestore.collection('orders').doc(orderId).snapshots().map(
      (snap) => snap.exists ? snap.data() : null,
    );
  }

  /// Fetch a customer's order history, newest first.
  Future<List<OrderingOrder>> getOrders({
    String? customerId,
    String? status,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> q = firestore
        .collection('orders')
        .orderBy('created_at', descending: true)
        .limit(limit);
    if (customerId != null) {
      q = q.where('customer_id', isEqualTo: customerId);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => OrderingOrder.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Fetch a single order by ID.
  Future<OrderingOrder?> getOrder(String id) async {
    final doc = await firestore.collection('orders').doc(id).get();
    if (!doc.exists) return null;
    return OrderingOrder.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Real-time stream of a customer's active orders.
  Stream<List<OrderingOrder>> watchActiveOrders(String customerId) {
    return firestore
        .collection('orders')
        .where('customer_id', isEqualTo: customerId)
        .where('status', whereIn: ['pending', 'confirmed', 'preparing', 'ready'])
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OrderingOrder.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  // ── Customers ─────────────────────────────────────────────────────────────

  /// Fetch a customer document by ID.
  Future<OrderingCustomer?> getCustomer(String id) async {
    final doc = await firestore.collection('customers').doc(id).get();
    if (!doc.exists) return null;
    return OrderingCustomer.fromJson({...doc.data()!, 'id': doc.id});
  }

  // ── Discounts ─────────────────────────────────────────────────────────────

  /// Look up an active discount by code.
  /// Returns null when the code doesn't exist or is inactive.
  Future<Map<String, dynamic>?> getDiscount(String code) async {
    final snap = await firestore
        .collection('discounts')
        .where('code', isEqualTo: code.toUpperCase())
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return {...d.data(), 'id': d.id};
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
