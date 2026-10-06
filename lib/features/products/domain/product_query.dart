import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_query.freezed.dart';

const kProductPageSize = 30;

enum StockFilter { all, low, out }

@freezed
abstract class ProductQuery with _$ProductQuery {
  const factory ProductQuery({
    @Default('') String search,
    String? categoryId,
    @Default(StockFilter.all) StockFilter stockFilter,

    /// When true the list shows archived products only.
    @Default(false) bool showArchived,

    /// Grows by one page each time the user scrolls to the end.
    @Default(kProductPageSize) int limit,
  }) = _ProductQuery;
}
