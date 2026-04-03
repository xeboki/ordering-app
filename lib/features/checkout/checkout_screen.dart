import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/services/postcode_service.dart';
import 'package:xeboki_ordering/core/services/stripe_service.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/features/checkout/widgets/delivery_fee_row.dart';
import 'package:xeboki_ordering/features/checkout/widgets/tip_selector.dart';
import 'package:xeboki_ordering/providers/app_providers.dart';
import 'package:xeboki_ordering/providers/auth_providers.dart';
import 'package:xeboki_ordering/providers/cart_providers.dart';
import 'package:xeboki_ordering/providers/catalog_providers.dart';
import 'package:xeboki_ordering/providers/delivery_providers.dart';
import 'package:xeboki_ordering/providers/orders_providers.dart';
import 'package:xeboki_ordering/providers/payment_providers.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late String _orderType;
  String? _paymentMethod;
  final _notesCtrl = TextEditingController();

  // Delivery address
  final _streetCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();

  // Table selection
  OrderingTable? _selectedTable;

  // Scheduling
  DateTime? _scheduledAt;

  // Loyalty
  bool _applyLoyalty = false;

  // Gift card
  final _giftCardCtrl = TextEditingController();
  GiftCardInfo? _giftCard;
  bool _lookingUpGiftCard = false;
  String? _giftCardError;

  // Store credit
  bool _applyStoreCredit = false;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final brand = BrandConfig.instance;
    _orderType = brand.checkout.defaultOrderType;
    if (brand.checkout.paymentMethods.isNotEmpty) {
      _paymentMethod = brand.checkout.paymentMethods.first;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _streetCtrl.dispose();
    _apartmentCtrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _giftCardCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupGiftCard() async {
    final code = _giftCardCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _lookingUpGiftCard = true; _giftCardError = null; });
    try {
      final gc = await ref.read(orderingClientProvider).lookupGiftCard(code);
      if (!gc.isUsable) throw Exception('Gift card is ${gc.status}');
      setState(() { _giftCard = gc; _lookingUpGiftCard = false; });
    } catch (e) {
      setState(() {
        _giftCard = null;
        _giftCardError = e.toString().replaceAll('Exception: ', '');
        _lookingUpGiftCard = false;
      });
    }
  }

  bool get _isDelivery => _orderType == 'delivery';
  bool get _isDineIn => _orderType == 'dine_in';

  /// True when the chosen payment method should be processed via Stripe.
  bool get _isStripePayment =>
      _paymentMethod == 'stripe' && StripeService.instance.isConfigured;

  String? _buildDeliveryAddress() {
    if (!_isDelivery) return null;
    final parts = [
      _streetCtrl.text.trim(),
      if (_apartmentCtrl.text.trim().isNotEmpty) _apartmentCtrl.text.trim(),
      _cityCtrl.text.trim(),
      if (_postcodeCtrl.text.trim().isNotEmpty)
        PostcodeService.normalise(_postcodeCtrl.text.trim()),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Returns the auto-discount amount for dine-in or collection orders.
  double _autoDiscount(double subtotal) {
    final brand = BrandConfig.instance;
    if (_isDineIn && brand.checkout.dineInDiscountPct > 0) {
      return subtotal * brand.checkout.dineInDiscountPct / 100;
    }
    if (_orderType == 'pickup' && brand.checkout.collectionDiscountPct > 0) {
      return subtotal * brand.checkout.collectionDiscountPct / 100;
    }
    return 0;
  }

  void _onPostcodeChanged(String value) {
    final normalised = PostcodeService.normalise(value);
    if (PostcodeService.isValidUkFormat(normalised)) {
      ref.read(deliveryProvider.notifier).validatePostcode(normalised);
    } else {
      ref.read(deliveryProvider.notifier).reset();
    }
  }

  int? get _loyaltyPointsToRedeem {
    if (!_applyLoyalty) return null;
    return ref.read(authProvider)?.customer.loyaltyPoints;
  }

  Future<void> _placeOrder(AppLocalizations l10n) async {
    final brand = BrandConfig.instance;
    final cart = ref.read(cartProvider);

    // Minimum spend check
    if (brand.checkout.minimumSpend > 0 &&
        cart.subtotal < brand.checkout.minimumSpend) {
      final fmt = NumberFormat.currency(
          symbol: brand.store.currencySymbol, decimalDigits: 2);
      setState(() => _error =
          'Minimum order is ${fmt.format(brand.checkout.minimumSpend)}');
      return;
    }

    if (_isDelivery) {
      if (_streetCtrl.text.trim().isEmpty) {
        setState(() => _error = l10n.checkoutStreetRequired);
        return;
      }
      if (_cityCtrl.text.trim().isEmpty) {
        setState(() => _error = l10n.checkoutCityRequired);
        return;
      }
      // Block checkout if postcode is invalid / out of range
      final deliveryState = ref.read(deliveryProvider);
      if (deliveryState is DeliveryInvalid ||
          deliveryState is DeliveryOutOfRange) {
        setState(() => _error = 'Please enter a valid delivery postcode');
        return;
      }
    }

    // Apply auto-discount for dine-in / collection before placing
    final autoDisc = _autoDiscount(cart.subtotal);
    if (autoDisc > 0 && cart.discountAmount == 0) {
      ref.read(cartProvider.notifier).applyAutoDiscount(autoDisc);
    }

    if (_isStripePayment) {
      await _handleStripePayment(l10n);
    } else {
      await _handleInPersonPayment(l10n);
    }
  }

  /// Creates the order, presents the Stripe PaymentSheet, then confirms.
  /// The cart is only cleared after a successful payment.
  Future<void> _handleStripePayment(AppLocalizations l10n) async {
    setState(() { _loading = true; _error = null; });
    try {
      final cartTotal = ref.read(cartProvider).total;
      final brand = BrandConfig.instance;

      // Step 1: create the order (no payment recorded yet)
      final orderId = await ref.read(cartProvider.notifier).createOrderOnly(
        orderType: _orderType,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        tableId: _isDineIn ? _selectedTable?.id : null,
        deliveryAddress: _buildDeliveryAddress(),
        scheduledAt: _scheduledAt,
        loyaltyPointsToRedeem: _loyaltyPointsToRedeem,
        giftCardCode: _giftCard?.code,
        applyStoreCredit: _applyStoreCredit,
      );

      // Step 2: create intent + present PaymentSheet
      await ref.read(paymentProvider.notifier).payWithStripe(
        orderId,
        amount: cartTotal,
        currencyCode: brand.store.currencyCode,
        merchantDisplayName: brand.appName,
      );

      // Step 3: react to result
      final payState = ref.read(paymentProvider);
      switch (payState) {
        case PaymentSuccess():
          ref.read(cartProvider.notifier).clear();
          ref.read(ordersProvider.notifier).refresh();
          ref.read(paymentProvider.notifier).reset();
          if (mounted) context.go('/track/$orderId');
        case PaymentCancelled():
          // User cancelled the sheet — stay on checkout, cart is still intact
          ref.read(paymentProvider.notifier).reset();
          if (mounted) setState(() => _loading = false);
        case PaymentError(:final message):
          ref.read(paymentProvider.notifier).reset();
          if (mounted) setState(() { _error = message; _loading = false; });
        default:
          if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() { _error = _friendly(e, l10n); _loading = false; });
    }
  }

  /// Cash / pay-on-pickup / any non-Stripe method.
  Future<void> _handleInPersonPayment(AppLocalizations l10n) async {
    setState(() { _loading = true; _error = null; });
    try {
      final orderId = await ref.read(cartProvider.notifier).placeOrder(
        orderType: _orderType,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        paymentMethod: _paymentMethod,
        tableId: _isDineIn ? _selectedTable?.id : null,
        deliveryAddress: _buildDeliveryAddress(),
        scheduledAt: _scheduledAt,
        loyaltyPointsToRedeem: _loyaltyPointsToRedeem,
        giftCardCode: _giftCard?.code,
        applyStoreCredit: _applyStoreCredit,
      );
      ref.read(ordersProvider.notifier).refresh();
      if (mounted) context.go('/track/$orderId');
    } catch (e) {
      setState(() => _error = _friendly(e, l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object e, AppLocalizations l10n) {
    final s = e.toString().toLowerCase();
    if (s.contains('network') || s.contains('connect')) {
      return l10n.checkoutNetworkError;
    }
    if (s.contains('stock') || s.contains('unavailable')) {
      return l10n.checkoutItemUnavailable;
    }
    return l10n.checkoutOrderFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final brand = ref.watch(brandProvider);
    final customer = ref.watch(authProvider)?.customer;
    final theme = Theme.of(context);
    final currency = BrandConfig.instance.store.currencySymbol;
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    final allowedTypes = brand.checkout.allowedOrderTypes;
    final stripe = StripeService.instance;
    final paymentMethods = [
      ...brand.checkout.paymentMethods,
      if (stripe.isConfigured && !brand.checkout.paymentMethods.contains('stripe'))
        'stripe',
    ];
    final showLoyalty = brand.features.loyalty &&
        customer != null &&
        customer.loyaltyPoints > 0;
    final showSchedule = brand.features.orderScheduling;
    final showTable = _isDineIn && brand.features.tableOrdering != 'false';
    final showTipping = brand.features.tipping;
    final deliveryState = ref.watch(deliveryProvider);
    final autoDisc = _autoDiscount(cart.subtotal);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style:
                      TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Order type ───────────────────────────────────────────────
            if (allowedTypes.length > 1) ...[
              _SectionTitle(l10n.checkoutOrderType),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: allowedTypes.map((type) {
                  return ChoiceChip(
                    label: Text(_typeLabel(type, l10n)),
                    selected: _orderType == type,
                    onSelected: (_) => setState(() {
                      _orderType = type;
                      _selectedTable = null;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // ── Delivery address ──────────────────────────────────────────
            if (_isDelivery) ...[
              _SectionTitle(l10n.checkoutDeliveryAddress),
              const SizedBox(height: 10),
              TextField(
                controller: _streetCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.checkoutStreetAddress,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apartmentCtrl,
                decoration: InputDecoration(
                  labelText: l10n.checkoutApartment,
                  prefixIcon: const Icon(Icons.apartment_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cityCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.checkoutCity,
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _postcodeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Postcode',
                  prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                ),
                onChanged: _onPostcodeChanged,
              ),
              const SizedBox(height: 10),
              DeliveryFeeRow(
                deliveryState: deliveryState,
                cartSubtotal: cart.subtotal,
                freeThreshold: brand.checkout.freeDeliveryThreshold,
                fmt: fmt,
              ),
              const SizedBox(height: 20),
            ],

            // ── Table selector ────────────────────────────────────────────
            if (showTable) ...[
              _SectionTitle(l10n.checkoutSelectTable),
              const SizedBox(height: 10),
              _TableSelector(
                selectedTable: _selectedTable,
                l10n: l10n,
                onSelect: (t) => setState(() => _selectedTable = t),
              ),
              const SizedBox(height: 20),
            ],

            // ── Schedule for later ────────────────────────────────────────
            if (showSchedule) ...[
              _SectionTitle(l10n.checkoutScheduleTime),
              const SizedBox(height: 8),
              _SchedulePicker(
                scheduled: _scheduledAt,
                l10n: l10n,
                onPick: (dt) => setState(() => _scheduledAt = dt),
                onClear: () => setState(() => _scheduledAt = null),
              ),
              const SizedBox(height: 20),
            ],

            // ── Loyalty points ────────────────────────────────────────────
            if (showLoyalty) ...[
              _LoyaltyRow(
                customer: customer,
                applied: _applyLoyalty,
                l10n: l10n,
                fmt: fmt,
                onToggle: (v) => setState(() => _applyLoyalty = v),
              ),
              const SizedBox(height: 16),
            ],

            // ── Gift card ─────────────────────────────────────────────────
            _GiftCardPanel(
              ctrl: _giftCardCtrl,
              giftCard: _giftCard,
              lookingUp: _lookingUpGiftCard,
              error: _giftCardError,
              fmt: fmt,
              onLookup: _lookupGiftCard,
              onRemove: () => setState(() {
                _giftCard = null;
                _giftCardCtrl.clear();
                _giftCardError = null;
              }),
            ),
            const SizedBox(height: 16),

            // ── Store credit ──────────────────────────────────────────────
            if (customer != null && customer.storeCredit > 0) ...[
              _StoreCreditRow(
                customer: customer,
                applied: _applyStoreCredit,
                fmt: fmt,
                onToggle: (v) => setState(() => _applyStoreCredit = v),
              ),
              const SizedBox(height: 16),
            ],

            // ── Payment method ────────────────────────────────────────────
            if (paymentMethods.isNotEmpty) ...[
              _SectionTitle(l10n.checkoutPaymentMethod),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v),
                child: Column(
                  children: paymentMethods.map((method) => RadioListTile<String>(
                    value: method,
                    title: Text(_paymentLabel(method, l10n)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Notes ─────────────────────────────────────────────────────
            _SectionTitle(l10n.checkoutNotes),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.checkoutNotesHint,
              ),
            ),
            const SizedBox(height: 24),

            // ── Tipping ───────────────────────────────────────────────────
            if (showTipping) ...[
              _SectionTitle('Add a tip'),
              const SizedBox(height: 8),
              TipSelector(
                orderTotal: cart.subtotal,
                selectedTip: cart.tip,
                presets: brand.checkout.tipPresets,
                onTipChanged: (tip) =>
                    ref.read(cartProvider.notifier).setTip(tip),
              ),
              const SizedBox(height: 20),
            ],

            // ── Auto-discount banner ──────────────────────────────────────
            if (autoDisc > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_isDineIn ? 'Dine-in' : 'Collection'} discount applied — ${fmt.format(autoDisc)} off',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Order summary ─────────────────────────────────────────────
            _SummaryCard(
              cart: cart,
              fmt: fmt,
              l10n: l10n,
              autoDiscount: autoDisc,
              giftCardDeducted: _giftCard != null
                  ? _giftCard!.balance.clamp(0, double.infinity)
                  : 0,
              storeCreditDeducted: (_applyStoreCredit && customer != null)
                  ? customer.storeCredit
                  : 0,
            ),
            const SizedBox(height: 16),

            // ── Customer info ─────────────────────────────────────────────
            if (customer != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          if (customer.email != null)
                            Text(customer.email!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : () => _placeOrder(l10n),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(l10n.checkoutPlaceOrder(fmt.format(cart.total))),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) => switch (type) {
        'pickup' => l10n.orderTypePickup,
        'delivery' => l10n.orderTypeDelivery,
        'dine_in' => l10n.orderTypeDineIn,
        'takeaway' => l10n.orderTypeTakeaway,
        _ => type,
      };

  String _paymentLabel(String method, AppLocalizations l10n) {
    if (method == 'stripe') {
      final stripe = StripeService.instance;
      if (stripe.isApplePayEnabled && stripe.isGooglePayEnabled) {
        return 'Apple Pay / Google Pay / Card';
      } else if (stripe.isApplePayEnabled) {
        return 'Apple Pay / Card';
      } else if (stripe.isGooglePayEnabled) {
        return 'Google Pay / Card';
      }
      return 'Pay by Card';
    }
    return switch (method) {
      'cash' => l10n.paymentCash,
      'card' => l10n.paymentCard,
      'gift_card' => l10n.paymentGiftCard,
      _ => method,
    };
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _TableSelector extends ConsumerWidget {
  final OrderingTable? selectedTable;
  final AppLocalizations l10n;
  final ValueChanged<OrderingTable?> onSelect;

  const _TableSelector({
    required this.selectedTable,
    required this.l10n,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);
    final theme = Theme.of(context);

    return tablesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tables) {
        if (tables.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tables.map((table) {
            final isSelected = selectedTable?.id == table.id;
            final available = table.isAvailable;
            return GestureDetector(
              onTap: available
                  ? () => onSelect(isSelected ? null : table)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : available
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.checkoutTableLabel(table.name),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : available
                                ? null
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      available
                          ? l10n.checkoutAvailable
                          : l10n.checkoutOccupied,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                            : available
                                ? Colors.green
                                : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SchedulePicker extends StatelessWidget {
  final DateTime? scheduled;
  final AppLocalizations l10n;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  const _SchedulePicker({
    required this.scheduled,
    required this.l10n,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEE, MMM d · h:mm a');

    if (scheduled != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fmt.format(scheduled!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onClear,
              color: theme.colorScheme.onPrimaryContainer,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now.add(const Duration(hours: 1)),
          firstDate: now,
          lastDate: now.add(const Duration(days: 7)),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
              now.add(const Duration(hours: 1))),
        );
        if (time == null) return;
        onPick(DateTime(
            date.year, date.month, date.day, time.hour, time.minute));
      },
      icon: const Icon(Icons.schedule_outlined, size: 18),
      label: Text(l10n.checkoutSchedule),
    );
  }
}

class _LoyaltyRow extends StatelessWidget {
  final OrderingCustomer customer;
  final bool applied;
  final AppLocalizations l10n;
  final NumberFormat fmt;
  final ValueChanged<bool> onToggle;

  const _LoyaltyRow({
    required this.customer,
    required this.applied,
    required this.l10n,
    required this.fmt,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Estimate redemption value (1 point ≈ 0.01 by default)
    final estimatedValue = customer.loyaltyPoints * 0.01;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_outlined, color: Colors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.checkoutLoyaltyAvailable(
                  customer.loyaltyPoints, fmt.format(estimatedValue)),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => onToggle(!applied),
            child: Text(
                applied ? l10n.checkoutRemovePoints : l10n.checkoutApplyPoints),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Cart cart;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  final double autoDiscount;
  final double giftCardDeducted;
  final double storeCreditDeducted;

  const _SummaryCard({
    required this.cart,
    required this.fmt,
    required this.l10n,
    this.autoDiscount = 0,
    this.giftCardDeducted = 0,
    this.storeCreditDeducted = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Use whichever discount is greater — manual code or auto
    final effectiveDiscount =
        cart.discountAmount > 0 ? cart.discountAmount : autoDiscount;
    final grandTotal = (cart.subtotal - effectiveDiscount + cart.deliveryFee +
            cart.tip - giftCardDeducted - storeCreditDeducted)
        .clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.checkoutOrderSummary,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // Line items
          ...cart.items.map<Widget>((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}× ${item.productName}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(fmt.format(item.lineTotal),
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              )),
          const Divider(height: 16),
          // Subtotal
          _SummaryRow(
            label: 'Subtotal',
            value: fmt.format(cart.subtotal),
            theme: theme,
          ),
          // Discount
          if (effectiveDiscount > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(
              label: l10n.cartDiscount,
              value: '-${fmt.format(effectiveDiscount)}',
              theme: theme,
              valueColor: cs.error,
            ),
          ],
          // Gift card
          if (giftCardDeducted > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(
              label: 'Gift card',
              value: '-${fmt.format(giftCardDeducted)}',
              theme: theme,
              valueColor: const Color(0xFF27AE60),
            ),
          ],
          // Store credit
          if (storeCreditDeducted > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(
              label: 'Store credit',
              value: '-${fmt.format(storeCreditDeducted)}',
              theme: theme,
              valueColor: const Color(0xFF27AE60),
            ),
          ],
          // Delivery fee
          if (cart.deliveryFee > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(
              label: 'Delivery',
              value: fmt.format(cart.deliveryFee),
              theme: theme,
            ),
          ],
          // VAT breakdown
          if (cart.vatRate > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(
              label: 'VAT (${(cart.vatRate * 100).toStringAsFixed(0)}%)',
              value: fmt.format(cart.taxAmount),
              theme: theme,
              small: true,
            ),
          ],
          // Tip
          if (cart.tip > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(
              label: 'Tip',
              value: fmt.format(cart.tip),
              theme: theme,
            ),
          ],
          const Divider(height: 16),
          // Grand total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.cartTotal,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                fmt.format(grandTotal),
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: cs.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final ThemeData theme;
  final Color? valueColor;
  final bool small;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = small
        ? theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
        : theme.textTheme.bodySmall;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style?.copyWith(color: valueColor)),
      ],
    );
  }
}

// ── Gift card panel ───────────────────────────────────────────────────────────

class _GiftCardPanel extends StatelessWidget {
  final TextEditingController ctrl;
  final GiftCardInfo? giftCard;
  final bool lookingUp;
  final String? error;
  final NumberFormat fmt;
  final VoidCallback onLookup;
  final VoidCallback onRemove;

  const _GiftCardPanel({
    required this.ctrl,
    required this.giftCard,
    required this.lookingUp,
    required this.error,
    required this.fmt,
    required this.onLookup,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (giftCard != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF27AE60).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard, size: 18, color: Color(0xFF27AE60)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    giftCard!.code,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF27AE60)),
                  ),
                  Text(
                    'Balance: ${fmt.format(giftCard!.balance)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gift card',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter gift card code',
                  errorText: error,
                  prefixIcon:
                      const Icon(Icons.card_giftcard_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: lookingUp ? null : onLookup,
              style: FilledButton.styleFrom(minimumSize: const Size(72, 44)),
              child: lookingUp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Store credit row ──────────────────────────────────────────────────────────

class _StoreCreditRow extends StatelessWidget {
  final OrderingCustomer customer;
  final bool applied;
  final NumberFormat fmt;
  final ValueChanged<bool> onToggle;

  const _StoreCreditRow({
    required this.customer,
    required this.applied,
    required this.fmt,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.secondaryContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.secondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${fmt.format(customer.storeCredit)} store credit available',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => onToggle(!applied),
            child: Text(applied ? 'Remove' : 'Apply'),
          ),
        ],
      ),
    );
  }
}
