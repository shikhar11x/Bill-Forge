import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';
import 'package:billforge/features/payments/domain/customer_payment.dart';
import 'package:billforge/features/payments/domain/payment_repository.dart';

/// An issued invoice with a balance (total minus paid).
Invoice sampleOpenInvoice({
  String id = 'i1',
  String number = 'INV-0001',
  String customerId = 'c1',
  String customerName = 'Rahul Sharma',
  String? customerPhone,
  int total = 100000,
  int paid = 0,
  DateTime? issuedAt,
  DateTime? dueDate,
}) => Invoice(
  id: id,
  invoiceNumber: number,
  status: InvoiceStatus.issued,
  customerId: customerId,
  customerName: customerName,
  customerPhone: customerPhone,
  placeOfSupply: 'Haryana',
  isInterState: false,
  pricesIncludeTax: true,
  discountPaise: 0,
  taxablePaise: total,
  cgstPaise: 0,
  sgstPaise: 0,
  igstPaise: 0,
  roundOffPaise: 0,
  grandTotalPaise: total,
  paidPaise: paid,
  dueDate: dueDate,
  issuedAt: issuedAt ?? DateTime(2026, 6, 1),
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

CustomerPayment sampleReceipt({
  String id = 'r1',
  String customerId = 'c1',
  int amountPaise = 50000,
  PaymentMethod method = PaymentMethod.upi,
  String? note,
  DateTime? receivedAt,
}) => CustomerPayment(
  id: id,
  customerId: customerId,
  method: method,
  amountPaise: amountPaise,
  note: note,
  receivedAt: receivedAt ?? DateTime(2026, 6, 12),
  createdAt: DateTime(2026, 6, 12),
);

class CollectCall {
  const CollectCall({
    required this.customerId,
    required this.amountPaise,
    required this.method,
    this.note,
    this.invoiceId,
  });

  final String customerId;
  final int amountPaise;
  final PaymentMethod method;
  final String? note;
  final String? invoiceId;
}

class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository({
    this.openInvoices = const [],
    this.receipts = const [],
    this.ledger,
  });

  final List<Invoice> openInvoices;
  final List<CustomerPayment> receipts;
  final CustomerLedger? ledger;
  final List<CollectCall> collected = [];
  ConflictFailure? failure;

  @override
  Stream<List<Invoice>> watchOpenInvoices() => Stream.value(openInvoices);

  @override
  Stream<List<Invoice>> watchOpenInvoicesFor(String customerId) => Stream.value(
    openInvoices.where((i) => i.customerId == customerId).toList(),
  );

  @override
  Stream<List<CustomerPayment>> watchReceipts(
    String customerId, {
    required int limit,
  }) => Stream.value(
    receipts.where((r) => r.customerId == customerId).take(limit).toList(),
  );

  @override
  Future<CustomerLedger> loadLedger(String customerId) async =>
      ledger ?? const CustomerLedger(invoices: [], payments: [], receipts: []);

  @override
  Future<CustomerPayment> collect({
    required String customerId,
    required int amountPaise,
    required PaymentMethod method,
    String? note,
    String? invoiceId,
  }) async {
    if (failure != null) throw failure!;
    collected.add(
      CollectCall(
        customerId: customerId,
        amountPaise: amountPaise,
        method: method,
        note: note,
        invoiceId: invoiceId,
      ),
    );
    return sampleReceipt(
      customerId: customerId,
      amountPaise: amountPaise,
      method: method,
    );
  }
}
