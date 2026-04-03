import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/config/app_config.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/types.dart';

// ── API Key Validation ────────────────────────────────────────────────────────

/// Holds the outcome of the startup API-key + subscription validation.
/// [null]  → not yet checked
/// Left    → validation failed (status + human-readable message)
/// Right   → success
typedef ValidationOutcome = ({KeyValidationStatus status, String message})?;

class _ApiValidationNotifier
    extends StateNotifier<AsyncValue<KeyValidationStatus>> {
  final OrderingClient client;
  _ApiValidationNotifier(this.client) : super(const AsyncValue.loading());

  Future<void> validate() async {
    state = const AsyncValue.loading();
    try {
      await client.validateApiKey();
      state = const AsyncValue.data(KeyValidationStatus.valid);
    } on XebokiSubscriptionError catch (e) {
      // Subscription-level 403 — structured code from the SDK.
      // The _Http circuit breaker is now armed; all further calls on this
      // client will throw XebokiSubscriptionError immediately.
      state = AsyncValue.data(e.toStatus());
    } on XebokiError catch (e) {
      // 401 = key invalid/revoked — hard block, no retry.
      // 404 = validate endpoint not yet deployed — fail open.
      // 5xx = server error — fail open (don't punish users for our outage).
      if (e.status == 401) {
        state = const AsyncValue.data(KeyValidationStatus.invalidKey);
      } else {
        // 404 / 5xx — fail open
        state = const AsyncValue.data(KeyValidationStatus.valid);
      }
    } catch (_) {
      // True network failure (no connectivity, DNS, timeout) — show retry.
      state = const AsyncValue.data(KeyValidationStatus.networkError);
    }
  }
}

final apiValidationProvider = StateNotifierProvider<_ApiValidationNotifier,
    AsyncValue<KeyValidationStatus>>((ref) {
  final client = ref.watch(orderingClientProvider);
  return _ApiValidationNotifier(client);
});

// ── Brand ────────────────────────────────────────────────────────────────────

final brandProvider = Provider<BrandConfig>((_) => BrandConfig.instance);

// ── Ordering client ───────────────────────────────────────────────────────────

final orderingClientProvider = Provider<OrderingClient>((_) {
  return OrderingClient(apiKey: AppConfig.apiKey);
});

// ── UI State ─────────────────────────────────────────────────────────────────

final isDarkModeProvider = StateProvider<bool>((_) => false);

final localeProvider = StateProvider<Locale>((_) => const Locale('en'));
