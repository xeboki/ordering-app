import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';
import 'cart_providers.dart';

// ── Meal Deal List ────────────────────────────────────────────────────────────

/// Fetches meal deals from the API. Cached until the provider is disposed.
final mealDealsProvider =
    FutureProvider.autoDispose<List<MealDeal>>((ref) async {
  final client = ref.watch(orderingClientProvider);
  return client.listMealDeals();
});

// ── Slot selection model ──────────────────────────────────────────────────────

class SlotSelection {
  const SlotSelection({
    required this.product,
    this.modifiers = const [],
    this.selectedSize,
  });
  final OrderingProduct product;
  final List<SelectedModifier> modifiers;
  final SelectedSize? selectedSize;
}

// ── Active Meal Deal (currently being configured) ─────────────────────────────

class MealDealState {
  const MealDealState({
    required this.deal,
    required this.selections,
  });

  final MealDeal deal;

  /// Maps slotId → chosen product + options.
  final Map<String, SlotSelection> selections;

  bool get isComplete =>
      deal.slots.every((s) => selections.containsKey(s.id));

  MealDealState withSelection(String slotId, SlotSelection sel) =>
      MealDealState(deal: deal, selections: {...selections, slotId: sel});

  MealDealState withoutSelection(String slotId) {
    final copy = Map<String, SlotSelection>.from(selections);
    copy.remove(slotId);
    return MealDealState(deal: deal, selections: copy);
  }
}

class MealDealNotifier extends StateNotifier<MealDealState?> {
  final Ref _ref;

  MealDealNotifier(this._ref) : super(null);

  void startDeal(MealDeal deal) =>
      state = MealDealState(deal: deal, selections: {});

  void cancel() => state = null;

  void selectForSlot(
    String slotId,
    OrderingProduct product, {
    List<SelectedModifier> modifiers = const [],
    SelectedSize? selectedSize,
  }) {
    if (state == null) return;
    state = state!.withSelection(
      slotId,
      SlotSelection(
          product: product, modifiers: modifiers, selectedSize: selectedSize),
    );
  }

  void clearSlot(String slotId) {
    if (state == null) return;
    state = state!.withoutSelection(slotId);
  }

  /// Adds all slot items to the cart at their normal prices, then applies
  /// the deal's savings as a cart discount.
  void addToCart() {
    final s = state;
    if (s == null || !s.isComplete) return;

    final cart = _ref.read(cartProvider.notifier);

    for (final sel in s.selections.values) {
      cart.addProduct(
        sel.product,
        modifiers: sel.modifiers,
        selectedSize: sel.selectedSize,
      );
    }

    // Apply savings as a cart discount (only when no manual code is active)
    if (s.deal.savings > 0) {
      cart.applyAutoDiscount(s.deal.savings);
    }

    state = null;
  }
}

final mealDealNotifierProvider =
    StateNotifierProvider.autoDispose<MealDealNotifier, MealDealState?>(
  (ref) => MealDealNotifier(ref),
);
