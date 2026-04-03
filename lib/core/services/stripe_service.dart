import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/types.dart';

/// Result of a Stripe payment attempt.
sealed class StripePaymentResult {
  const StripePaymentResult();
}

class StripePaymentSuccess extends StripePaymentResult {
  final String paymentIntentId;
  const StripePaymentSuccess(this.paymentIntentId);
}

class StripePaymentCancelled extends StripePaymentResult {
  const StripePaymentCancelled();
}

class StripePaymentFailed extends StripePaymentResult {
  final String message;
  const StripePaymentFailed(this.message);
}

/// Wraps the flutter_stripe SDK.
///
/// All payment flows (card, Apple Pay, Google Pay) go through here.
/// Initialised once in main.dart via [StripeService.init].
class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  /// Call from main.dart after BrandConfig.load().
  static void init() {
    final key = BrandConfig.instance.checkout.stripePublishableKey;
    if (key.isEmpty) return; // Stripe not configured for this white-label
    Stripe.publishableKey = key;
    Stripe.merchantIdentifier = 'merchant.com.xeboki.ordering';
  }

  /// Whether Stripe is configured for this white-label build.
  bool get isConfigured =>
      BrandConfig.instance.checkout.stripePublishableKey.isNotEmpty &&
      BrandConfig.instance.features.stripePayments;

  bool get isApplePayEnabled =>
      isConfigured && BrandConfig.instance.features.applePay;

  bool get isGooglePayEnabled =>
      isConfigured && BrandConfig.instance.features.googlePay;

  // ── PaymentSheet (card / Apple Pay / Google Pay) ─────────────────────────────

  /// Presents the Stripe PaymentSheet and returns the result.
  ///
  /// [intent] comes from the server via [OrderingClient.createStripePaymentIntent].
  Future<StripePaymentResult> presentPaymentSheet(
    StripePaymentIntent intent, {
    required String merchantDisplayName,
    required String currencyCode,
    required double amount,
  }) async {
    try {
      final brand = BrandConfig.instance;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: merchantDisplayName,
          googlePay: brand.features.googlePay
              ? PaymentSheetGooglePay(
                  merchantCountryCode: 'US',
                  currencyCode: currencyCode.toUpperCase(),
                  testEnv: intent.publishableKey.startsWith('pk_test'),
                )
              : null,
          applePay: brand.features.applePay
              ? PaymentSheetApplePay(
                  merchantCountryCode: 'US',
                )
              : null,
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return StripePaymentSuccess(intent.paymentIntentId);
    } on StripeException catch (e) {
      final code = e.error.code;
      if (code == FailureCode.Canceled) {
        return const StripePaymentCancelled();
      }
      return StripePaymentFailed(
        e.error.localizedMessage ?? e.error.message ?? 'Payment failed',
      );
    } catch (e) {
      return StripePaymentFailed(e.toString());
    }
  }
}
