import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/services/firestore_service.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

// ── Order history — direct Firestore read ─────────────────────────────────────

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderingOrder>>> {
  final String? _customerId;

  OrdersNotifier(this._customerId) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final orders = await FirestoreService.instance.getOrders(
        customerId: _customerId,
        limit: 50,
      );
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderingOrder>>>(
  (ref) {
    final customerId = ref.watch(authProvider)?.customer.id;
    return OrdersNotifier(customerId);
  },
);

// ── Active orders — real-time Firestore stream ────────────────────────────────

/// Live stream of the customer's in-progress orders.
/// Updates push automatically — no polling needed.
final activeOrdersProvider =
    StreamProvider<List<OrderingOrder>>((ref) {
  final customerId = ref.watch(authProvider)?.customer.id;
  if (customerId == null) return const Stream.empty();
  return FirestoreService.instance.watchActiveOrders(customerId);
});

// ── Single order — fetch once ─────────────────────────────────────────────────

/// Fetch a single order by ID (one-shot, invalidate to refresh).
final orderDetailProvider =
    FutureProvider.family<OrderingOrder?, String>((ref, orderId) {
  return FirestoreService.instance.getOrder(orderId);
});

// ── Single order — real-time stream ──────────────────────────────────────────

/// Real-time stream of a single order document.
final orderStreamProvider =
    StreamProvider.family<OrderingOrder?, String>((ref, orderId) {
  return FirestoreService.instance.orderStream(orderId).map((data) {
    if (data == null) return null;
    return OrderingOrder.fromJson({...data, 'id': orderId});
  });
});

/// Alias used by order_tracking_screen — live Firestore stream.
final orderLiveProvider = orderStreamProvider;

// ── Appointments — direct Firestore read ──────────────────────────────────────

class AppointmentsNotifier
    extends StateNotifier<AsyncValue<List<OrderingAppointment>>> {
  final String? _customerId;
  final String? _locationId;

  AppointmentsNotifier(this._customerId, this._locationId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final fs = FirestoreService.instance.firestore;
      Query<Map<String, dynamic>> q = fs
          .collection('appointments')
          .orderBy('date', descending: true)
          .limit(50);
      if (_customerId != null) {
        q = q.where('customer_id', isEqualTo: _customerId);
      }
      if (_locationId != null) {
        q = q.where('location_id', isEqualTo: _locationId);
      }
      final snap = await q.get();
      final appts = snap.docs
          .map((d) => OrderingAppointment.fromJson(
              {...d.data(), 'id': d.id}))
          .toList();
      state = AsyncValue.data(appts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();
}

final appointmentsProvider = StateNotifierProvider<AppointmentsNotifier,
    AsyncValue<List<OrderingAppointment>>>((ref) {
  final customerId = ref.watch(authProvider)?.customer.id;
  final locationId = ref.watch(selectedLocationIdProvider);
  return AppointmentsNotifier(customerId, locationId);
});
