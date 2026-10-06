import 'package:billforge/features/products/domain/category.dart';
import 'package:billforge/features/products/domain/category_repository.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';
import 'package:billforge/features/products/domain/product_repository.dart';
import 'package:billforge/features/shop/domain/business_type.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';
import 'package:billforge/features/shop/domain/shop_repository.dart';

ShopProfile sampleShop({String name = 'Sharma General Store'}) => ShopProfile(
  id: 'shop_1',
  name: name,
  businessType: BusinessType.grocery,
  phone: '9876543210',
  addressLine1: '12 Main Bazaar',
  city: 'Gurugram',
  state: 'Haryana',
  pincode: '122001',
  gstRegistration: GstRegistration.unregistered,
  defaultGstRate: 0,
  invoicePrefix: 'INV',
  nextInvoiceNumber: 1,
  primaryColorValue: 0xFF3F6FF0,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

class FakeShopRepository implements ShopRepository {
  ShopProfile? saved;

  @override
  Stream<ShopProfile?> watchShop() => Stream.value(saved);

  @override
  Future<void> save(ShopProfile shop) async {
    saved = shop;
  }
}

Product sampleProduct({
  String id = 'p1',
  String name = 'Parle-G Biscuits',
  String? sku,
  String? barcode,
  int sellingPricePaise = 1000,
  bool trackStock = true,
  int stockMilli = 10000,
  int lowStockThresholdMilli = 0,
  DateTime? archivedAt,
}) => Product(
  id: id,
  name: name,
  sku: sku,
  barcode: barcode,
  sellingPricePaise: sellingPricePaise,
  trackStock: trackStock,
  stockMilli: stockMilli,
  lowStockThresholdMilli: lowStockThresholdMilli,
  archivedAt: archivedAt,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

class FakeProductRepository implements ProductRepository {
  FakeProductRepository([List<Product> products = const []])
    : _products = List.of(products);

  final List<Product> _products;

  @override
  Stream<List<Product>> watchProducts(ProductQuery query) {
    final search = query.search.trim().toLowerCase();
    final result = _products
        .where((p) => p.isArchived == query.showArchived)
        .where(
          (p) =>
              search.isEmpty ||
              p.name.toLowerCase().contains(search) ||
              (p.sku ?? '').toLowerCase().contains(search) ||
              (p.barcode ?? '').toLowerCase().contains(search),
        )
        .take(query.limit)
        .toList();
    return Stream.value(result);
  }

  @override
  Future<Product?> getById(String id) async {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> save(Product product) async {
    _products
      ..removeWhere((p) => p.id == product.id)
      ..add(product);
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index < 0) return;
    _products[index] = _products[index].copyWith(
      archivedAt: archived ? DateTime(2026, 6, 1) : null,
    );
  }
}

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([List<Category> categories = const []])
    : _categories = List.of(categories);

  final List<Category> _categories;

  @override
  Stream<List<Category>> watchCategories() =>
      Stream.value(List.of(_categories));

  @override
  Future<Category> create(String name) async {
    final category = Category(
      id: 'cat_${_categories.length + 1}',
      name: name,
      createdAt: DateTime(2026, 1, 1),
    );
    _categories.add(category);
    return category;
  }

  @override
  Future<void> rename(String id, String name) async {}

  @override
  Future<void> delete(String id) async {
    _categories.removeWhere((c) => c.id == id);
  }
}
