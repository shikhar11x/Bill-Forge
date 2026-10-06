import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_query.freezed.dart';

const kCustomerPageSize = 30;

@freezed
abstract class CustomerQuery with _$CustomerQuery {
  const factory CustomerQuery({
    @Default('') String search,

    /// When true the list shows archived customers only.
    @Default(false) bool showArchived,

    /// Grows by one page each time the user scrolls to the end.
    @Default(kCustomerPageSize) int limit,
  }) = _CustomerQuery;
}
