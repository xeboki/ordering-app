import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

// ── Loyalty config ────────────────────────────────────────────────────────────

/// Merchant's loyalty programme settings (threshold, value, etc.).
/// Cached for the session — changes rarely.
final loyaltyConfigProvider =
    FutureProvider.autoDispose<LoyaltyConfig>((ref) async {
  final client = ref.watch(orderingClientProvider);
  return client.getLoyaltyConfig();
});

// ── Loyalty transactions ──────────────────────────────────────────────────────

/// Recent loyalty transactions for the logged-in customer.
/// null stream when no customer is logged in.
final loyaltyTransactionsProvider =
    FutureProvider.autoDispose<List<LoyaltyTransaction>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth == null) return [];
  final client = ref.watch(orderingClientProvider);
  return client.getLoyaltyTransactions(auth.customer.id, limit: 30);
});

// ── Discounts / offers ────────────────────────────────────────────────────────

/// Active public offers and discount codes.
final offersProvider =
    FutureProvider.autoDispose<List<OrderingDiscount>>((ref) async {
  final client = ref.watch(orderingClientProvider);
  return client.listDiscounts();
});
