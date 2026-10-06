import 'package:billforge/features/shop/domain/shop_profile.dart';

abstract interface class ShopRepository {
  /// Emits the current shop, or null when none has been created yet.
  Stream<ShopProfile?> watchShop();

  /// Creates or updates the shop (upsert by id).
  Future<void> save(ShopProfile shop);
}
