import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';
import 'cart_providers.dart';

// ── Delivery state machine ────────────────────────────────────────────────────

sealed class DeliveryState {
  const DeliveryState();
}

class DeliveryIdle extends DeliveryState {
  const DeliveryIdle();
}

class DeliveryValidating extends DeliveryState {
  const DeliveryValidating();
}

class DeliveryValid extends DeliveryState {
  final PostcodeValidationResult result;
  const DeliveryValid(this.result);
}

class DeliveryOutOfRange extends DeliveryState {
  final double distanceKm;
  const DeliveryOutOfRange(this.distanceKm);
}

class DeliveryInvalid extends DeliveryState {
  final String message;
  const DeliveryInvalid(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final OrderingClient _client;
  final Ref _ref;

  DeliveryNotifier(this._client, this._ref) : super(const DeliveryIdle());

  void reset() {
    _ref.read(cartProvider.notifier).setDeliveryFee(0);
    state = const DeliveryIdle();
  }

  /// Validates [postcode] server-side, then updates cart delivery fee.
  ///
  /// Server returns zone + distance. If out of range, sets [DeliveryOutOfRange].
  /// If valid, sets [DeliveryValid] and writes the zone fee into the cart.
  Future<void> validatePostcode(String postcode, {String? locationId}) async {
    state = const DeliveryValidating();
    try {
      final result = await _client.validatePostcode(
        postcode,
        locationId: locationId,
      );

      if (!result.valid) {
        _ref.read(cartProvider.notifier).setDeliveryFee(0);
        state = DeliveryInvalid(result.reason ?? 'Invalid postcode');
        return;
      }

      if (result.zone == null) {
        // Valid postcode but no zone covers the distance → out of range
        _ref.read(cartProvider.notifier).setDeliveryFee(0);
        state = DeliveryOutOfRange(result.distanceKm ?? 0);
        return;
      }

      final zone = result.zone!;
      final cartTotal = _ref.read(cartProvider).subtotal;

      // Apply free delivery threshold — if order meets it, fee is zero
      final fee = (zone.freeThreshold > 0 && cartTotal >= zone.freeThreshold)
          ? 0.0
          : zone.fee;

      _ref.read(cartProvider.notifier).setDeliveryFee(fee);
      state = DeliveryValid(result);
    } on XebokiError catch (e) {
      _ref.read(cartProvider.notifier).setDeliveryFee(0);
      state = DeliveryInvalid(e.message);
    } catch (e) {
      _ref.read(cartProvider.notifier).setDeliveryFee(0);
      state = DeliveryInvalid(e.toString());
    }
  }

  /// Apply the default flat delivery fee from brand config when no zone
  /// pricing is configured (used when `delivery/zones` returns empty).
  void applyFlatFee(double fee, {required double orderTotal, required double freeThreshold}) {
    final effective = (freeThreshold > 0 && orderTotal >= freeThreshold) ? 0.0 : fee;
    _ref.read(cartProvider.notifier).setDeliveryFee(effective);
    state = DeliveryValid(
      // Synthetic result — no postcode, just a flat fee applied
      _Flat.flat(),
    );
  }
}

extension _Flat on PostcodeValidationResult {
  /// Sentinel for flat-fee mode (no real postcode validation).
  static PostcodeValidationResult flat() =>
      PostcodeValidationResult.fromJson({'valid': true});
}

// ── Provider ──────────────────────────────────────────────────────────────────

final deliveryProvider =
    StateNotifierProvider.autoDispose<DeliveryNotifier, DeliveryState>(
  (ref) => DeliveryNotifier(ref.watch(orderingClientProvider), ref),
);
