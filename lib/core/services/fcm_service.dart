import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:xeboki_ordering/core/services/firestore_service.dart';

/// Top-level background message handler.
///
/// Must be a top-level function (not a class method) so Flutter can call it
/// from an isolate when the app is terminated or in the background.
/// Only performs lightweight work — no UI, no provider access.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // No UI work here — the OS notification is shown automatically by FCM.
  // Heavy work (e.g. DB writes) can be done here if needed.
}

/// Manages FCM for the ordering app.
///
/// Uses the merchant's Pro Firebase project (via [FirestoreService]'s named
/// secondary app). Each white-label build sends/receives via the merchant's
/// own FCM sender ID.
///
/// # Setup per build
/// - Android: `google-services.json` is NOT required (messaging works via the
///   secondary app's messagingSenderId).
/// - iOS: Merchant must upload APNs key/cert to their Pro Firebase console.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  String? _token;
  bool _initialised = false;

  bool get isInitialised => _initialised;
  String? get token => _token;

  /// Initialise FCM. Call once after [FirestoreService.init].
  /// No-op when [FirestoreService] is not initialised.
  Future<void> init() async {
    if (_initialised || !FirestoreService.instance.isInitialised) return;
    _initialised = true;

    // Register background handler (must happen before any other FCM work).
    // Web and macOS use service-worker / extension-based push — no isolate handler.
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS) {
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
    }

    // Request permission + fetch initial token
    _token = await FirestoreService.instance.getFcmToken();

    // Refresh token silently
    FirestoreService.instance.messaging.onTokenRefresh.listen((token) {
      _token = token;
      _onTokenRefreshed(token);
    });
  }

  // ── Foreground message handling ───────────────────────────────────────────

  /// Call from a widget (e.g. HomeScreen) to start listening for foreground
  /// messages. [onMessage] receives the parsed notification so the caller
  /// can show an in-app banner.
  void listenForeground(void Function(OrderStatusNotification) onMessage) {
    FirebaseMessaging.onMessage.listen((message) {
      final notif = _parse(message);
      if (notif != null) onMessage(notif);
    });
  }

  /// Returns the notification the app was opened FROM when it was terminated.
  /// Returns null if the app was opened normally.
  Future<OrderStatusNotification?> getInitialNotification() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message != null ? _parse(message) : null;
  }

  /// Subscribe to notification taps when the app was in the background
  /// (not terminated). Caller navigates based on [OrderStatusNotification.orderId].
  void listenNotificationTap(void Function(OrderStatusNotification) onTap) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final notif = _parse(message);
      if (notif != null) onTap(notif);
    });
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  OrderStatusNotification? _parse(RemoteMessage message) {
    final data = message.data;
    final orderId = data['order_id'] as String?;
    final status = data['status'] as String?;
    if (orderId == null || orderId.isEmpty) return null;
    return OrderStatusNotification(
      orderId: orderId,
      status: status ?? 'updated',
      title: message.notification?.title ?? 'Order Update',
      body: message.notification?.body ?? '',
    );
  }

  /// Called when the FCM token refreshes (e.g. app re-install, token expiry).
  /// Re-registration with the backend happens via the checkout flow the next
  /// time a new order is placed. Nothing needed here for now.
  void _onTokenRefreshed(String token) {
    // Future: call PUT /customers/fcm-token if a customer session is active.
  }
}

/// Parsed push notification about an order status change.
@immutable
class OrderStatusNotification {
  const OrderStatusNotification({
    required this.orderId,
    required this.status,
    required this.title,
    required this.body,
  });

  final String orderId;
  final String status;
  final String title;
  final String body;
}
