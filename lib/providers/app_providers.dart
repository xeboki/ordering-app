import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// ── Store config (auto-detected from POS) ────────────────────────────────────

/// Fetches business config from the POS API and merges it into BrandConfig.
/// Called once after API key validation succeeds. Non-fatal on failure —
/// brand.json fallbacks remain in effect.
final storeConfigProvider =
    FutureProvider.autoDispose<StoreConfig?>((ref) async {
  final client = ref.watch(orderingClientProvider);
  try {
    final config = await client.fetchStoreConfig();
    BrandConfig.applyStoreConfig(config);
    return config;
  } catch (_) {
    // Non-fatal: brand.json fallbacks stay in effect
    return null;
  }
});

// ── Brand ────────────────────────────────────────────────────────────────────

final brandProvider = Provider<BrandConfig>((_) => BrandConfig.instance);

// ── Ordering client ───────────────────────────────────────────────────────────

final orderingClientProvider = Provider<OrderingClient>((_) {
  return OrderingClient(apiKey: AppConfig.apiKey);
});

// ── Location discovery ────────────────────────────────────────────────────────

const _kSelectedLocationKey = 'xbk_selected_location_id';

/// All ordering-enabled locations returned by the API after validation.
final locationsProvider =
    StateNotifierProvider<_LocationsNotifier, AsyncValue<List<StoreLocation>>>(
  (ref) => _LocationsNotifier(ref.watch(orderingClientProvider)),
);

class _LocationsNotifier
    extends StateNotifier<AsyncValue<List<StoreLocation>>> {
  final OrderingClient client;
  _LocationsNotifier(this.client) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final locs = await client.listLocations();
      state = AsyncValue.data(locs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// The currently active location ID — persisted across restarts.
/// Null until locations are loaded; auto-selected when only one exists.
final selectedLocationIdProvider =
    StateNotifierProvider<_SelectedLocationNotifier, String?>(
  (ref) => _SelectedLocationNotifier(),
);

class _SelectedLocationNotifier extends StateNotifier<String?> {
  _SelectedLocationNotifier() : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kSelectedLocationKey);
  }

  Future<void> select(String locationId) async {
    state = locationId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedLocationKey, locationId);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSelectedLocationKey);
  }
}

// ── UI State ─────────────────────────────────────────────────────────────────

final isDarkModeProvider = StateProvider<bool>((_) => false);

final localeProvider = StateProvider<Locale>((_) => const Locale('en'));
