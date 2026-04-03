import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Parsed representation of assets/brand.json.
/// Loaded once at startup — immutable after that.
class BrandConfig {
  const BrandConfig({
    required this.appName,
    required this.tagline,
    required this.businessType,
    required this.colors,
    required this.typography,
    required this.logo,
    required this.splash,
    required this.store,
    required this.features,
    required this.checkout,
    required this.social,
  });

  final String appName;
  final String tagline;
  final String businessType;
  final BrandColors colors;
  final BrandTypography typography;
  final BrandLogo logo;
  final BrandSplash splash;
  final BrandStore store;
  final BrandFeatures features;
  final BrandCheckout checkout;
  final BrandSocial social;

  /// True for business types where meal deals / bundles are relevant.
  bool get isFoodBusiness {
    const foodTypes = {
      'auto', 'restaurant', 'bar', 'qsr', 'coffeeshop', 'coffee_shop',
      'bakery', 'cafe', 'fastfood', 'fast_food', 'pizza', 'foodtruck',
    };
    return foodTypes.contains(businessType.toLowerCase());
  }

  /// Whether to show meal deals UI — respects explicit flag, falls back to
  /// business-type inference for 'auto'.
  bool get showMealDeals {
    if (features.mealDeals == 'false') return false;
    if (features.mealDeals == 'true') return true;
    return isFoodBusiness; // 'auto'
  }

  static BrandConfig? _instance;
  static BrandConfig get instance {
    assert(_instance != null, 'BrandConfig not loaded. Call BrandConfig.load() first.');
    return _instance!;
  }

  static Future<BrandConfig> load() async {
    final raw = await rootBundle.loadString('assets/brand.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _instance = BrandConfig._fromJson(json);
    return _instance!;
  }

  factory BrandConfig._fromJson(Map<String, dynamic> j) {
    return BrandConfig(
      appName: j['app_name'] as String? ?? 'My Store',
      tagline: j['tagline'] as String? ?? '',
      businessType: j['business_type'] as String? ?? 'auto',
      colors: BrandColors._fromJson(j['colors'] as Map<String, dynamic>? ?? {}),
      typography: BrandTypography._fromJson(j['typography'] as Map<String, dynamic>? ?? {}),
      logo: BrandLogo._fromJson(j['logo'] as Map<String, dynamic>? ?? {}),
      splash: BrandSplash._fromJson(j['splash'] as Map<String, dynamic>? ?? {}),
      store: BrandStore._fromJson(j['store'] as Map<String, dynamic>? ?? {}),
      features: BrandFeatures._fromJson(j['features'] as Map<String, dynamic>? ?? {}),
      checkout: BrandCheckout._fromJson(j['checkout'] as Map<String, dynamic>? ?? {}),
      social: BrandSocial._fromJson(j['social'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// ── Sub-configs ──────────────────────────────────────────────────────────────

class BrandColors {
  const BrandColors({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color success;
  final Color warning;
  final Color error;

  factory BrandColors._fromJson(Map<String, dynamic> j) => BrandColors(
        primary: _hex(j['primary'], const Color(0xFF1A1A2E)),
        secondary: _hex(j['secondary'], const Color(0xFFE94560)),
        surface: _hex(j['surface'], Colors.white),
        background: _hex(j['background'], const Color(0xFFF8F9FA)),
        onPrimary: _hex(j['on_primary'], Colors.white),
        onSecondary: _hex(j['on_secondary'], Colors.white),
        onSurface: _hex(j['on_surface'], const Color(0xFF1A1A2E)),
        success: _hex(j['success'], const Color(0xFF27AE60)),
        warning: _hex(j['warning'], const Color(0xFFF39C12)),
        error: _hex(j['error'], const Color(0xFFE74C3C)),
      );

  static Color _hex(dynamic value, Color fallback) {
    if (value == null) return fallback;
    final s = (value as String).replaceAll('#', '');
    final hex = s.length == 6 ? 'FF$s' : s;
    return Color(int.tryParse(hex, radix: 16) ?? fallback.toARGB32());
  }
}

class BrandTypography {
  const BrandTypography({required this.fontFamily, required this.scale});
  final String fontFamily;
  final double scale;

  factory BrandTypography._fromJson(Map<String, dynamic> j) => BrandTypography(
        fontFamily: j['font_family'] as String? ?? 'Inter',
        scale: (j['scale'] as num?)?.toDouble() ?? 1.0,
      );
}

class BrandLogo {
  const BrandLogo({
    required this.asset,
    required this.width,
    required this.height,
    required this.useTextFallback,
  });
  final String asset;
  final double width;
  final double height;
  final bool useTextFallback;

  factory BrandLogo._fromJson(Map<String, dynamic> j) => BrandLogo(
        asset: j['asset'] as String? ?? 'assets/images/logo.png',
        width: (j['width'] as num?)?.toDouble() ?? 120.0,
        height: (j['height'] as num?)?.toDouble() ?? 40.0,
        useTextFallback: j['use_text_fallback'] as bool? ?? true,
      );
}

class BrandSplash {
  const BrandSplash({
    required this.backgroundColor,
    required this.logoAsset,
    required this.showTagline,
  });
  final Color backgroundColor;
  final String logoAsset;
  final bool showTagline;

  factory BrandSplash._fromJson(Map<String, dynamic> j) => BrandSplash(
        backgroundColor: BrandColors._hex(j['background_color'], const Color(0xFF1A1A2E)),
        logoAsset: j['logo_asset'] as String? ?? 'assets/images/logo.png',
        showTagline: j['show_tagline'] as bool? ?? true,
      );
}

class BrandStore {
  const BrandStore({
    required this.currencySymbol,
    required this.currencyCode,
    required this.locale,
    required this.timezone,
    required this.taxLabel,
    required this.supportEmail,
    required this.supportPhone,
    required this.address,
    required this.website,
  });
  final String currencySymbol;
  final String currencyCode;
  final String locale;
  final String timezone;
  final String taxLabel;
  final String supportEmail;
  final String supportPhone;
  final String address;
  final String website;

  factory BrandStore._fromJson(Map<String, dynamic> j) => BrandStore(
        currencySymbol: j['currency_symbol'] as String? ?? '\$',
        currencyCode: j['currency_code'] as String? ?? 'USD',
        locale: j['locale'] as String? ?? 'en_US',
        timezone: j['timezone'] as String? ?? 'UTC',
        taxLabel: j['tax_label'] as String? ?? 'Tax',
        supportEmail: j['support_email'] as String? ?? '',
        supportPhone: j['support_phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
        website: j['website'] as String? ?? '',
      );
}

class BrandFeatures {
  const BrandFeatures({
    required this.customerAuth,
    required this.loyalty,
    required this.discountCodes,
    required this.orderScheduling,
    required this.tableOrdering,
    required this.appointments,
    required this.darkMode,
    required this.reviews,
    required this.stripePayments,
    required this.applePay,
    required this.googlePay,
    required this.tipping,
    required this.firebaseAuth,
    required this.mealDeals,
  });
  final bool customerAuth;
  final bool loyalty;
  final bool discountCodes;
  final bool orderScheduling;
  final String tableOrdering;  // 'auto' | 'true' | 'false'
  final String appointments;   // 'auto' | 'true' | 'false'
  final bool darkMode;
  final bool reviews;
  final bool stripePayments;
  final bool applePay;
  final bool googlePay;
  final bool tipping;
  /// When true, customer login/register uses Firebase Auth (email+password)
  /// backed by the merchant's Pro Firebase. Falls back to REST when false.
  final bool firebaseAuth;
  /// Show meal deals / bundle offers tab. 'auto' enables for food businesses,
  /// 'true' forces on, 'false' forces off.
  final String mealDeals; // 'auto' | 'true' | 'false'

  /// True when meal deals should be shown — explicit `true`, or `auto` for
  /// food-type businesses (restaurant, bar, qsr, coffeeShop, bakery).
  bool get showMealDeals {
    if (mealDeals == 'false') return false;
    if (mealDeals == 'true') return true;
    // 'auto' — infer from business type (stored on BrandConfig, not here)
    return true; // BrandConfig.instance.isFoodBusiness checks full list
  }

  factory BrandFeatures._fromJson(Map<String, dynamic> j) => BrandFeatures(
        customerAuth: j['customer_auth'] as bool? ?? true,
        loyalty: j['loyalty'] as bool? ?? true,
        discountCodes: j['discount_codes'] as bool? ?? true,
        orderScheduling: j['order_scheduling'] as bool? ?? false,
        tableOrdering: j['table_ordering']?.toString() ?? 'auto',
        appointments: j['appointments']?.toString() ?? 'auto',
        darkMode: j['dark_mode'] as bool? ?? true,
        reviews: j['reviews'] as bool? ?? false,
        stripePayments: j['stripe_payments'] as bool? ?? false,
        applePay: j['apple_pay'] as bool? ?? false,
        googlePay: j['google_pay'] as bool? ?? false,
        tipping: j['tipping'] as bool? ?? false,
        firebaseAuth: j['firebase_auth'] as bool? ?? false,
        mealDeals: j['meal_deals']?.toString() ?? 'auto',
      );
}

class BrandCheckout {
  const BrandCheckout({
    required this.defaultOrderType,
    required this.allowedOrderTypes,
    required this.paymentMethods,
    required this.requireCustomerForDineIn,
    required this.notesPlaceholder,
    required this.deliveryNote,
    required this.stripePublishableKey,
    required this.stripeConnectedAccountId,
    required this.minimumSpend,
    required this.tipPresets,
    required this.defaultDeliveryFee,
    required this.freeDeliveryThreshold,
    required this.dineInDiscountPct,
    required this.collectionDiscountPct,
  });
  final String defaultOrderType;
  final List<String> allowedOrderTypes;
  final List<String> paymentMethods;
  final bool requireCustomerForDineIn;
  final String notesPlaceholder;
  final String deliveryNote;
  /// Stripe publishable key (pk_live_... or pk_test_...).
  /// Secret key lives server-side only — never in brand.json.
  final String stripePublishableKey;
  /// Optional Stripe Connect account ID for per-merchant routing.
  final String? stripeConnectedAccountId;
  /// Minimum order total in store currency. 0 = no minimum.
  final double minimumSpend;
  /// Tip percentage presets shown to customers (e.g. [10, 15, 20]).
  final List<int> tipPresets;
  /// Flat delivery fee when no zone pricing is configured. 0 = free.
  final double defaultDeliveryFee;
  /// Orders at or above this total get free delivery. 0 = always charge.
  final double freeDeliveryThreshold;
  /// Auto-discount % applied to dine-in orders (e.g. 10 for 10%). 0 = none.
  final double dineInDiscountPct;
  /// Auto-discount % applied to collection/pickup orders. 0 = none.
  final double collectionDiscountPct;

  factory BrandCheckout._fromJson(Map<String, dynamic> j) => BrandCheckout(
        defaultOrderType: j['default_order_type'] as String? ?? 'pickup',
        allowedOrderTypes: (j['allowed_order_types'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            ['pickup'],
        paymentMethods: (j['payment_methods'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            ['cash', 'card'],
        requireCustomerForDineIn: j['require_customer_for_dine_in'] as bool? ?? false,
        notesPlaceholder: j['notes_placeholder'] as String? ?? 'Any special instructions?',
        deliveryNote: j['delivery_note'] as String? ?? '',
        stripePublishableKey: j['stripe_publishable_key'] as String? ?? '',
        stripeConnectedAccountId:
            (j['stripe_connected_account_id'] as String?)?.isNotEmpty == true
                ? j['stripe_connected_account_id'] as String
                : null,
        minimumSpend: (j['minimum_spend'] as num?)?.toDouble() ?? 0.0,
        tipPresets: (j['tip_presets'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [10, 15, 20],
        defaultDeliveryFee: (j['default_delivery_fee'] as num?)?.toDouble() ?? 0.0,
        freeDeliveryThreshold: (j['free_delivery_threshold'] as num?)?.toDouble() ?? 0.0,
        dineInDiscountPct: (j['dine_in_discount_pct'] as num?)?.toDouble() ?? 0.0,
        collectionDiscountPct: (j['collection_discount_pct'] as num?)?.toDouble() ?? 0.0,
      );
}

class BrandSocial {
  const BrandSocial({
    required this.instagram,
    required this.facebook,
    required this.twitter,
    required this.whatsapp,
  });
  final String instagram;
  final String facebook;
  final String twitter;
  final String whatsapp;

  factory BrandSocial._fromJson(Map<String, dynamic> j) => BrandSocial(
        instagram: j['instagram'] as String? ?? '',
        facebook: j['facebook'] as String? ?? '',
        twitter: j['twitter'] as String? ?? '',
        whatsapp: j['whatsapp'] as String? ?? '',
      );
}
