import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_query.dart';
import 'package:billforge/features/billing/domain/invoice_repository.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';

Invoice sampleInvoice({
  String id = 'i1',
  String? number = 'INV-0001',
  InvoiceStatus status = InvoiceStatus.issued,
  String? customerName,
  int grandTotalPaise = 10000,
  int paidPaise = 10000,
}) => Invoice(
  id: id,
  invoiceNumber: number,
  status: status,
  customerName: customerName,
  placeOfSupply: 'Haryana',
  isInterState: false,
  pricesIncludeTax: true,
  discountPaise: 0,
  taxablePaise: grandTotalPaise,
  cgstPaise: 0,
  sgstPaise: 0,
  igstPaise: 0,
  roundOffPaise: 0,
  grandTotalPaise: grandTotalPaise,
  paidPaise: paidPaise,
  issuedAt: status == InvoiceStatus.issued ? DateTime(2026, 6, 1, 14, 5) : null,
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1, 14, 5),
);

class FakeInvoiceRepository implements InvoiceRepository {
  FakeInvoiceRepository([List<Invoice> invoices = const []])
    : _invoices = List.of(invoices);

  final List<Invoice> _invoices;
  InvoiceDetail? lastDraft;
  InvoiceDetail? lastIssued;
  List<PaymentEntry>? lastPayments;

  @override
  Stream<List<Invoice>> watchInvoices(InvoiceQuery query) {
    final result = _invoices
        .where((i) {
          switch (query.status) {
            case InvoiceStatusFilter.all:
              return true;
            case InvoiceStatusFilter.drafts:
              return i.isDraft;
            case InvoiceStatusFilter.issued:
              return !i.isDraft;
          }
        })
        .take(query.limit)
        .toList();
    return Stream.value(result);
  }

  @override
  Future<InvoiceDetail?> getDetail(String id) async {
    for (final i in _invoices) {
      if (i.id == id) return InvoiceDetail(invoice: i, items: const []);
    }
    return null;
  }

  @override
  Future<void> saveDraft(InvoiceDetail draft) async {
    lastDraft = draft;
  }

  @override
  Future<void> deleteDraft(String id) async {}

  @override
  Future<Invoice> issue(
    InvoiceDetail draft,
    List<PaymentEntry> payments,
  ) async {
    lastIssued = draft;
    lastPayments = payments;
    return draft.invoice.copyWith(
      invoiceNumber: 'INV-0001',
      status: InvoiceStatus.issued,
      paidPaise: payments.fold<int>(0, (s, p) => s + p.amountPaise),
      issuedAt: DateTime(2026, 6, 1),
      billDiscount: draft.invoice.billDiscount,
    );
  }
}

/// Shorthand for tests that don't care about discounts.
const noDiscount = Discount.none();
