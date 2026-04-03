import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/features/catalog/product_detail_sheet.dart';
import 'package:xeboki_ordering/features/catalog/widgets/category_chip_bar.dart';
import 'package:xeboki_ordering/features/catalog/widgets/meal_deal_sheet.dart';
import 'package:xeboki_ordering/features/catalog/widgets/product_card.dart';
import 'package:xeboki_ordering/providers/app_providers.dart';
import 'package:xeboki_ordering/providers/cart_providers.dart';
import 'package:xeboki_ordering/providers/catalog_providers.dart';
import 'package:xeboki_ordering/providers/meal_deal_providers.dart';
import 'package:xeboki_ordering/widgets/error_view.dart';
import 'package:xeboki_ordering/widgets/loading_shimmer.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(productsProvider.notifier).load();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    ref.read(productsProvider.notifier).setFilter(
          categoryId: ref.read(selectedCategoryIdProvider),
          search: value,
        );
    setState(() {}); // refresh clear button visibility
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = ref.watch(brandProvider);
    final theme = Theme.of(context);
    final productsState = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.read(productsProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 16,
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          brand.appName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (brand.store.address.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 11,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  brand.store.address,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: l10n.catalogSearchHint(brand.appName),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Category chips (sticky) ───────────────────────────────────
            const SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryBarDelegate(),
            ),

            // ── Meal deals banner (food businesses / explicit opt-in) ─────
            if (BrandConfig.instance.showMealDeals)
              _MealDealsSliver(),

            // ── Products grid ─────────────────────────────────────────────
            if (productsState.error != null && productsState.products.isEmpty)
              SliverFillRemaining(
                child: ErrorView(
                  message: l10n.catalogFailedToLoad,
                  onRetry: () =>
                      ref.read(productsProvider.notifier).refresh(),
                ),
              )
            else if (productsState.isLoading &&
                productsState.products.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ProductCardShimmer(),
                    childCount: 8,
                  ),
                  gridDelegate: _gridDelegate,
                ),
              )
            else if (productsState.products.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.search_off,
                            size: 36,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.catalogNoProducts,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        'Try a different category or search',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= productsState.products.length) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final product = productsState.products[index];
                      final hasModifiers =
                          product.modifierGroups.isNotEmpty;
                      return ProductCard(
                        product: product,
                        onTap: () =>
                            ProductDetailSheet.show(context, product),
                        onAddSimple: hasModifiers
                            ? null
                            : () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addProduct(product);
                                _showAddedSnack(
                                    context, product.name, l10n);
                              },
                      );
                    },
                    childCount: productsState.products.length +
                        (productsState.isLoading &&
                                productsState.products.isNotEmpty
                            ? 1
                            : 0),
                  ),
                  gridDelegate: _gridDelegate,
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount get _gridDelegate =>
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      );

  void _showAddedSnack(
      BuildContext context, String name, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.productAddedToCart(name))),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      ),
    );
  }
}

// ── Meal Deals horizontal scroll sliver ──────────────────────────────────────

class _MealDealsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dealsAsync = ref.watch(mealDealsProvider);

    return dealsAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (deals) {
        final active = deals.where((d) => d.isActive).toList();
        if (active.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Meal Deals',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: active.length,
                  itemBuilder: (ctx, i) =>
                      _MealDealCard(deal: active[i]),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _MealDealCard extends StatelessWidget {
  const _MealDealCard({required this.deal});
  final MealDeal deal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = BrandConfig.instance.store.currencySymbol;
    final priceStr =
        NumberFormat.currency(symbol: currency, decimalDigits: 2).format(deal.price);

    return GestureDetector(
      onTap: () => MealDealSheet.show(context, deal),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Image or placeholder
            if (deal.imageUrl != null && deal.imageUrl!.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: deal.imageUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.25),
                  colorBlendMode: BlendMode.darken,
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),

            // Content overlay
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: deal.imageUrl != null
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priceStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (deal.savings > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Save ${NumberFormat.currency(symbol: currency, decimalDigits: 0).format(deal.savings)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
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
      ),
    );
  }
}

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  const _CategoryBarDelegate();

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: const CategoryChipBar(),
    );
  }

  @override
  bool shouldRebuild(_CategoryBarDelegate oldDelegate) => false;
}
