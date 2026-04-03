import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';

// ── Filters ─────────────────────────────────────────────────────────────────

final selectedCategoryIdProvider = StateProvider<String?>((_) => null);
final searchQueryProvider = StateProvider<String>((_) => '');

// ── Categories ───────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<OrderingCategory>>((ref) async {
  final client = ref.watch(orderingClientProvider);
  final result = await client.listCategories();
  return result.data;
});

// ── Products ─────────────────────────────────────────────────────────────────

class ProductsState {
  final List<OrderingProduct> products;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  ProductsState copyWith({
    List<OrderingProduct>? products,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) =>
      ProductsState(
        products: products ?? this.products,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final OrderingClient _client;
  String? _categoryId;
  String _search = '';
  static const _pageSize = 40;

  ProductsNotifier(this._client) : super(const ProductsState()) {
    load();
  }

  Future<void> setFilter({String? categoryId, String? search}) async {
    _categoryId = categoryId;
    _search = search ?? '';
    state = const ProductsState();
    await load();
  }

  Future<void> load() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _client.listProducts(
        categoryId: _categoryId,
        search: _search.isNotEmpty ? _search : null,
        limit: _pageSize,
        offset: state.products.length,
      );
      final all = [...state.products, ...result.data];
      state = state.copyWith(
        products: all,
        isLoading: false,
        hasMore: all.length < result.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const ProductsState();
    await load();
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier(ref.watch(orderingClientProvider));
});

final productDetailProvider =
    FutureProvider.family<OrderingProduct, String>((ref, id) {
  return ref.watch(orderingClientProvider).getProduct(id);
});

// ── Tables ───────────────────────────────────────────────────────────────────

final tablesProvider = FutureProvider<List<OrderingTable>>((ref) async {
  final client = ref.watch(orderingClientProvider);
  final result = await client.listTables();
  return result.data;
});
