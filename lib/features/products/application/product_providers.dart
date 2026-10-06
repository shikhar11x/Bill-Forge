import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/database_providers.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/features/products/data/drift_category_repository.dart';
import 'package:billforge/features/products/data/drift_product_repository.dart';
import 'package:billforge/features/products/domain/category.dart';
import 'package:billforge/features/products/domain/category_repository.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';
import 'package:billforge/features/products/domain/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DriftProductRepository(ref.watch(appDatabaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(appDatabaseProvider)),
);

class ProductQueryNotifier extends Notifier<ProductQuery> {
  @override
  ProductQuery build() => const ProductQuery();

  void setSearch(String value) =>
      state = state.copyWith(search: value, limit: kProductPageSize);

  void setCategory(String? id) =>
      state = state.copyWith(categoryId: id, limit: kProductPageSize);

  void setStockFilter(StockFilter filter) =>
      state = state.copyWith(stockFilter: filter, limit: kProductPageSize);

  void setShowArchived(bool value) =>
      state = state.copyWith(showArchived: value, limit: kProductPageSize);

  /// Called by the UI when the user scrolls near the end of the list.
  void loadMore() =>
      state = state.copyWith(limit: state.limit + kProductPageSize);

  /// Clears filters but keeps the search text.
  void clearFilters() => state = ProductQuery(search: state.search);

  /// Clears everything, including search.
  void reset() => state = const ProductQuery();

  void categoryRemoved(String id) {
    if (state.categoryId == id) setCategory(null);
  }
}

final productQueryProvider =
    NotifierProvider<ProductQueryNotifier, ProductQuery>(
      ProductQueryNotifier.new,
    );

/// Live list for the current query. Re-queries when the query changes and
/// whenever the products table changes.
final productsProvider = StreamProvider<List<Product>>((ref) {
  final query = ref.watch(productQueryProvider);
  return ref.watch(productRepositoryProvider).watchProducts(query);
});

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchCategories(),
);

final categoryNamesProvider = Provider<Map<String, String>>((ref) {
  final categories =
      ref.watch(categoriesProvider).dataOrNull ?? const <Category>[];
  return {for (final c in categories) c.id: c.name};
});

final productByIdProvider = FutureProvider.autoDispose.family<Product?, String>(
  (ref, id) => ref.watch(productRepositoryProvider).getById(id),
);
