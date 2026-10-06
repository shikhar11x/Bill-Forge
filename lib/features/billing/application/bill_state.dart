import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/customers/domain/customer.dart';

part 'bill_state.freezed.dart';

@freezed
abstract class BillState with _$BillState {
  const BillState._();

  const factory BillState({
    @Default(<CartLine>[]) List<CartLine> lines,
    Customer? customer,
    @Default(Discount.none()) Discount billDiscount,

    /// Set when this cart was loaded from (or saved as) a draft.
    String? draftId,
    DateTime? draftCreatedAt,
  }) = _BillState;

  bool get isEmpty => lines.isEmpty;
  int get itemCount => lines.length;
}
