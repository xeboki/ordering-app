import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/features/cart/widgets/cart_item_tile.dart';
import 'package:xeboki_ordering/features/cart/widgets/upsell_row.dart';
import 'package:xeboki_ordering/providers/cart_providers.dart';
import 'package:intl/intl.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _discountCtrl = TextEditingController();
  bool _validatingDiscount = false;
  String? _discountError;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyDiscount(AppLocalizations l10n) async {
    final code = _discountCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _validatingDiscount = true;
      _discountError = null;
    });
    try {
      await ref.read(cartProvider.notifier).applyDiscount(code);
    } catch (e) {
      setState(
          () => _discountError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _validatingDiscount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final brand = BrandConfig.instance;
    final theme = Theme.of(context);
    final currency = brand.store.currencySymbol;
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cartTitle,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            if (!cart.isEmpty)
              Text(
                '${cart.items.length} item${cart.items.length == 1 ? '' : 's'}',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, l10n),
              child: Text(l10n.cartClear,
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _emptyState(context, l10n)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      // Cart items
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 76),
                        itemBuilder: (_, i) {
                          final item = cart.items[i];
                          return CartItemTile(
                            item: item,
                            onIncrement: () => ref
                                .read(cartProvider.notifier)
                                .increment(item.id),
                            onDecrement: () => ref
                                .read(cartProvider.notifier)
                                .decrement(item.id),
                            onRemove: () =>
                                ref.read(cartProvider.notifier).remove(item.id),
                          );
                        },
                      ),
                      // Upsell recommendations
                      const UpsellRow(),
                    ],
                  ),
                ),

                // ── Bottom Totals ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                        top: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                            width: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Discount code
                          if (brand.features.discountCodes) ...[
                            if (cart.discountCode != null)
                              _DiscountApplied(
                                code: cart.discountCode!,
                                amount: fmt.format(cart.discountAmount),
                                onRemove: () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .clearDiscount();
                                  _discountCtrl.clear();
                                },
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _discountCtrl,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: InputDecoration(
                                        hintText: l10n.cartDiscountCode,
                                        errorText: _discountError,
                                        prefixIcon: const Icon(
                                            Icons.local_offer_outlined,
                                            size: 18),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    onPressed: _validatingDiscount
                                        ? null
                                        : () => _applyDiscount(l10n),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(72, 44),
                                    ),
                                    child: _validatingDiscount
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : Text(l10n.cartApply),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 14),
                          ],

                          // Totals
                          _TotalRow(
                              label: l10n.cartSubtotal,
                              value: fmt.format(cart.subtotal)),
                          if (cart.discountAmount > 0) ...[
                            const SizedBox(height: 6),
                            _TotalRow(
                              label: l10n.cartDiscount,
                              value: '−${fmt.format(cart.discountAmount)}',
                              valueColor: const Color(0xFF27AE60),
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          _TotalRow(
                            label: l10n.cartTotal,
                            value: fmt.format(cart.total),
                            bold: true,
                            largeValue: true,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.push('/checkout'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(l10n.cartProceedToCheckout,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 48, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(l10n.cartEmpty,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              l10n.cartEmptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: Text(l10n.cartBrowseMenu),
              style: FilledButton.styleFrom(
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.cartClearTitle),
        content: Text(l10n.cartClearMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(context);
            },
            style:
                FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.cartClear),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool largeValue;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.largeValue = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = bold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    final valueStyle = largeValue
        ? theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? theme.colorScheme.primary)
        : bold
            ? theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? theme.colorScheme.primary)
            : theme.textTheme.bodyMedium
                ?.copyWith(color: valueColor);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _DiscountApplied extends StatelessWidget {
  final String code;
  final String amount;
  final VoidCallback onRemove;

  const _DiscountApplied(
      {required this.code, required this.amount, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              size: 18, color: Color(0xFF27AE60)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF27AE60))),
                Text('$amount off',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
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
}
