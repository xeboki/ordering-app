import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';
import 'cart_providers.dart';

// ── Upsell provider ───────────────────────────────────────────────────────────

/// Returns recommended products based on the current cart contents.
///
/// Watches [cartProvider] so the upsells refresh when items change.
/// Returns an empty list when the cart is empty (nothing to base recs on).
/// Auto-disposes when the cart screen closes.
final upsellsProvider =
    FutureProvider.autoDispose<List<OrderingProduct>>((ref) async {
  final cart = ref.watch(cartProvider);
  if (cart.isEmpty) return [];

  final productIds = cart.items.map((i) => i.productId).toList();
  final client = ref.watch(orderingClientProvider);
  return client.getUpsells(productIds);
});
