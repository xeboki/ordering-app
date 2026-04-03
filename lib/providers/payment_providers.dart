import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xeboki_ordering/core/services/stripe_service.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';

// ── Payment state machine ─────────────────────────────────────────────────────

sealed class PaymentState {
  const PaymentState();
}

class PaymentIdle extends PaymentState {
  const PaymentIdle();
}

class PaymentCreatingIntent extends PaymentState {
  const PaymentCreatingIntent();
}

class PaymentAwaitingSheet extends PaymentState {
  final StripePaymentIntent intent;
  const PaymentAwaitingSheet(this.intent);
}

class PaymentConfirming extends PaymentState {
  final String paymentIntentId;
  const PaymentConfirming(this.paymentIntentId);
}

class PaymentSuccess extends PaymentState {
  final OrderingOrder order;
  const PaymentSuccess(this.order);
}

/// Terminal state for any failure — Stripe cancellation is handled separately.
class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
}

/// User cancelled the Stripe sheet — not an error, just go back.
class PaymentCancelled extends PaymentState {
  const PaymentCancelled();
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PaymentNotifier extends StateNotifier<PaymentState> {
  final OrderingClient _client;

  PaymentNotifier(this._client) : super(const PaymentIdle());

  void reset() => state = const PaymentIdle();

  // ── Stripe (card / Apple Pay / Google Pay) ───────────────────────────────────

  /// Full Stripe flow:
  ///   1. Create PaymentIntent on server
  ///   2. Present Stripe PaymentSheet
  ///   3. On success, confirm with server to record the payment
  Future<void> payWithStripe(
    String orderId, {
    required double amount,
    required String currencyCode,
    required String merchantDisplayName,
  }) async {
    state = const PaymentCreatingIntent();

    StripePaymentIntent intent;
    try {
      intent = await _client.createStripePaymentIntent(orderId);
    } catch (e) {
      state = PaymentError(_friendlyError(e));
      return;
    }

    state = PaymentAwaitingSheet(intent);

    final result = await StripeService.instance.presentPaymentSheet(
      intent,
      merchantDisplayName: merchantDisplayName,
      currencyCode: currencyCode,
      amount: amount,
    );

    switch (result) {
      case StripePaymentCancelled():
        state = const PaymentCancelled();
      case StripePaymentFailed(:final message):
        state = PaymentError(message);
      case StripePaymentSuccess(:final paymentIntentId):
        state = PaymentConfirming(paymentIntentId);
        try {
          final order = await _client.confirmStripePayment(
            orderId,
            paymentIntentId,
          );
          state = PaymentSuccess(order);
        } catch (e) {
          // Intent was charged — don't report as a hard error; just note it.
          state = PaymentError(
            'Payment captured but order update failed. '
            'Please contact support with reference: $paymentIntentId',
          );
        }
    }
  }

  // ── In-person / pay-later (cash, card-on-pickup, etc.) ───────────────────────

  /// Records the order as pay-later (method provided at door / counter).
  /// No Stripe flow — just confirms the order client-side.
  Future<void> payInPerson(
    String orderId, {
    required String method,
    required double amount,
  }) async {
    state = const PaymentCreatingIntent(); // reuse loading indicator
    try {
      final order = await _client.payOrder(
        orderId,
        method: method,
        amount: amount,
      );
      state = PaymentSuccess(order);
    } catch (e) {
      state = PaymentError(_friendlyError(e));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    if (e is XebokiError) return e.message;
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.substring(11);
    return s;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final paymentProvider =
    StateNotifierProvider.autoDispose<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(ref.watch(orderingClientProvider)),
);

// ── Convenience selectors ────────────────────────────────────────────────────

final isPaymentLoadingProvider = Provider.autoDispose<bool>((ref) {
  final s = ref.watch(paymentProvider);
  return s is PaymentCreatingIntent ||
      s is PaymentAwaitingSheet ||
      s is PaymentConfirming;
});
