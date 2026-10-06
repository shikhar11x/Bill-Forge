import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/shop/data/shop_mapper.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';
import 'package:billforge/features/shop/domain/shop_repository.dart';

class DriftShopRepository implements ShopRepository {
  DriftShopRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<ShopProfile?> watchShop() {
    final query = _db.select(_db.shopProfiles)..limit(1);
    return query.watch().map(
      (rows) => rows.isEmpty ? null : shopFromRow(rows.first),
    );
  }

  @override
  Future<void> save(ShopProfile shop) =>
      _db.into(_db.shopProfiles).insertOnConflictUpdate(shopToCompanion(shop));
}
