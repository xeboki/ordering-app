import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';

// ── Nash delivery tracking ────────────────────────────────────────────────────

/// Polls the Nash delivery tracking endpoint every [_pollInterval].
///
/// Returns null when:
///  - The order has no Nash delivery (404)
///  - Polling is not yet complete
///
/// The provider auto-disposes when the tracking screen is closed, stopping
/// the timer automatically.
const Duration _pollInterval = Duration(seconds: 10);

class DeliveryTrackingNotifier
    extends StateNotifier<AsyncValue<NashDeliveryTracking?>> {
  final OrderingClient _client;
  final String _orderId;
  Timer? _timer;

  DeliveryTrackingNotifier(this._client, this._orderId)
      : super(const AsyncValue.loading()) {
    _fetch();
    _timer = Timer.periodic(_pollInterval, (_) => _fetch());
  }

  Future<void> _fetch() async {
    try {
      final tracking = await _client.getDeliveryTracking(_orderId);
      if (mounted) state = AsyncValue.data(tracking);
      // Stop polling once the delivery is no longer active
      if (!tracking.isActive) _timer?.cancel();
    } on XebokiError catch (e) {
      if (e.status == 404) {
        // No Nash delivery on this order — stop polling silently
        if (mounted) state = const AsyncValue.data(null);
        _timer?.cancel();
      } else {
        if (mounted) state = AsyncValue.data(state.valueOrNull);
      }
    } catch (_) {
      // Network error — keep last good value, retry on next tick
      if (mounted && state is AsyncLoading) {
        state = const AsyncValue.data(null);
      }
    }
  }

  void refresh() => _fetch();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final deliveryTrackingProvider = StateNotifierProvider.autoDispose
    .family<DeliveryTrackingNotifier, AsyncValue<NashDeliveryTracking?>,
        String>(
  (ref, orderId) {
    final client = ref.watch(orderingClientProvider);
    return DeliveryTrackingNotifier(client, orderId);
  },
);
