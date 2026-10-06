import 'package:billforge/features/products/domain/category.dart';

abstract interface class CategoryRepository {
  Stream<List<Category>> watchCategories();

  /// Throws `ConflictFailure` if the name is already used (case-insensitive).
  Future<Category> create(String name);

  Future<void> rename(String id, String name);

  /// Products in the category become uncategorised.
  Future<void> delete(String id);
}
