import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/services/firestore_service.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderingOrder>>> {
  final OrderingClient _client;
  final String? _customerId;

  OrdersNotifier(this._client, this._customerId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final result = await _client.listOrders(
        customerId: _customerId,
        limit: 50,
      );
      state = AsyncValue.data(result.data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderingOrder>>>(
  (ref) {
    final client = ref.watch(orderingClientProvider);
    final customerId = ref.watch(authProvider)?.customer.id;
    return OrdersNotifier(client, customerId);
  },
);

final activeOrdersProvider = Provider<List<OrderingOrder>>((ref) {
  return ref.watch(ordersProvider).valueOrNull
          ?.where((o) => o.isActive)
          .toList() ??
      [];
});

final orderDetailProvider =
    FutureProvider.family<OrderingOrder, String>((ref, id) {
  return ref.watch(orderingClientProvider).getOrder(id);
});

/// Live Firestore stream for a single order.
///
/// When the merchant's Pro Firebase is initialised ([FirestoreService.isInitialised])
/// this emits real-time status updates from Firestore — no polling needed.
///
/// Falls back to null stream when Firebase is not configured (REST-only mode),
/// in which case [OrderTrackingScreen] keeps its REST polling fallback.
final orderLiveProvider =
    StreamProvider.autoDispose.family<OrderingOrder?, String>((ref, orderId) {
  if (!FirestoreService.instance.isInitialised) {
    // Firebase not configured — emit nothing; REST polling handles updates.
    return const Stream.empty();
  }

  return FirestoreService.instance.orderStream(orderId).map((data) {
    if (data == null) return null;
    // Firestore camelCase → normalise to the same snake_case the REST API uses
    final normalised = _normaliseFsOrder(orderId, data);
    return OrderingOrder.fromJson(normalised);
  });
});

/// Convert Firestore camelCase order document to the same snake_case shape
/// that [OrderingOrder.fromJson] expects (matching the REST API response).
Map<String, dynamic> _normaliseFsOrder(
    String id, Map<String, dynamic> d) {
  dynamic tsToIso(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    // Firestore Timestamp
    try {
      return (v as dynamic).toDate().toIso8601String();
    } catch (_) {
      return null;
    }
  }

  final rawItems = (d['items'] as List? ?? []);
  final items = rawItems.map((e) {
    final m = e as Map<String, dynamic>;
    return {
      'product_id':    m['productId'] ?? m['product_id'] ?? '',
      'product_name':  m['productName'] ?? m['product_name'] ?? '',
      'quantity':      m['quantity'] ?? 1,
      'unit_price':    (m['unitPrice'] ?? m['unit_price'] ?? 0).toDouble(),
      'total_price':   (m['totalPrice'] ?? m['total_price'] ?? 0).toDouble(),
      'modifier_names': m['modifierNames'] ?? m['modifier_names'] ?? [],
      'notes':         m['notes'],
    };
  }).toList();

  return {
    'id':               id,
    'order_number':     d['orderNumber'] ?? d['order_number'] ?? '',
    'status':           d['status'] ?? 'pending',
    'order_type':       d['orderType'] ?? d['order_type'] ?? 'pickup',
    'subtotal':         (d['subtotal'] ?? 0).toDouble(),
    'tax':              (d['tax'] ?? 0).toDouble(),
    'discount':         (d['discount'] ?? 0).toDouble(),
    'total':            (d['total'] ?? 0).toDouble(),
    'paid_total':       (d['paidTotal'] ?? d['paid_total'] ?? 0).toDouble(),
    'items':            items,
    'customer_id':      d['customerId'] ?? d['customer_id'],
    'table_id':         d['tableId'] ?? d['table_id'],
    'notes':            d['notes'],
    'reference':        d['reference'],
    'delivery_address': d['deliveryAddress'] ?? d['delivery_address'],
    'scheduled_at':     d['scheduledAt'] ?? d['scheduled_at'],
    'created_at':       tsToIso(d['createdAt'] ?? d['created_at']),
  };
}

// ── Appointments ─────────────────────────────────────────────────────────────

class AppointmentsNotifier
    extends StateNotifier<AsyncValue<List<OrderingAppointment>>> {
  final OrderingClient _client;
  final String? _customerId;

  AppointmentsNotifier(this._client, this._customerId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final result = await _client.listAppointments(customerId: _customerId);
      state = AsyncValue.data(result.data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();
}

final appointmentsProvider = StateNotifierProvider<AppointmentsNotifier,
    AsyncValue<List<OrderingAppointment>>>(
  (ref) {
    final client = ref.watch(orderingClientProvider);
    final customerId = ref.watch(authProvider)?.customer.id;
    return AppointmentsNotifier(client, customerId);
  },
);
