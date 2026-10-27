import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/credit_note_repository.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

CreditNote sampleCreditNote({
  String id = 'cn1',
  String number = 'CN-0001',
  int total = 45000,
  int applied = 0,
  int refund = 45000,
  DateTime? issuedAt,
}) => CreditNote(
  id: id,
  creditNoteNumber: number,
  invoiceId: 'inv_1',
  invoiceNumber: 'INV-0042',
  customerId: 'c1',
  customerName: 'Rahul Sharma',
  customerPhone: '9876543210',
  placeOfSupply: 'Haryana',
  isInterState: false,
  reason: ReturnReason.damaged,
  isCancellation: false,
  restocked: true,
  taxablePaise: total,
  cgstPaise: 0,
  sgstPaise: 0,
  igstPaise: 0,
  roundOffPaise: 0,
  totalPaise: total,
  appliedPaise: applied,
  refundPaise: refund,
  refundMethod: refund > 0 ? PaymentMethod.cash : null,
  issuedAt: issuedAt ?? DateTime(2026, 6, 12, 10),
);

CreditNoteItem sampleCreditNoteItem({
  String id = 'cn1-1',
  String name = 'Basmati Rice 5 kg',
  int qtyMilli = 1000,
  int total = 45000,
}) => CreditNoteItem(
  id: id,
  creditNoteId: 'cn1',
  invoiceItemId: 'inv_1-1',
  position: 0,
  name: name,
  unit: ProductUnit.piece,
  qtyMilli: qtyMilli,
  unitPricePaise: 45000,
  gstRatePercent: 0,
  taxablePaise: total,
  cgstPaise: 0,
  sgstPaise: 0,
  igstPaise: 0,
  totalPaise: total,
);

CreditNoteDetail sampleCreditNoteDetail({
  int applied = 0,
  int refund = 45000,
}) => CreditNoteDetail(
  creditNote: sampleCreditNote(applied: applied, refund: refund),
  items: [sampleCreditNoteItem()],
);

class IssueCall {
  const IssueCall({
    required this.invoiceId,
    required this.quantities,
    required this.reason,
    required this.restock,
    this.note,
    this.refundMethod,
  });

  final String invoiceId;
  final Map<String, int> quantities;
  final ReturnReason reason;
  final String? note;
  final bool restock;
  final PaymentMethod? refundMethod;
}

class CancelCall {
  const CancelCall({
    required this.invoiceId,
    required this.restock,
    this.note,
    this.refundMethod,
  });

  final String invoiceId;
  final String? note;
  final bool restock;
  final PaymentMethod? refundMethod;
}

class FakeCreditNoteRepository implements CreditNoteRepository {
  FakeCreditNoteRepository({this.returned = const []});

  final List<CreditNoteItem> returned;
  IssueCall? issued;
  CancelCall? cancelled;
  ConflictFailure? failure;

  @override
  Stream<List<CreditNote>> watchForInvoice(String invoiceId) =>
      Stream.value(const []);

  @override
  Future<CreditNoteDetail?> getDetail(String id) async =>
      sampleCreditNoteDetail();

  @override
  Future<List<CreditNoteItem>> returnedItems(String invoiceId) async =>
      returned;

  @override
  Future<CreditNote> issue({
    required String invoiceId,
    required Map<String, int> quantities,
    required ReturnReason reason,
    String? note,
    required bool restock,
    PaymentMethod? refundMethod,
  }) async {
    if (failure != null) throw failure!;
    issued = IssueCall(
      invoiceId: invoiceId,
      quantities: quantities,
      reason: reason,
      note: note,
      restock: restock,
      refundMethod: refundMethod,
    );
    return sampleCreditNote();
  }

  @override
  Future<CreditNote> cancelInvoice({
    required String invoiceId,
    String? note,
    required bool restock,
    PaymentMethod? refundMethod,
  }) async {
    if (failure != null) throw failure!;
    cancelled = CancelCall(
      invoiceId: invoiceId,
      note: note,
      restock: restock,
      refundMethod: refundMethod,
    );
    return sampleCreditNote();
  }
}
