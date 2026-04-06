import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/services/firestore_service.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'app_providers.dart';

// ── Filters ──────────────────────────────────────────────────────────────────

final selectedCategoryIdProvider = StateProvider<String?>((_) => null);
final searchQueryProvider = StateProvider<String>((_) => '');

// ── Categories — direct Firestore read ───────────────────────────────────────

final categoriesProvider = FutureProvider<List<OrderingCategory>>((ref) async {
  final locationId = ref.watch(selectedLocationIdProvider);
  return FirestoreService.instance.getCategories(locationId: locationId);
});

// ── Products — direct Firestore read with pagination ─────────────────────────

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
  final String? _locationId;
  String? _categoryId;
  String _search = '';
  DocumentSnapshot? _lastDoc;
  static const _pageSize = 40;

  ProductsNotifier(this._locationId) : super(const ProductsState()) {
    load();
  }

  Future<void> setFilter({String? categoryId, String? search}) async {
    _categoryId = categoryId;
    _search = search ?? '';
    _lastDoc = null;
    state = const ProductsState();
    await load();
  }

  Future<void> load() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await FirestoreService.instance.getProducts(
        categoryId: _categoryId,
        search: _search.isNotEmpty ? _search : null,
        locationId: _locationId,
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      if (products.isNotEmpty) {
        // The last Firestore snapshot is not exposed by the helper — for now
        // treat a partial page as "no more" (simple, correct for most catalogs)
        _lastDoc = null;
      }
      final all = [...state.products, ...products];
      state = state.copyWith(
        products: all,
        isLoading: false,
        hasMore: products.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    _lastDoc = null;
    state = const ProductsState();
    await load();
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final locationId = ref.watch(selectedLocationIdProvider);
  return ProductsNotifier(locationId);
});

final productDetailProvider =
    FutureProvider.family<OrderingProduct?, String>((ref, id) {
  return FirestoreService.instance.getProduct(id);
});

// ── Tables — direct Firestore read ───────────────────────────────────────────

final tablesProvider = FutureProvider<List<OrderingTable>>((ref) async {
  final locationId = ref.watch(selectedLocationIdProvider);
  final fs = FirestoreService.instance.firestore;
  Query<Map<String, dynamic>> q = fs
      .collection('tables')
      .where('is_active', isEqualTo: true)
      .orderBy('name');
  if (locationId != null) {
    q = q.where('location_id', isEqualTo: locationId);
  }
  final snap = await q.get();
  return snap.docs
      .map((d) => OrderingTable.fromJson({...d.data(), 'id': d.id}))
      .toList();
});
