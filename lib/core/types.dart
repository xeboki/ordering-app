import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Exception ─────────────────────────────────────────────────────────────────

class XebokiError implements Exception {
  final int status;
  final String message;
  final String? requestId;
  final int? retryAfter;

  const XebokiError({
    required this.status,
    required this.message,
    this.requestId,
    this.retryAfter,
  });

  @override
  String toString() => 'XebokiError($status): $message';
}

/// Thrown by [_Http] whenever the Xeboki API returns a subscription-level 403.
///
/// Acts as a **circuit breaker**: once thrown, every subsequent request on the
/// same [OrderingClient] instance fails immediately without a network call.
/// This means any product built on the SDK — ordering app, kiosk, website SDK —
/// gets subscription gating for free.  No per-product validate call required.
///
/// ```dart
/// try {
///   final products = await client.listProducts();
/// } on XebokiSubscriptionError catch (e) {
///   // e.toStatus() → KeyValidationStatus.freePlanBlocked / noSubscription / etc.
/// }
/// ```
class XebokiSubscriptionError implements Exception {
  final String code;
  final String message;
  final String? requestId;

  const XebokiSubscriptionError({
    required this.code,
    required this.message,
    this.requestId,
  });

  static const _codeToStatus = <String, KeyValidationStatus>{
    'subscription_required':    KeyValidationStatus.noSubscription,
    'free_plan_not_supported':  KeyValidationStatus.freePlanBlocked,
    'ordering_app_not_in_plan': KeyValidationStatus.featureNotInPlan,
  };

  /// Map this error to the matching [KeyValidationStatus] for UI display.
  KeyValidationStatus toStatus() =>
      _codeToStatus[code] ?? KeyValidationStatus.invalidKey;

  /// Reconstruct a [XebokiSubscriptionError] from a known [KeyValidationStatus].
  /// Used internally by the circuit breaker.
  static XebokiSubscriptionError _fromStatus(KeyValidationStatus s) {
    const statusToCode = <KeyValidationStatus, String>{
      KeyValidationStatus.noSubscription:  'subscription_required',
      KeyValidationStatus.freePlanBlocked: 'free_plan_not_supported',
      KeyValidationStatus.featureNotInPlan: 'ordering_app_not_in_plan',
    };
    return XebokiSubscriptionError(
      code: statusToCode[s] ?? 'subscription_required',
      message: 'Subscription access blocked — upgrade your Xeboki POS plan.',
    );
  }

  @override
  String toString() => 'XebokiSubscriptionError($code): $message';
}

// ── Rate limit ────────────────────────────────────────────────────────────────

class RateLimitInfo {
  final int limit, remaining, reset;
  final String requestId;
  const RateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.reset,
    required this.requestId,
  });
}

// ── Models ────────────────────────────────────────────────────────────────────

class OrderingCategory {
  final String id, name;
  final String? icon, color;
  final int sortOrder;
  final bool isActive;

  OrderingCategory.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        icon = j['icon']?.toString(),
        color = j['color']?.toString(),
        sortOrder = j['sort_order'] as int? ?? 0,
        isActive = j['is_active'] as bool? ?? true;
}

// ── Size variants ─────────────────────────────────────────────────────────────

/// A single size option on a product (e.g. Small, Medium, Large).
/// [priceAdjustment] is the delta from the product's base price — can be
/// negative (e.g. Small = -0.50), zero, or positive (Large = +1.00).
class ProductSize {
  final String id, name;
  final double priceAdjustment;
  final bool isDefault;

  ProductSize.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        priceAdjustment = (j['price_adjustment'] as num?)?.toDouble() ?? 0,
        isDefault = j['is_default'] as bool? ?? false;
}

/// The size selected by the customer for a specific cart item.
class SelectedSize {
  final String sizeId, sizeName;
  final double priceAdjustment;

  const SelectedSize({
    required this.sizeId,
    required this.sizeName,
    required this.priceAdjustment,
  });
}

// ── Meal deals ────────────────────────────────────────────────────────────────

/// A slot in a meal deal — the customer picks one product that belongs to
/// the eligible categories/products for that slot.
class MealDealSlot {
  final String id, name;
  final List<String> eligibleCategoryIds;
  final List<String> eligibleProductIds;

  MealDealSlot.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        eligibleCategoryIds = (j['eligible_category_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        eligibleProductIds = (j['eligible_product_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
}

class MealDeal {
  final String id, name;
  /// Fixed bundle price — replaces the sum of individual item prices.
  final double price;
  /// How much the customer saves vs buying separately. 0 = not shown.
  final double savings;
  final String? description, imageUrl;
  final List<MealDealSlot> slots;
  final bool isActive;

  MealDeal.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        price = (j['price'] as num?)?.toDouble() ?? 0,
        savings = (j['savings'] as num?)?.toDouble() ?? 0,
        description = j['description']?.toString(),
        imageUrl = j['image_url']?.toString(),
        slots = (j['slots'] as List? ?? [])
            .map((e) => MealDealSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        isActive = j['is_active'] as bool? ?? true;
}

// ── Modifier option (existing) ────────────────────────────────────────────────

class ModifierOption {
  final String id, name;
  final double priceAdjustment;
  final bool isAvailable;

  ModifierOption.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        priceAdjustment = (j['price_adjustment'] as num?)?.toDouble() ?? 0,
        isAvailable = j['is_available'] as bool? ?? true;
}

class ModifierGroup {
  final String id, name;
  final bool required;
  final int? minSelections, maxSelections;
  final List<ModifierOption> options;

  ModifierGroup.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        required = j['required'] as bool? ?? false,
        minSelections = j['min_selections'] as int?,
        maxSelections = j['max_selections'] as int?,
        options = (j['options'] as List? ?? [])
            .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
            .toList();
}

class OrderingProduct {
  final String id, name;
  final double price;
  final bool isActive, trackInventory;
  final String? description, imageUrl, categoryId, categoryName;
  final int? stockQuantity;
  final List<ModifierGroup> modifierGroups;
  final List<String> tags;
  /// Non-empty when the product has size variants (e.g. S / M / L).
  /// Empty list = no size selection needed.
  final List<ProductSize> sizes;

  OrderingProduct.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        price = (j['price'] as num?)?.toDouble() ?? 0,
        isActive = j['is_active'] as bool? ?? true,
        trackInventory = j['track_inventory'] as bool? ?? false,
        description = j['description']?.toString(),
        imageUrl = j['image_url']?.toString(),
        categoryId = j['category_id']?.toString(),
        categoryName = j['category_name']?.toString(),
        stockQuantity = j['stock_quantity'] as int?,
        modifierGroups = (j['modifier_groups'] as List? ?? [])
            .map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
        tags = (j['tags'] as List? ?? []).map((e) => e.toString()).toList(),
        sizes = (j['sizes'] as List? ?? [])
            .map((e) => ProductSize.fromJson(e as Map<String, dynamic>))
            .toList();

  bool get inStock => !trackInventory || (stockQuantity ?? 1) > 0;
}

class OrderingCustomer {
  final String id, name;
  final String? email, phone;
  final double storeCredit;
  final int loyaltyPoints;

  OrderingCustomer.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = (j['name'] ?? j['full_name'])?.toString() ?? '',
        email = j['email']?.toString(),
        phone = j['phone']?.toString(),
        storeCredit = (j['store_credit'] as num?)?.toDouble() ?? 0,
        loyaltyPoints = j['loyalty_points'] as int? ?? 0;
}

class CustomerAuth {
  final OrderingCustomer customer;
  final String token;

  CustomerAuth({required this.customer, required this.token});

  factory CustomerAuth.fromJson(Map<String, dynamic> j) => CustomerAuth(
        customer: OrderingCustomer.fromJson(
            j['customer'] as Map<String, dynamic>),
        token: j['token']?.toString() ?? '',
      );
}

class OrderingLineItem {
  final String productId, productName;
  final int quantity;
  final double unitPrice, totalPrice;
  final List<String> modifierNames;
  final String? notes;

  OrderingLineItem.fromJson(Map<String, dynamic> j)
      : productId = j['product_id']?.toString() ?? '',
        productName = j['product_name']?.toString() ?? '',
        quantity = j['quantity'] as int? ?? 1,
        unitPrice = (j['unit_price'] as num?)?.toDouble() ?? 0,
        totalPrice = (j['total_price'] as num?)?.toDouble() ?? 0,
        modifierNames = (j['modifier_names'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        notes = j['notes']?.toString();
}

class OrderingOrder {
  final String id, orderNumber, status, orderType;
  final double subtotal, tax, discount, total, paidTotal;
  final List<OrderingLineItem> items;
  final String? customerId, tableId, notes, reference, deliveryAddress,
      scheduledAt;
  final DateTime createdAt;

  OrderingOrder.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        orderNumber = j['order_number']?.toString() ?? '',
        status = j['status']?.toString() ?? 'pending',
        orderType = j['order_type']?.toString() ?? 'pickup',
        subtotal = (j['subtotal'] as num?)?.toDouble() ?? 0,
        tax = (j['tax'] as num?)?.toDouble() ?? 0,
        discount = (j['discount'] as num?)?.toDouble() ?? 0,
        total = (j['total'] as num?)?.toDouble() ?? 0,
        paidTotal = (j['paid_total'] as num?)?.toDouble() ?? 0,
        items = (j['items'] as List? ?? [])
            .map((e) => OrderingLineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        customerId = j['customer_id']?.toString(),
        tableId = j['table_id']?.toString(),
        notes = j['notes']?.toString(),
        reference = j['reference']?.toString(),
        deliveryAddress = j['delivery_address']?.toString(),
        scheduledAt = j['scheduled_at']?.toString(),
        createdAt = j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
            : DateTime.now();

  bool get isActive =>
      ['pending', 'confirmed', 'processing', 'ready'].contains(status);
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}

class DiscountValidation {
  final bool valid;
  final String? type, reason;
  final double? value, discountAmount;

  DiscountValidation.fromJson(Map<String, dynamic> j)
      : valid = j['valid'] as bool? ?? false,
        type = j['type']?.toString(),
        reason = j['reason']?.toString(),
        value = (j['value'] as num?)?.toDouble(),
        discountAmount = (j['discount_amount'] as num?)?.toDouble();
}

class GiftCardInfo {
  final String id, code;
  final double balance, initialValue;
  final String status, currency;
  final String? expiresAt;

  GiftCardInfo.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        code = j['code']?.toString() ?? '',
        balance = (j['balance'] as num?)?.toDouble() ?? 0,
        initialValue = (j['initial_value'] as num?)?.toDouble() ?? 0,
        status = j['status']?.toString() ?? 'active',
        currency = j['currency']?.toString() ?? 'USD',
        expiresAt = j['expires_at']?.toString();

  bool get isUsable => status == 'active' && balance > 0;
}

class OrderingAppointment {
  final String id, status, serviceId, serviceName;
  final String? customerId, customerName, staffId, staffName, notes;
  final DateTime startTime;
  final int durationMinutes;

  OrderingAppointment.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        status = j['status']?.toString() ?? 'pending',
        serviceId = j['service_id']?.toString() ?? '',
        serviceName = j['service_name']?.toString() ?? '',
        customerId = j['customer_id']?.toString(),
        customerName = j['customer_name']?.toString(),
        staffId = j['staff_id']?.toString(),
        staffName = j['staff_name']?.toString(),
        notes = j['notes']?.toString(),
        startTime = j['start_time'] != null
            ? DateTime.tryParse(j['start_time'].toString()) ?? DateTime.now()
            : DateTime.now(),
        durationMinutes = j['duration_minutes'] as int? ?? 60;

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));
}

class OrderingTable {
  final String id, name, status;
  final int? capacity;
  final String? section;

  OrderingTable.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        status = j['status']?.toString() ?? 'available',
        capacity = j['capacity'] as int?,
        section = j['section']?.toString();

  bool get isAvailable => status == 'available';
}

class OrderingStaff {
  final String id, name;
  final String? role, avatarUrl;
  final bool isActive;

  OrderingStaff.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        role = j['role']?.toString(),
        avatarUrl = j['avatar_url']?.toString(),
        isActive = j['is_active'] as bool? ?? true;
}

class OrderingListResponse<T> {
  final List<T> data;
  final int total, limit, offset;

  const OrderingListResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.offset,
  });
}

// ── Cart models ───────────────────────────────────────────────────────────────

class SelectedModifier {
  final String modifierId, modifierName;
  final double priceAdjustment;

  const SelectedModifier({
    required this.modifierId,
    required this.modifierName,
    required this.priceAdjustment,
  });
}

class CartItem {
  final String id;
  final String productId, productName;
  final String? productImageUrl;
  final double baseUnitPrice;
  final List<SelectedModifier> modifiers;
  final SelectedSize? selectedSize;
  final String? notes;
  final int quantity;

  CartItem({
    String? id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.baseUnitPrice,
    this.modifiers = const [],
    this.selectedSize,
    this.notes,
    this.quantity = 1,
  }) : id = id ?? '${productId}_${DateTime.now().microsecondsSinceEpoch}';

  double get unitPrice =>
      baseUnitPrice +
      (selectedSize?.priceAdjustment ?? 0) +
      modifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        baseUnitPrice: baseUnitPrice,
        modifiers: modifiers,
        selectedSize: selectedSize,
        notes: notes,
        quantity: quantity ?? this.quantity,
      );
}

class Cart {
  final List<CartItem> items;
  final String? discountCode;
  final double discountAmount;
  final double deliveryFee;
  final double tip;
  /// VAT rate as a fraction (e.g. 0.20 for 20%).
  /// Set by the checkout screen from business config.
  final double vatRate;

  const Cart({
    this.items = const [],
    this.discountCode,
    this.discountAmount = 0,
    this.deliveryFee = 0,
    this.tip = 0,
    this.vatRate = 0,
  });

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => items.fold(0.0, (s, i) => s + i.lineTotal);
  double get taxAmount => subtotal * vatRate;
  double get total => subtotal - discountAmount + deliveryFee + tip;

  static const Object _absent = Object();

  Cart copyWith({
    List<CartItem>? items,
    Object? discountCode = _absent,
    double? discountAmount,
    double? deliveryFee,
    double? tip,
    double? vatRate,
  }) =>
      Cart(
        items: items ?? this.items,
        discountCode: identical(discountCode, _absent)
            ? this.discountCode
            : discountCode as String?,
        discountAmount: discountAmount ?? this.discountAmount,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        tip: tip ?? this.tip,
        vatRate: vatRate ?? this.vatRate,
      );
}

// ── Delivery models ───────────────────────────────────────────────────────────

class DeliveryZone {
  final String id, name;
  final double minDistanceKm, maxDistanceKm;
  final double fee;
  /// 0 = always charge; > 0 = orders above this amount get free delivery.
  final double freeThreshold;

  DeliveryZone.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        name = j['name']?.toString() ?? '',
        minDistanceKm = (j['min_distance_km'] as num?)?.toDouble() ?? 0,
        maxDistanceKm = (j['max_distance_km'] as num?)?.toDouble() ?? double.infinity,
        fee = (j['fee'] as num?)?.toDouble() ?? 0,
        freeThreshold = (j['free_threshold'] as num?)?.toDouble() ?? 0;
}

class DeliveryZonesResult {
  final List<DeliveryZone> zones;
  final String? storePostcode;
  final double? storeLatitude, storeLongitude;

  DeliveryZonesResult.fromJson(Map<String, dynamic> j)
      : zones = ((j['zones'] as List?) ?? [])
            .map((e) => DeliveryZone.fromJson(e as Map<String, dynamic>))
            .toList(),
        storePostcode = j['store_postcode']?.toString(),
        storeLatitude = (j['store_latitude'] as num?)?.toDouble(),
        storeLongitude = (j['store_longitude'] as num?)?.toDouble();
}

class PostcodeValidationResult {
  final bool valid;
  final double? distanceKm;
  final DeliveryZone? zone;
  final String? reason;

  PostcodeValidationResult.fromJson(Map<String, dynamic> j)
      : valid = j['valid'] as bool? ?? false,
        distanceKm = (j['distance_km'] as num?)?.toDouble(),
        zone = j['zone'] != null
            ? DeliveryZone.fromJson(j['zone'] as Map<String, dynamic>)
            : null,
        reason = j['reason']?.toString();
}

// ── Firebase models ───────────────────────────────────────────────────────────

/// Public Firebase config returned by GET /v1/pos/firestore-config.
/// Contains only fields safe to ship to the client (no service-account key).
/// These are the same values a merchant enters in the Manager app when
/// setting up their Pro Firebase project.
class FirebaseOrderingConfig {
  final String apiKey;
  final String appId;
  final String projectId;
  final String authDomain;
  final String messagingSenderId;
  final String? storageBucket;
  final String? measurementId;

  FirebaseOrderingConfig.fromJson(Map<String, dynamic> j)
      : apiKey = j['api_key']?.toString() ?? '',
        appId = j['app_id']?.toString() ?? '',
        projectId = j['project_id']?.toString() ?? '',
        authDomain = j['auth_domain']?.toString() ?? '',
        messagingSenderId = j['messaging_sender_id']?.toString() ?? '',
        storageBucket = j['storage_bucket']?.toString(),
        measurementId = j['measurement_id']?.toString();
}

/// Returned by firebase-verify and firebase-register — same shape as REST auth.
/// Reuses [CustomerAuth] so the rest of the app sees no difference.

// ── Stripe models ─────────────────────────────────────────────────────────────

class StripePaymentIntent {
  final String clientSecret;
  final String paymentIntentId;
  final String publishableKey;
  final String? connectedAccountId;

  StripePaymentIntent.fromJson(Map<String, dynamic> j)
      : clientSecret = j['client_secret']?.toString() ?? '',
        paymentIntentId = j['payment_intent_id']?.toString() ?? '',
        publishableKey = j['publishable_key']?.toString() ?? '',
        connectedAccountId = j['connected_account_id']?.toString();
}

// ── Store config (auto-detected from POS) ────────────────────────────────────

/// Business configuration fetched from the merchant's POS at startup.
/// These values override any fallbacks in brand.json — the merchant never
/// needs to re-enter them in the ordering app.
class StoreConfig {
  final String businessType;
  final String businessName;
  final String currencyCode;
  final String currencySymbol;
  final String timezone;
  final String taxLabel;
  final double taxRate;
  final String supportEmail;
  final String supportPhone;
  final String website;

  const StoreConfig({
    required this.businessType,
    required this.businessName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.timezone,
    required this.taxLabel,
    required this.taxRate,
    required this.supportEmail,
    required this.supportPhone,
    required this.website,
  });

  factory StoreConfig.fromJson(Map<String, dynamic> j) => StoreConfig(
        businessType:   j['business_type']?.toString() ?? 'retail',
        businessName:   j['business_name']?.toString() ?? '',
        currencyCode:   j['currency_code']?.toString() ?? 'USD',
        currencySymbol: j['currency_symbol']?.toString() ?? '\$',
        timezone:       j['timezone']?.toString() ?? 'UTC',
        taxLabel:       j['tax_label']?.toString() ?? 'Tax',
        taxRate:        (j['tax_rate'] as num?)?.toDouble() ?? 0.0,
        supportEmail:   j['support_email']?.toString() ?? '',
        supportPhone:   j['support_phone']?.toString() ?? '',
        website:        j['website']?.toString() ?? '',
      );
}

// ── Store location ────────────────────────────────────────────────────────────

class StoreLocation {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? timezone;
  final String? currency;
  final bool isActive;

  const StoreLocation({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.timezone,
    this.currency,
    this.isActive = true,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> j) => StoreLocation(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        address: j['address']?.toString(),
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
        timezone: j['timezone']?.toString(),
        currency: j['currency']?.toString(),
        isActive: j['is_active'] as bool? ?? true,
      );
}

// ── Key validation ────────────────────────────────────────────────────────────

enum KeyValidationStatus {
  valid,
  invalidKey,            // 401 — key not found or revoked
  noSubscription,        // 403 code: subscription_required
  freePlanBlocked,       // 403 code: free_plan_not_supported
  featureNotInPlan,      // 403 code: ordering_app_not_in_plan
  noOrderingLocations,   // subscription valid but no branch has ordering_enabled
  networkError,          // connection failure
}

class KeyValidationResult {
  final bool valid;
  final String subscriberId;
  final String subStatus;
  final String subPlan;

  const KeyValidationResult({
    required this.valid,
    required this.subscriberId,
    required this.subStatus,
    required this.subPlan,
  });

  factory KeyValidationResult.fromJson(Map<String, dynamic> j) {
    final sub = j['subscription'] as Map<String, dynamic>?;
    return KeyValidationResult(
      valid:        j['valid'] as bool? ?? false,
      subscriberId: j['subscriber_id']?.toString() ?? '',
      subStatus:    sub?['status']?.toString() ?? '',
      subPlan:      sub?['plan']?.toString() ?? '',
    );
  }
}

// ── HTTP helper ───────────────────────────────────────────────────────────────

class _Http {
  final String apiKey;
  final String baseUrl = 'https://api.xeboki.com';
  final http.Client _client = http.Client();

  /// Circuit breaker — set on the first subscription-level 403.
  /// Every subsequent [request] call throws [XebokiSubscriptionError]
  /// immediately without making a network call.
  KeyValidationStatus? _subscriptionBlock;
  KeyValidationStatus? get subscriptionBlock => _subscriptionBlock;

  _Http({required this.apiKey});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<(T, RateLimitInfo)> request<T>(
    String method,
    String path, {
    Map<String, String?>? query,
    Map<String, dynamic>? body,
    required T Function(dynamic) fromJson,
  }) async {
    // ── Circuit breaker: fail fast once subscription is known to be blocked ──
    if (_subscriptionBlock != null) {
      throw XebokiSubscriptionError._fromStatus(_subscriptionBlock!);
    }

    final params = query?.entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value!))
        .toList();

    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: params != null && params.isNotEmpty
          ? Map.fromEntries(params)
          : null,
    );

    http.Response response;
    final encoded = body != null ? jsonEncode(body) : null;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: _headers);
      case 'POST':
        response = await _client.post(uri, headers: _headers, body: encoded);
      case 'PUT':
        response = await _client.put(uri, headers: _headers, body: encoded);
      case 'PATCH':
        response = await _client.patch(uri, headers: _headers, body: encoded);
      case 'DELETE':
        response = await _client.delete(uri, headers: _headers);
      default:
        throw XebokiError(status: 0, message: 'Unknown method: $method');
    }

    final requestId = response.headers['x-request-id'] ?? '';
    final rl = RateLimitInfo(
      limit: int.tryParse(response.headers['x-ratelimit-limit'] ?? '') ?? 0,
      remaining:
          int.tryParse(response.headers['x-ratelimit-remaining'] ?? '') ?? 0,
      reset: int.tryParse(response.headers['x-ratelimit-reset'] ?? '') ?? 0,
      requestId: requestId,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // ── Check for subscription-level 403 before generic error handling ──
      if (response.statusCode == 403) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final detail = decoded['detail'];
          final String? code = detail is Map<String, dynamic>
              ? detail['code']?.toString()
              : null;
          if (code != null &&
              XebokiSubscriptionError._codeToStatus.containsKey(code)) {
            final err = XebokiSubscriptionError(
              code: code,
              message: (detail['message'] ?? 'Subscription access blocked.')
                  .toString(),
              requestId: requestId,
            );
            _subscriptionBlock = err.toStatus(); // arm the circuit breaker
            throw err;
          }
        } catch (e) {
          if (e is XebokiSubscriptionError) rethrow;
        }
      }

      String message = 'HTTP ${response.statusCode}';
      int? retryAfter;
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        message =
            (decoded['detail'] ?? decoded['message'] ?? message).toString();
      } catch (_) {}
      if (response.statusCode == 429) {
        retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      }
      throw XebokiError(
        status: response.statusCode,
        message: message,
        requestId: requestId,
        retryAfter: retryAfter,
      );
    }

    if (response.statusCode == 204 || response.body.isEmpty) {
      return (fromJson(null), rl);
    }

    return (fromJson(jsonDecode(response.body)), rl);
  }

  void close() => _client.close();
}

// ── Nash delivery tracking ────────────────────────────────────────────────────

/// Real-time delivery tracking state from Nash (or any delivery aggregator).
class NashDeliveryTracking {
  /// Unique Nash delivery / job ID.
  final String deliveryId;
  /// Current Nash delivery status (e.g. 'driver_assigned', 'pickup', 'dropoff').
  final String status;
  /// Driver's current latitude. null before driver is assigned.
  final double? driverLat;
  /// Driver's current longitude. null before driver is assigned.
  final double? driverLng;
  /// Driver's display name.
  final String? driverName;
  /// Driver's vehicle description or plate.
  final String? driverVehicle;
  /// Estimated minutes until dropoff. null if unknown.
  final int? etaMinutes;
  /// Destination lat/lng for map pin.
  final double? destinationLat;
  final double? destinationLng;
  final DateTime? updatedAt;

  NashDeliveryTracking.fromJson(Map<String, dynamic> j)
      : deliveryId = j['delivery_id']?.toString() ?? '',
        status = j['status']?.toString() ?? 'pending',
        driverLat = (j['driver_lat'] as num?)?.toDouble(),
        driverLng = (j['driver_lng'] as num?)?.toDouble(),
        driverName = j['driver_name']?.toString(),
        driverVehicle = j['driver_vehicle']?.toString(),
        etaMinutes = (j['eta_minutes'] as num?)?.toInt(),
        destinationLat = (j['destination_lat'] as num?)?.toDouble(),
        destinationLng = (j['destination_lng'] as num?)?.toDouble(),
        updatedAt = j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at'].toString())
            : null;

  bool get hasDriverLocation => driverLat != null && driverLng != null;
  bool get hasDestination => destinationLat != null && destinationLng != null;
  bool get isActive =>
      !['delivered', 'cancelled', 'failed'].contains(status.toLowerCase());
}

// ── Loyalty ───────────────────────────────────────────────────────────────────

/// Merchant-level loyalty programme configuration.
class LoyaltyConfig {
  /// Points earned per unit of currency spent (e.g. 1.0 = 1 pt per £1).
  final double pointsPerPound;
  /// Minimum points needed before redemption is allowed.
  final int redemptionThreshold;
  /// Pound value of each redeemed point (e.g. 0.01 = 1p per point).
  final double redemptionValue;
  /// Bonus points awarded on first enrolment.
  final int enrollmentBonus;
  /// Days before points expire. 0 = never.
  final int pointsExpiry;

  LoyaltyConfig.fromJson(Map<String, dynamic> j)
      : pointsPerPound =
            (j['points_per_pound'] ?? j['pointsPerPound'] ?? 1).toDouble(),
        redemptionThreshold =
            (j['redemption_threshold'] ?? j['loyaltyRedemptionThreshold'] ?? 100)
                as int,
        redemptionValue =
            (j['redemption_value'] ?? j['loyaltyRedemptionValue'] ?? 0.01)
                .toDouble(),
        enrollmentBonus =
            (j['enrollment_bonus'] ?? j['loyaltyEnrollmentBonus'] ?? 0) as int,
        pointsExpiry =
            (j['points_expiry'] ?? j['loyaltyPointsExpiry'] ?? 0) as int;

  /// Dollar/pound value of [points] based on [redemptionValue].
  double pointsToCurrency(int points) => points * redemptionValue;
}

class LoyaltyTransaction {
  final String id, type;
  /// Positive = points earned, negative = points redeemed.
  final int points;
  final String? description, orderId;
  final DateTime createdAt;

  LoyaltyTransaction.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        type = j['type']?.toString() ?? 'earn',
        points = (j['points'] as num?)?.toInt() ?? 0,
        description = j['description']?.toString(),
        orderId = j['order_id']?.toString(),
        createdAt = j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
            : DateTime.now();

  bool get isEarn => points > 0;
}

// ── Discounts / Offers ────────────────────────────────────────────────────────

class OrderingDiscount {
  final String id, type;
  final String? code, name, description, scope;
  final double value;
  final double minOrderValue;
  final bool isActive;
  final DateTime? expiresAt, startsAt;
  final List<String> productIds, categoryIds;

  OrderingDiscount.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        type = j['type']?.toString() ?? 'percentage',
        code = j['code']?.toString(),
        name = j['name']?.toString(),
        description = j['description']?.toString(),
        scope = j['scope']?.toString(),
        value = (j['value'] as num?)?.toDouble() ?? 0,
        minOrderValue = (j['min_order_value'] as num?)?.toDouble() ?? 0,
        isActive = j['is_active'] as bool? ?? true,
        expiresAt = j['expires_at'] != null
            ? DateTime.tryParse(j['expires_at'].toString())
            : null,
        startsAt = j['starts_at'] != null
            ? DateTime.tryParse(j['starts_at'].toString())
            : null,
        productIds =
            (j['product_ids'] as List? ?? []).map((e) => e.toString()).toList(),
        categoryIds = (j['category_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList();

  /// Human-readable value label, e.g. "20% off" or "£5 off".
  String valueLabel(String currencySymbol) {
    if (type == 'percentage') return '${value.toStringAsFixed(0)}% off';
    if (type == 'fixed') {
      return '$currencySymbol${value.toStringAsFixed(2)} off';
    }
    if (type == 'bogo') return 'Buy 1 Get 1';
    return 'Offer';
  }
}

// ── Client ────────────────────────────────────────────────────────────────────

class OrderingClient {
  final _Http _http;
  RateLimitInfo? lastRateLimit;

  OrderingClient({required String apiKey})
      : _http = _Http(apiKey: apiKey);

  /// Non-null once a subscription-level 403 has been received on any call.
  /// The internal [_Http] circuit breaker means subsequent calls throw
  /// [XebokiSubscriptionError] immediately without a network round-trip.
  /// Products can read this to show a gate screen without waiting for the
  /// next request to fail.
  KeyValidationStatus? get subscriptionBlock => _http.subscriptionBlock;

  void _track(RateLimitInfo rl) => lastRateLimit = rl;

  // ── Startup validation ───────────────────────────────────────────────────────

  /// Validates the API key and POS subscription on app startup.
  /// Throws [XebokiError] with meaningful codes on failure:
  ///   status=401  → key invalid / revoked
  ///   status=403  → subscription_required | free_plan_not_supported | ordering_app_not_in_plan
  Future<KeyValidationResult> validateApiKey() async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/validate',
      fromJson: (j) => KeyValidationResult.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  // ── Store config ────────────────────────────────────────────────────────────

  /// Fetches merchant business config from the POS — business type, currency,
  /// timezone, tax label, contact info. Called once at startup so the app
  /// auto-configures without the merchant entering these values again.
  Future<StoreConfig> fetchStoreConfig() async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/store-config',
      fromJson: (j) => StoreConfig.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  // ── Locations ───────────────────────────────────────────────────────────────

  /// Returns all active store locations for this subscriber.
  /// When the API key has a location restriction, only those locations are
  /// returned by the gateway. If a single location is configured at build-time
  /// via [AppConfig.locationId], call sites can skip this and use that ID.
  Future<List<StoreLocation>> listLocations() async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/locations',
      fromJson: (j) {
        final list = (j['locations'] ?? (j is List ? j : [])) as List;
        return list
            .map((e) => StoreLocation.fromJson(e as Map<String, dynamic>))
            .where((l) => l.isActive)
            .toList();
      },
    );
    _track(rl);
    return data;
  }

  // ── Customer Auth ────────────────────────────────────────────────────────────

  Future<CustomerAuth> registerCustomer({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/customers/register',
      body: {
        'email': email,
        'password': password,
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
      fromJson: (j) => CustomerAuth.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  Future<CustomerAuth> loginCustomer({
    required String email,
    required String password,
  }) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/customers/login',
      body: {'email': email, 'password': password},
      fromJson: (j) => CustomerAuth.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  /// Register or refresh the customer's FCM push token.
  /// Fire-and-forget — failures are silently ignored.
  Future<void> registerCustomerFcmToken(
      String customerId, String token) async {
    try {
      await _http.request(
        'POST',
        '/v1/pos/customers/fcm-token',
        body: {
          'customer_id': customerId,
          'fcm_token': token,
          'platform': _platform(),
        },
        fromJson: (_) => null,
      );
    } catch (_) {
      // Non-critical — don't surface push registration errors to the UI
    }
  }

  String _platform() {
    // dart:io Platform is not available on web — use a safe fallback
    try {
      // ignore: do_not_use_environment
      const p = String.fromEnvironment('FLUTTER_TEST', defaultValue: '');
      if (p.isNotEmpty) return 'test';
    } catch (_) {}
    // Runtime check via defaultTargetPlatform would require flutter/foundation
    // Keep it simple — the API accepts 'unknown'
    return 'mobile';
  }

  Future<GiftCardInfo> lookupGiftCard(String code) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/gift-cards/${Uri.encodeComponent(code.trim().toUpperCase())}',
      fromJson: (j) => GiftCardInfo.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  Future<OrderingOrder> createOrder({
    required String orderType,
    required List<Map<String, dynamic>> items,
    String? customerId,
    String? notes,
    String? tableId,
    String? scheduledAt,
    String? deliveryAddress,
    String? idempotencyKey,
    int? loyaltyPointsRedeemed,
    double? deliveryFee,
    double? tip,
    String? giftCardCode,
    bool applyStoreCredit = false,
  }) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/orders',
      body: {
        'order_type': orderType,
        'items': items,
        if (customerId != null) 'customer_id': customerId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (tableId != null) 'table_id': tableId,
        if (scheduledAt != null) 'scheduled_at': scheduledAt,
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        if (loyaltyPointsRedeemed != null && loyaltyPointsRedeemed > 0)
          'loyalty_points_redeemed': loyaltyPointsRedeemed,
        if (deliveryFee != null && deliveryFee > 0) 'delivery_fee': deliveryFee,
        if (tip != null && tip > 0) 'tip': tip,
        if (giftCardCode != null && giftCardCode.isNotEmpty)
          'gift_card_code': giftCardCode,
        if (applyStoreCredit) 'apply_store_credit': true,
      },
      fromJson: (j) =>
          OrderingOrder.fromJson((j['order'] ?? j) as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  Future<OrderingOrder> payOrder(
    String id, {
    required String method,
    required double amount,
    String? reference,
  }) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/orders/$id/pay',
      body: {
        'method': method,
        'amount': amount,
        if (reference != null) 'reference': reference,
      },
      fromJson: (j) =>
          OrderingOrder.fromJson((j['order'] ?? j) as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  // ── Appointments ─────────────────────────────────────────────────────────────

  Future<OrderingListResponse<OrderingAppointment>> listAppointments({
    String? customerId,
    String? status,
    String? date,
    String? staffId,
  }) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/appointments',
      query: {
        'customer_id': customerId,
        'status': status,
        'date': date,
        'staff_id': staffId,
      },
      fromJson: (j) {
        final list = ((j['appointments'] ?? j['data'] ??
            (j is List ? j : [])) as List);
        return OrderingListResponse<OrderingAppointment>(
          data: list
              .map((e) =>
                  OrderingAppointment.fromJson(e as Map<String, dynamic>))
              .toList(),
          total: (j is Map ? j['total'] as int? : null) ?? list.length,
          limit: 50,
          offset: 0,
        );
      },
    );
    _track(rl);
    return data;
  }

  Future<OrderingAppointment> createAppointment({
    required String customerId,
    required String serviceId,
    String? staffId,
    required String startTime,
    int durationMinutes = 60,
    String? notes,
  }) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/appointments',
      body: {
        'customer_id': customerId,
        'service_id': serviceId,
        if (staffId != null) 'staff_id': staffId,
        'start_time': startTime,
        'duration_minutes': durationMinutes,
        if (notes != null) 'notes': notes,
      },
      fromJson: (j) => OrderingAppointment.fromJson(
          (j['appointment'] ?? j) as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  Future<OrderingAppointment> updateAppointmentStatus(
      String id, String status) async {
    final (data, rl) = await _http.request(
      'PATCH',
      '/v1/pos/appointments/$id/status',
      body: {'status': status},
      fromJson: (j) => OrderingAppointment.fromJson(
          (j['appointment'] ?? j) as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  // ── Staff ─────────────────────────────────────────────────────────────────────

  Future<OrderingListResponse<OrderingStaff>> listStaff({
    String? locationId,
    bool? isActive,
  }) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/staff',
      query: {
        'location_id': locationId,
        'is_active': isActive?.toString(),
      },
      fromJson: (j) {
        final list =
            ((j['staff'] ?? j['data'] ?? (j is List ? j : [])) as List);
        return OrderingListResponse<OrderingStaff>(
          data: list
              .map((e) => OrderingStaff.fromJson(e as Map<String, dynamic>))
              .toList(),
          total: (j is Map ? j['total'] as int? : null) ?? list.length,
          limit: 50,
          offset: 0,
        );
      },
    );
    _track(rl);
    return data;
  }

  // ── Stripe payments ──────────────────────────────────────────────────────────

  /// Creates a Stripe PaymentIntent server-side and returns the client_secret
  /// needed to present the PaymentSheet. The merchant's Stripe secret key
  /// never leaves the server.
  Future<StripePaymentIntent> createStripePaymentIntent(String orderId) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/orders/$orderId/stripe/intent',
      fromJson: (j) =>
          StripePaymentIntent.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  /// Called after the Stripe PaymentSheet succeeds to record the payment
  /// against the order in Firestore.
  Future<OrderingOrder> confirmStripePayment(
    String orderId,
    String paymentIntentId,
  ) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/orders/$orderId/stripe/confirm',
      body: {'payment_intent_id': paymentIntentId},
      fromJson: (j) =>
          OrderingOrder.fromJson((j['order'] ?? j) as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  // ── Meal deals ───────────────────────────────────────────────────────────────

  Future<List<MealDeal>> listMealDeals({String? locationId}) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/meal-deals',
      query: {'location_id': locationId},
      fromJson: (j) {
        final list = (j['meal_deals'] ?? j['data'] ?? (j is List ? j : [])) as List;
        return list
            .map((e) => MealDeal.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    _track(rl);
    return data;
  }

  // ── Firebase config ──────────────────────────────────────────────────────────

  /// Returns the merchant's Pro Firebase public config.
  /// Used to initialise a named Firebase app at runtime — no google-services.json needed.
  Future<FirebaseOrderingConfig> getFirebaseConfig() async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/firestore-config',
      fromJson: (j) =>
          FirebaseOrderingConfig.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  /// Exchange a Firebase ID token for a Xeboki CustomerAuth.
  /// Called after [FirebaseAuth.signInWithEmailAndPassword] succeeds.
  Future<CustomerAuth> firebaseVerify(String idToken) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/customers/firebase-verify',
      body: {'id_token': idToken},
      fromJson: (j) => CustomerAuth.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  /// Register via Firebase ID token (after createUserWithEmailAndPassword).
  Future<CustomerAuth> firebaseRegister({
    required String idToken,
    String? fullName,
    String? phone,
  }) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/customers/firebase-register',
      body: {
        'id_token': idToken,
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
      fromJson: (j) => CustomerAuth.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  // ── Delivery ─────────────────────────────────────────────────────────────────

  Future<DeliveryZonesResult> getDeliveryZones({String? locationId}) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/delivery/zones',
      query: {'location_id': locationId},
      fromJson: (j) =>
          DeliveryZonesResult.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  Future<PostcodeValidationResult> validatePostcode(
    String postcode, {
    String? locationId,
  }) async {
    final (data, rl) = await _http.request(
      'POST',
      '/v1/pos/delivery/validate-postcode',
      body: {
        'postcode': postcode,
        if (locationId != null) 'location_id': locationId,
      },
      fromJson: (j) =>
          PostcodeValidationResult.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  // ── Delivery tracking (Nash) ──────────────────────────────────────────────────

  /// Returns real-time delivery tracking for an order fulfilled via Nash.
  /// Throws [XebokiError] with status 404 if the order has no Nash delivery.
  Future<NashDeliveryTracking> getDeliveryTracking(String orderId) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/orders/$orderId/delivery/tracking',
      fromJson: (j) =>
          NashDeliveryTracking.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  // ── Upsells ───────────────────────────────────────────────────────────────────

  /// Returns recommended products based on the current cart's product IDs.
  Future<List<OrderingProduct>> getUpsells(List<String> productIds) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/catalog/upsells',
      query: {'product_ids': productIds.join(',')},
      fromJson: (j) {
        final list =
            (j['products'] ?? j['data'] ?? (j is List ? j : [])) as List;
        return list
            .map((e) => OrderingProduct.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    _track(rl);
    return data;
  }

  // ── Loyalty ──────────────────────────────────────────────────────────────────

  /// Returns merchant-level loyalty programme settings (threshold, value, etc.).
  Future<LoyaltyConfig> getLoyaltyConfig() async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/loyalty/config',
      fromJson: (j) => LoyaltyConfig.fromJson(j as Map<String, dynamic>),
    );
    _track(rl);
    return data;
  }

  /// Returns a customer's loyalty transactions (most recent first).
  Future<List<LoyaltyTransaction>> getLoyaltyTransactions(
    String customerId, {
    int limit = 20,
  }) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/loyalty/transactions/$customerId',
      query: {'limit': limit.toString()},
      fromJson: (j) {
        final list = (j['transactions'] ?? j['data'] ?? (j is List ? j : [])) as List;
        return list
            .map((e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    _track(rl);
    return data;
  }

  // ── Offers (discounts) ────────────────────────────────────────────────────────

  /// Returns active discount codes and promotions.
  Future<List<OrderingDiscount>> listDiscounts({String? code}) async {
    final (data, rl) = await _http.request(
      'GET',
      '/v1/pos/discounts',
      query: {if (code != null) 'code': code},
      fromJson: (j) {
        final list = (j['discounts'] ?? j['data'] ?? (j is List ? j : [])) as List;
        return list
            .map((e) => OrderingDiscount.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    _track(rl);
    return data;
  }

  void close() => _http.close();
}
