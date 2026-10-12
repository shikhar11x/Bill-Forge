import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';

abstract interface class ProductRepository {
  Stream<List<Product>> watchProducts(ProductQuery query);

  /// How many active, stock-tracked products are low or out of stock.
  Stream<int> watchLowStockCount();

  Future<Product?> getById(String id);

  /// Upsert by id. Throws `ConflictFailure` on a duplicate SKU or barcode.
  /// Stock changes made here are recorded in the stock ledger.
  Future<void> save(Product product);

  Future<void> setArchived(String id, {required bool archived});
}
