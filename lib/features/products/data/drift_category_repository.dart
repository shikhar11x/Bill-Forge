import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/features/products/data/product_mapper.dart';
import 'package:billforge/features/products/domain/category.dart';
import 'package:billforge/features/products/domain/category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Category>> watchCategories() {
    final select = _db.select(_db.categories)
      ..orderBy([(t) => OrderingTerm.asc(t.name.collate(Collate.noCase))]);
    return select.watch().map(
      (rows) => rows.map(categoryFromRow).toList(growable: false),
    );
  }

  Future<void> _ensureNameFree(String name, {String? exceptId}) async {
    final lower = name.toLowerCase();
    final matches = await (_db.select(
      _db.categories,
    )..where((t) => t.name.lower().equals(lower))).get();
    if (matches.any((c) => c.id != exceptId)) {
      throw const ConflictFailure('A category with this name already exists.');
    }
  }

  @override
  Future<Category> create(String name) async {
    final trimmed = name.trim();
    await _ensureNameFree(trimmed);
    final category = Category(
      id: newId('cat'),
      name: trimmed,
      createdAt: DateTime.now(),
    );
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: category.id,
            name: category.name,
            createdAt: category.createdAt,
          ),
        );
    return category;
  }

  @override
  Future<void> rename(String id, String name) async {
    final trimmed = name.trim();
    await _ensureNameFree(trimmed, exceptId: id);
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(name: Value(trimmed)),
    );
  }

  @override
  Future<void> delete(String id) {
    return _db.transaction(() async {
      await (_db.update(_db.products)..where((t) => t.categoryId.equals(id)))
          .write(const ProductsCompanion(categoryId: Value(null)));
      await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
    });
  }
}
