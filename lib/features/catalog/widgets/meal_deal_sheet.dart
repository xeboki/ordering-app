import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/providers/catalog_providers.dart';
import 'package:xeboki_ordering/providers/meal_deal_providers.dart';

/// Bottom sheet for configuring a meal deal — one slot at a time.
class MealDealSheet extends ConsumerStatefulWidget {
  const MealDealSheet({super.key, required this.deal});

  final MealDeal deal;

  static Future<void> show(BuildContext context, MealDeal deal) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProviderScope(
        child: MealDealSheet(deal: deal),
      ),
    );
  }

  @override
  ConsumerState<MealDealSheet> createState() => _MealDealSheetState();
}

class _MealDealSheetState extends ConsumerState<MealDealSheet> {
  int _activeSlotIndex = 0;

  MealDeal get deal => widget.deal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealDealNotifierProvider.notifier).startDeal(deal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = BrandConfig.instance.store.currencySymbol;
    final dealState = ref.watch(mealDealNotifierProvider);
    final products = ref.watch(productsProvider).products;

    final priceStr = NumberFormat.currency(symbol: currency, decimalDigits: 2)
        .format(deal.price);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            // Handle + header
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
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(mealDealNotifierProvider.notifier).cancel();
                        Navigator.pop(context);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  // Deal header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (deal.imageUrl != null && deal.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: deal.imageUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (deal.imageUrl != null && deal.imageUrl!.isNotEmpty)
                        const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deal.name,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (deal.description != null &&
                                deal.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                deal.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    priceStr,
                                    style: theme.textTheme.labelLarge
                                        ?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (deal.savings > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Save ${NumberFormat.currency(symbol: currency, decimalDigits: 2).format(deal.savings)}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Slot progress indicator
                  _SlotStepper(
                    slots: deal.slots,
                    activeIndex: _activeSlotIndex,
                    selections: dealState?.selections ?? {},
                    onSlotTap: (i) => setState(() => _activeSlotIndex = i),
                  ),

                  const SizedBox(height: 20),

                  // Active slot product picker
                  if (deal.slots.isNotEmpty) ...[
                    Text(
                      'Choose ${deal.slots[_activeSlotIndex].name}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _SlotProductGrid(
                      slot: deal.slots[_activeSlotIndex],
                      allProducts: products,
                      selectedProductId: dealState
                          ?.selections[deal.slots[_activeSlotIndex].id]
                          ?.product
                          .id,
                      onSelected: (product) {
                        ref
                            .read(mealDealNotifierProvider.notifier)
                            .selectForSlot(
                              deal.slots[_activeSlotIndex].id,
                              product,
                            );
                        // Auto-advance to next unfilled slot
                        _advanceSlot(dealState);
                      },
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Sticky CTA
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
                child: FilledButton(
                  onPressed: (dealState?.isComplete ?? false)
                      ? () {
                          ref.read(mealDealNotifierProvider.notifier).addToCart();
                          Navigator.pop(context);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Add Deal to Cart — $priceStr',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _advanceSlot(MealDealState? dealState) {
    if (dealState == null) return;
    // Find the next unfilled slot
    for (int i = 0; i < deal.slots.length; i++) {
      if (!dealState.selections.containsKey(deal.slots[i].id)) {
        setState(() => _activeSlotIndex = i);
        return;
      }
    }
    // All filled — stay on current (CTA will activate)
  }
}

// ── Slot progress stepper ─────────────────────────────────────────────────────

class _SlotStepper extends StatelessWidget {
  const _SlotStepper({
    required this.slots,
    required this.activeIndex,
    required this.selections,
    required this.onSlotTap,
  });

  final List<MealDealSlot> slots;
  final int activeIndex;
  final Map<String, dynamic> selections;
  final ValueChanged<int> onSlotTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(slots.length, (i) {
        final slot = slots[i];
        final isDone = selections.containsKey(slot.id);
        final isActive = i == activeIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSlotTap(i),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? Colors.green
                              : isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                          border: isActive && !isDone
                              ? Border.all(
                                  color: theme.colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isActive
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slot.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (i < slots.length - 1)
                  Container(
                    height: 2,
                    width: 12,
                    color: isDone
                        ? Colors.green
                        : theme.colorScheme.outlineVariant,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Slot product grid ─────────────────────────────────────────────────────────

class _SlotProductGrid extends StatelessWidget {
  const _SlotProductGrid({
    required this.slot,
    required this.allProducts,
    required this.selectedProductId,
    required this.onSelected,
  });

  final MealDealSlot slot;
  final List<OrderingProduct> allProducts;
  final String? selectedProductId;
  final ValueChanged<OrderingProduct> onSelected;

  List<OrderingProduct> get _eligible {
    if (slot.eligibleProductIds.isNotEmpty) {
      return allProducts
          .where((p) => slot.eligibleProductIds.contains(p.id))
          .toList();
    }
    if (slot.eligibleCategoryIds.isNotEmpty) {
      return allProducts
          .where((p) =>
              p.categoryId != null &&
              slot.eligibleCategoryIds.contains(p.categoryId))
          .toList();
    }
    // No filter = all products eligible
    return allProducts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = BrandConfig.instance.store.currencySymbol;
    final eligible = _eligible;

    if (eligible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No products available for this slot.',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: eligible.length,
      itemBuilder: (context, i) {
        final product = eligible[i];
        final isSelected = product.id == selectedProductId;
        return GestureDetector(
          onTap: () => onSelected(product),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2.5 : 1,
              ),
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.06)
                  : theme.colorScheme.surface,
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: theme.colorScheme
                                    .surfaceContainerHighest,
                                child: Icon(
                                  Icons.restaurant_menu,
                                  size: 36,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormat.currency(
                                    symbol: currency, decimalDigits: 2)
                                .format(product.price),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check,
                          size: 14, color: theme.colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
