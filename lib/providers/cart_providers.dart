import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';
import 'auth_providers.dart';



class CartNotifier extends StateNotifier<Cart> {
  final OrderingClient _client;
  final Ref _ref;

  CartNotifier(this._client, this._ref) : super(const Cart());

  void addProduct(
    OrderingProduct product, {
    List<SelectedModifier> modifiers = const [],
    SelectedSize? selectedSize,
    String? notes,
  }) {
    final existing = state.items.where(
      (i) =>
          i.productId == product.id &&
          _sameModifiers(i.modifiers, modifiers) &&
          i.selectedSize?.sizeId == selectedSize?.sizeId,
    );
    if (existing.isNotEmpty) {
      final item = existing.first;
      _updateItem(item.id, item.quantity + 1);
    } else {
      final items = [
        ...state.items,
        CartItem(
          productId: product.id,
          productName: product.name,
          productImageUrl: product.imageUrl,
          baseUnitPrice: product.price,
          modifiers: modifiers,
          selectedSize: selectedSize,
          notes: notes,
        ),
      ];
      state = state.copyWith(items: items);
    }
  }

  void _updateItem(String itemId, int qty) {
    final items = state.items.map((i) {
      if (i.id != itemId) return i;
      return i.copyWith(quantity: qty);
    }).toList();
    state = state.copyWith(items: items);
  }

  void increment(String itemId) {
    final item = state.items.firstWhere((i) => i.id == itemId);
    _updateItem(itemId, item.quantity + 1);
  }

  void decrement(String itemId) {
    final item = state.items.firstWhere((i) => i.id == itemId);
    if (item.quantity <= 1) {
      remove(itemId);
    } else {
      _updateItem(itemId, item.quantity - 1);
    }
  }

  void remove(String itemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
  }

  void clear() => state = const Cart();

  Future<void> applyDiscount(String code) async {
    final result = await _client.validateDiscount(
      code,
      orderTotal: state.subtotal,
    );
    if (result.valid && result.discountAmount != null) {
      state = state.copyWith(
        discountCode: code,
        discountAmount: result.discountAmount!,
      );
    } else {
      throw Exception(result.reason ?? 'Invalid discount code');
    }
  }

  void clearDiscount() {
    state = state.copyWith(discountCode: null, discountAmount: 0);
  }

  void setDeliveryFee(double fee) => state = state.copyWith(deliveryFee: fee);
  void setTip(double tip) => state = state.copyWith(tip: tip);
  void setVatRate(double rate) => state = state.copyWith(vatRate: rate);

  /// Apply an automatically computed discount (dine-in / collection).
  /// Only applies if no manual discount code is already active.
  void applyAutoDiscount(double amount) {
    if (state.discountCode != null) return; // don't override manual code
    state = state.copyWith(discountAmount: amount);
  }

  /// Create an order without recording a payment and without clearing the cart.
  ///
  /// Use this when payment will be collected asynchronously (e.g. Stripe).
  /// After payment succeeds call [clear] manually.
  Future<String> createOrderOnly({
    required String orderType,
    String? notes,
    String? tableId,
    String? deliveryAddress,
    DateTime? scheduledAt,
    int? loyaltyPointsToRedeem,
    String? giftCardCode,
    bool applyStoreCredit = false,
  }) async {
    final customerId = _ref.read(authProvider)?.customer.id;
    final items = state.items
        .map((i) => {
              'product_id': i.productId,
              'product_name': i.productName,
              'quantity': i.quantity,
              'unit_price': i.unitPrice,
              'modifiers': i.modifiers
                  .map((m) => {
                        'modifier_id': m.modifierId,
                        'modifier_name': m.modifierName,
                        'price_adjustment': m.priceAdjustment,
                      })
                  .toList(),
              if (i.notes != null) 'notes': i.notes,
            })
        .toList();

    final order = await _client.createOrder(
      orderType: orderType,
      items: items,
      customerId: customerId,
      notes: notes?.isNotEmpty == true ? notes : null,
      tableId: tableId,
      deliveryAddress: deliveryAddress,
      scheduledAt: scheduledAt?.toIso8601String(),
      loyaltyPointsRedeemed: loyaltyPointsToRedeem,
      deliveryFee: state.deliveryFee > 0 ? state.deliveryFee : null,
      tip: state.tip > 0 ? state.tip : null,
      giftCardCode: giftCardCode,
      applyStoreCredit: applyStoreCredit,
    );

    return order.id;
  }

  /// Place the order via the Xeboki SDK.
  ///
  /// Returns the created order ID.
  Future<String> placeOrder({
    required String orderType,
    String? notes,
    String? tableId,
    String? paymentMethod,
    String? deliveryAddress,
    DateTime? scheduledAt,
    int? loyaltyPointsToRedeem,
    String? giftCardCode,
    bool applyStoreCredit = false,
  }) async {
    final customerId = _ref.read(authProvider)?.customer.id;
    final items = state.items
        .map((i) => {
              'product_id': i.productId,
              'product_name': i.productName,
              'quantity': i.quantity,
              'unit_price': i.unitPrice,
              'modifiers': i.modifiers
                  .map((m) => {
                        'modifier_id': m.modifierId,
                        'modifier_name': m.modifierName,
                        'price_adjustment': m.priceAdjustment,
                      })
                  .toList(),
              if (i.notes != null) 'notes': i.notes,
            })
        .toList();

    final order = await _client.createOrder(
      orderType: orderType,
      items: items,
      customerId: customerId,
      notes: notes?.isNotEmpty == true ? notes : null,
      tableId: tableId,
      deliveryAddress: deliveryAddress,
      scheduledAt: scheduledAt?.toIso8601String(),
      loyaltyPointsRedeemed: loyaltyPointsToRedeem,
      deliveryFee: state.deliveryFee > 0 ? state.deliveryFee : null,
      tip: state.tip > 0 ? state.tip : null,
      giftCardCode: giftCardCode,
      applyStoreCredit: applyStoreCredit,
    );

    if (paymentMethod != null) {
      await _client.payOrder(
        order.id,
        method: paymentMethod,
        amount: order.total,
      );
    }

    clear();
    return order.id;
  }

  bool _sameModifiers(List<SelectedModifier> a, List<SelectedModifier> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((m) => m.modifierId).toSet();
    final bIds = b.map((m) => m.modifierId).toSet();
    return aIds.containsAll(bIds) && bIds.containsAll(aIds);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier(ref.watch(orderingClientProvider), ref);
});

final cartItemCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).itemCount,
);
