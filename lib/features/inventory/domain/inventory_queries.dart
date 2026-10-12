import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_queries.freezed.dart';

const kSupplierLimit = 500;
const kPurchasePageSize = 30;
const kMovementPageSize = 30;

@freezed
abstract class SupplierQuery with _$SupplierQuery {
  const factory SupplierQuery({
    @Default('') String search,
    @Default(false) bool showArchived,
  }) = _SupplierQuery;
}

@freezed
abstract class PurchaseQuery with _$PurchaseQuery {
  const factory PurchaseQuery({
    @Default('') String search,
    @Default(kPurchasePageSize) int limit,
  }) = _PurchaseQuery;
}