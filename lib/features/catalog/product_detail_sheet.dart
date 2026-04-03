import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/providers/cart_providers.dart';
import 'package:xeboki_ordering/features/catalog/widgets/size_selector.dart';
import 'package:intl/intl.dart';

class ProductDetailSheet extends ConsumerStatefulWidget {
  final OrderingProduct product;

  const ProductDetailSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, OrderingProduct product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductDetailSheet> createState() =>
      _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<ProductDetailSheet> {
  final Map<String, Set<String>> _selected = {};
  int _quantity = 1;
  String _notes = '';
  SelectedSize? _selectedSize;

  @override
  void initState() {
    super.initState();
    // Auto-select the default size if sizes are present
    if (widget.product.sizes.isNotEmpty) {
      final defaultSize = widget.product.sizes.firstWhere(
        (s) => s.isDefault,
        orElse: () => widget.product.sizes.first,
      );
      _selectedSize = SelectedSize(
        sizeId: defaultSize.id,
        sizeName: defaultSize.name,
        priceAdjustment: defaultSize.priceAdjustment,
      );
    }
  }

  OrderingProduct get p => widget.product;

  double get _modifierTotal {
    double total = 0;
    for (final group in p.modifierGroups) {
      final selectedIds = _selected[group.id] ?? {};
      for (final opt in group.options) {
        if (selectedIds.contains(opt.id)) total += opt.priceAdjustment;
      }
    }
    return total;
  }

  double get _unitPrice =>
      p.price + _modifierTotal + (_selectedSize?.priceAdjustment ?? 0);
  double get _lineTotal => _unitPrice * _quantity;

  bool get _canAdd {
    for (final group in p.modifierGroups) {
      if (group.required && (_selected[group.id]?.isEmpty ?? true)) {
        return false;
      }
    }
    return true;
  }

  List<SelectedModifier> get _selectedModifiers {
    final result = <SelectedModifier>[];
    for (final group in p.modifierGroups) {
      final selectedIds = _selected[group.id] ?? {};
      for (final opt in group.options) {
        if (selectedIds.contains(opt.id)) {
          result.add(SelectedModifier(
            modifierId: opt.id,
            modifierName: opt.name,
            priceAdjustment: opt.priceAdjustment,
          ));
        }
      }
    }
    return result;
  }

  void _toggleOption(String groupId, String optionId, bool isMulti,
      {int? max}) {
    setState(() {
      _selected[groupId] ??= {};
      final set = _selected[groupId]!;
      if (isMulti) {
        if (set.contains(optionId)) {
          set.remove(optionId);
        } else if (max == null || set.length < max) {
          set.add(optionId);
        }
      } else {
        set
          ..clear()
          ..add(optionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currency = BrandConfig.instance.store.currencySymbol;
    final priceStr =
        NumberFormat.currency(symbol: currency, decimalDigits: 2)
            .format(_lineTotal);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            // Handle + close
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: EdgeInsets.zero,
                children: [
                  // Hero image
                  if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                    ClipRRect(
                      child: CachedNetworkImage(
                        imageUrl: p.imageUrl!,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(Icons.restaurant_menu,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3)),
                      ),
                    ),

                  // Product info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              NumberFormat.currency(
                                      symbol: currency, decimalDigits: 2)
                                  .format(p.price),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if (p.description != null &&
                            p.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            p.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Size selector — only shown when product has size variants
                  if (p.sizes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: SizeSelector(
                        sizes: p.sizes,
                        selected: _selectedSize,
                        currencySymbol: BrandConfig.instance.store.currencySymbol,
                        onSelected: (size) => setState(() => _selectedSize = size),
                      ),
                    ),
                  ],

                  // Modifier groups
                  for (final group in p.modifierGroups) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    _ModifierGroupTile(
                      group: group,
                      selected: _selected[group.id] ?? {},
                      l10n: l10n,
                      onToggle: (optId) => _toggleOption(
                        group.id,
                        optId,
                        (group.maxSelections ?? 1) > 1,
                        max: group.maxSelections,
                      ),
                    ),
                  ],

                  // Special instructions
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notes_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.productSpecialInstructions,
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            hintText: l10n.productInstructionsHint,
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: 2,
                          onChanged: (v) => _notes = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),

            // ── Sticky bottom bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Quantity stepper
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: theme.colorScheme.outline, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _QtyBtn(
                            icon: Icons.remove,
                            onTap: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '$_quantity',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          _QtyBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canAdd
                            ? () {
                                for (int i = 0; i < _quantity; i++) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .addProduct(
                                        p,
                                        modifiers: _selectedModifiers,
                                        selectedSize: _selectedSize,
                                        notes: _notes.isNotEmpty
                                            ? _notes
                                            : null,
                                      );
                                }
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.white, size: 16),
                                        const SizedBox(width: 8),
                                        Text(l10n.productAddedToCart(p.name)),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    margin: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 100),
                                  ),
                                );
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          l10n.productAddPrice(priceStr),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModifierGroupTile extends StatelessWidget {
  final ModifierGroup group;
  final Set<String> selected;
  final AppLocalizations l10n;
  final ValueChanged<String> onToggle;

  const _ModifierGroupTile({
    required this.group,
    required this.selected,
    required this.l10n,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMulti = (group.maxSelections ?? 1) > 1;
    final currency = BrandConfig.instance.store.currencySymbol;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (group.required)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.productRequired,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          if (group.maxSelections != null && group.maxSelections! > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.productChooseUpTo(group.maxSelections!),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          for (final opt in group.options)
            _OptionTile(
              option: opt,
              isSelected: selected.contains(opt.id),
              isMulti: isMulti,
              currency: currency,
              onTap: opt.isAvailable ? () => onToggle(opt.id) : null,
            ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final ModifierOption option;
  final bool isSelected;
  final bool isMulti;
  final String currency;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isMulti,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (isMulti)
              Checkbox(
                value: isSelected,
                onChanged: onTap != null ? (_) => onTap!() : null,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              )
            else
              RadioGroup<bool>(
                groupValue: isSelected,
                onChanged: (_) {
                  onTap?.call();
                },
                child: Radio<bool>(
                  value: true,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                option.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: option.isAvailable
                      ? null
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (option.priceAdjustment != 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${NumberFormat.currency(symbol: currency, decimalDigits: 2).format(option.priceAdjustment)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? Theme.of(context).colorScheme.outline
              : null,
        ),
      ),
    );
  }
}
