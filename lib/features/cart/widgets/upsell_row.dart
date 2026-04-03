import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/features/catalog/product_detail_sheet.dart';
import 'package:xeboki_ordering/providers/cart_providers.dart';
import 'package:xeboki_ordering/providers/upsell_providers.dart';

/// Horizontal scroll row of recommended add-on products.
///
/// Shown in the cart above the totals when there are upsell suggestions.
/// Hidden entirely when loading fails or returns no results.
class UpsellRow extends ConsumerWidget {
  const UpsellRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upsellsAsync = ref.watch(upsellsProvider);
    final theme = Theme.of(context);

    return upsellsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.add_shopping_cart_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'You might also like',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: products.length,
                itemBuilder: (ctx, i) => _UpsellCard(product: products[i]),
              ),
            ),
            const SizedBox(height: 8),
            Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ],
        );
      },
    );
  }
}

class _UpsellCard extends ConsumerWidget {
  const _UpsellCard({required this.product});
  final OrderingProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = BrandConfig.instance.store.currencySymbol;
    final priceStr = NumberFormat.currency(symbol: currency, decimalDigits: 2)
        .format(product.price);
    final hasModifiers =
        product.modifierGroups.isNotEmpty || product.sizes.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasModifiers) {
          ProductDetailSheet.show(context, product);
        } else {
          ref.read(cartProvider.notifier).addProduct(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('${product.name} added'),
              ]),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            ),
          );
        }
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surface,
          border: Border.all(
              color: theme.colorScheme.outlineVariant, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 28,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                      ),
                    ),
            ),
            // Info + add button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasModifiers ? Icons.arrow_forward : Icons.add,
                          size: 14,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
