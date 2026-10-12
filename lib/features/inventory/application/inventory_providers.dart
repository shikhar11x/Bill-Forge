import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/database_providers.dart';
import 'package:billforge/features/inventory/data/drift_purchase_repository.dart';
import 'package:billforge/features/inventory/data/drift_stock_repository.dart';
import 'package:billforge/features/inventory/data/drift_supplier_repository.dart';
import 'package:billforge/features/inventory/domain/inventory_queries.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';
import 'package:billforge/features/inventory/domain/purchase_repository.dart';
import 'package:billforge/features/inventory/domain/stock_movement.dart';
import 'package:billforge/features/inventory/domain/stock_repository.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';
import 'package:billforge/features/inventory/domain/supplier_repository.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';

final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => DriftStockRepository(ref.watch(appDatabaseProvider)),
);

final supplierRepositoryProvider = Provider<SupplierRepository>(
  (ref) => DriftSupplierRepository(ref.watch(appDatabaseProvider)),
);

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => DriftPurchaseRepository(ref.watch(appDatabaseProvider)),
);

// --- Stock tab ---------------------------------------------------------

class InventoryQueryNotifier extends Notifier<ProductQuery> {
  @override
  ProductQuery build() =>
      const ProductQuery(stockFilter: StockFilter.attention);

  void setSearch(String value) =>
      state = state.copyWith(search: value, limit: kProductPageSize);

  void setStockFilter(StockFilter filter) =>
      state = state.copyWith(stockFilter: filter, limit: kProductPageSize);

  void loadMore() =>
      state = state.copyWith(limit: state.limit + kProductPageSize);
}

final inventoryQueryProvider =
    NotifierProvider<InventoryQueryNotifier, ProductQuery>(
      InventoryQueryNotifier.new,
    );

final inventoryProductsProvider = StreamProvider<List<Product>>((ref) {
  final query = ref.watch(inventoryQueryProvider);
  return ref.watch(productRepositoryProvider).watchProducts(query);
});

final lowStockCountProvider = StreamProvider<int>(
  (ref) => ref.watch(productRepositoryProvider).watchLowStockCount(),
);

/// Product picker (purchases). Starts clean each time it is opened.
final productSearchProvider = StreamProvider.autoDispose
    .family<List<Product>, String>((ref, search) {
      return ref
          .watch(productRepositoryProvider)
          .watchProducts(ProductQuery(search: search, limit: 50));
    });

/// Stock history of one product, newest first. The key is (productId, limit).
final stockMovementsProvider = StreamProvider.autoDispose
    .family<List<StockMovement>, (String, int)>((ref, args) {
      return ref
          .watch(stockRepositoryProvider)
          .watchMovements(args.$1, limit: args.$2);
    });

// --- Suppliers ---------------------------------------------------------

class SupplierQueryNotifier extends Notifier<SupplierQuery> {
  @override
  SupplierQuery build() => const SupplierQuery();

  void setSearch(String value) => state = state.copyWith(search: value);

  void setShowArchived(bool value) =>
      state = state.copyWith(showArchived: value);
}

final supplierQueryProvider =
    NotifierProvider<SupplierQueryNotifier, SupplierQuery>(
      SupplierQueryNotifier.new,
    );

final suppliersProvider = StreamProvider<List<Supplier>>((ref) {
  final query = ref.watch(supplierQueryProvider);
  return ref.watch(supplierRepositoryProvider).watchSuppliers(query);
});

/// Active suppliers for the purchase form's dropdown.
final supplierOptionsProvider = StreamProvider.autoDispose<List<Supplier>>(
  (ref) => ref
      .watch(supplierRepositoryProvider)
      .watchSuppliers(const SupplierQuery()),
);

// --- Purchases ---------------------------------------------------------

class PurchaseQueryNotifier extends Notifier<PurchaseQuery> {
  @override
  PurchaseQuery build() => const PurchaseQuery();

  void setSearch(String value) =>
      state = state.copyWith(search: value, limit: kPurchasePageSize);

  void loadMore() =>
      state = state.copyWith(limit: state.limit + kPurchasePageSize);
}

final purchaseQueryProvider =
    NotifierProvider<PurchaseQueryNotifier, PurchaseQuery>(
      PurchaseQueryNotifier.new,
    );

final purchasesProvider = StreamProvider<List<Purchase>>((ref) {
  final query = ref.watch(purchaseQueryProvider);
  return ref.watch(purchaseRepositoryProvider).watchPurchases(query);
});

final purchaseDetailProvider = FutureProvider.autoDispose
    .family<PurchaseDetail?, String>(
      (ref, id) => ref.watch(purchaseRepositoryProvider).getDetail(id),
    );
