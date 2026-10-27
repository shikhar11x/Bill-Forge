import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';
import 'package:billforge/features/products/domain/product_unit.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/domain/report_repository.dart';

InvoiceItem rItem({
  String id = 'it1',
  String invoiceId = 'i1',
  String? productId = 'p1',
  String name = 'Rice',
  String? hsn,
  int rate = 0,
  int qtyMilli = 1000,
  int taxable = 100000,
  int cgst = 0,
  int sgst = 0,
  int igst = 0,
  ProductUnit unit = ProductUnit.piece,
}) => InvoiceItem(
  id: id,
  invoiceId: invoiceId,
  position: 0,
  productId: productId,
  name: name,
  hsnCode: hsn,
  unit: unit,
  qtyMilli: qtyMilli,
  unitPricePaise: taxable,
  gstRatePercent: rate,
  discountPaise: 0,
  taxablePaise: taxable,
  cgstPaise: cgst,
  sgstPaise: sgst,
  igstPaise: igst,
  totalPaise: taxable + cgst + sgst + igst,
);

CreditNoteItem rCnItem({
  String id = 'cni1',
  String creditNoteId = 'cn1',
  String? productId = 'p1',
  String name = 'Rice',
  String? hsn,
  int rate = 0,
  int qtyMilli = 1000,
  int taxable = 50000,
  int cgst = 0,
  int sgst = 0,
  int igst = 0,
  ProductUnit unit = ProductUnit.piece,
}) => CreditNoteItem(
  id: id,
  creditNoteId: creditNoteId,
  invoiceItemId: 'it1',
  position: 0,
  productId: productId,
  name: name,
  hsnCode: hsn,
  unit: unit,
  qtyMilli: qtyMilli,
  unitPricePaise: taxable,
  gstRatePercent: rate,
  taxablePaise: taxable,
  cgstPaise: cgst,
  sgstPaise: sgst,
  igstPaise: igst,
  totalPaise: taxable + cgst + sgst + igst,
);

InvoicePayment rPayment({
  String id = 'pay1',
  String invoiceId = 'i1',
  PaymentMethod method = PaymentMethod.cash,
  int amount = 100000,
  DateTime? paidAt,
  String? receiptId,
}) => InvoicePayment(
  id: id,
  invoiceId: invoiceId,
  method: method,
  amountPaise: amount,
  paidAt: paidAt ?? DateTime(2026, 6, 10, 12),
  receiptId: receiptId,
);

Purchase rPurchase({
  String id = 'pur1',
  String? supplierName = 'Metro Wholesale',
  int total = 30000,
  DateTime? at,
}) => Purchase(
  id: id,
  supplierName: supplierName,
  purchasedAt: at ?? DateTime(2026, 6, 10),
  totalPaise: total,
  createdAt: at ?? DateTime(2026, 6, 10),
);

class FakeReportRepository implements ReportRepository {
  FakeReportRepository([this.data = const ReportData()]);

  final ReportData data;
  ReportRange? lastRange;

  @override
  Future<ReportData> load(ReportRange range) async {
    lastRange = range;
    return data;
  }
}
