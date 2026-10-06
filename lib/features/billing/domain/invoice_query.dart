import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_query.freezed.dart';

const kInvoicePageSize = 30;

enum InvoiceStatusFilter { all, drafts, issued }

@freezed
abstract class InvoiceQuery with _$InvoiceQuery {
  const factory InvoiceQuery({
    @Default('') String search,
    @Default(InvoiceStatusFilter.all) InvoiceStatusFilter status,
    @Default(kInvoicePageSize) int limit,
  }) = _InvoiceQuery;
}
