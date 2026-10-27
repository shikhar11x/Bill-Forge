import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/products/domain/product_unit.dart';
import 'package:billforge/features/reports/domain/customer_report.dart';
import 'package:billforge/features/reports/domain/product_report.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/payment_fakes.dart';
import '../../support/report_fakes.dart';

void main() {
  final range = ReportRange.between(
    DateTime(2026, 6, 1),
    DateTime(2026, 6, 30),
  );

  group('products', () {
    final data = ReportData(
      invoiceItems: [
        rItem(
          id: 'i1',
          productId: 'p1',
          name: 'Rice',
          qtyMilli: 2000,
          taxable: 90000,
        ),
        rItem(
          id: 'i2',
          productId: 'p1',
          name: 'Rice',
          qtyMilli: 1000,
          taxable: 45000,
        ),
        rItem(
          id: 'i3',
          productId: 'p2',
          name: 'Dal',
          unit: ProductUnit.kilogram,
          qtyMilli: 2500,
          taxable: 37500,
        ),
      ],
      creditNoteItems: [
        rCnItem(productId: 'p1', name: 'Rice', qtyMilli: 1000, taxable: 45000),
      ],
      costByProductId: const {'p1': 30000},
    );

    test('net quantity, revenue and profit per product', () {
      final rows = buildProductRows(data);
      expect(rows.map((r) => r.name), ['Rice', 'Dal']);

      final rice = rows.first;
      expect(rice.soldMilli, 3000);
      expect(rice.returnedMilli, 1000);
      expect(rice.netMilli, 2000);
      expect(rice.revenuePaise, 90000);
      expect(rice.profitPaise, 30000); // 90000 - (90000 - 30000)

      final dal = rows.last;
      expect(dal.netMilli, 2500);
      expect(dal.unitSymbol, 'kg');
      expect(dal.profitPaise, isNull);
    });

    test('items without a product are grouped by name', () {
      final rows = buildProductRows(
        ReportData(
          invoiceItems: [
            rItem(id: 'a', productId: null, name: 'Loose item', taxable: 100),
            rItem(id: 'b', productId: null, name: 'Loose item', taxable: 200),
          ],
        ),
      );
      expect(rows, hasLength(1));
      expect(rows.single.revenuePaise, 300);
    });

    test('the document', () {
      final doc = buildProductsDocument(data, range);
      expect(doc.metrics.first.value.text, '2');
      expect(
        doc.metrics
            .firstWhere((m) => m.label == 'Net sales (excl. GST)')
            .value
            .text,
        '₹1,275.00',
      );
      expect(
        doc.metrics.firstWhere((m) => m.label == 'Est. profit').value.text,
        '₹300.00',
      );

      final table = doc.sections.single.table;
      expect(table.rows.first.map((c) => c.text), [
        'Rice',
        '2 pcs',
        '₹900.00',
        '₹300.00',
      ]);
      expect(table.rows.last.last.text, '—');
      expect(table.footer![2].text, '₹1,275.00');
    });

    test('an empty period gives an empty table', () {
      final doc = buildProductsDocument(const ReportData(), range);
      expect(doc.sections.single.table.rows, isEmpty);
      expect(doc.metrics.last.value.text, '—');
    });
  });

  group('customers', () {
    final data = ReportData(
      invoices: [
        sampleOpenInvoice(id: 'a', total: 105000, paid: 105000),
        sampleOpenInvoice(id: 'b', total: 50000, paid: 50000),
        sampleOpenInvoice(
          id: 'x',
          customerId: 'c2',
          customerName: 'Amit Verma',
          total: 20000,
        ),
        sampleOpenInvoice(
          id: 'w',
          total: 10000,
          paid: 10000,
        ).copyWith(customerId: null, customerName: null),
      ],
      creditNotes: [sampleCreditNote(total: 10500, refund: 10500)],
    );

    test('net sales per customer, walk-ins grouped together', () {
      final rows = buildCustomerRows(data);
      expect(rows.map((r) => r.name), [
        'Rahul Sharma',
        'Amit Verma',
        walkInLabel,
      ]);

      final rahul = rows.first;
      expect(rahul.orders, 2);
      expect(rahul.grossPaise, 155000);
      expect(rahul.returnsPaise, 10500);
      expect(rahul.netPaise, 144500);
      expect(rows.last.isWalkIn, isTrue);
    });

    test('the document', () {
      final doc = buildCustomersDocument(data, range);
      expect(doc.metrics.first.value.text, '2'); // named customers
      expect(doc.metrics.last.value.text, '₹1,745.00');
      expect(doc.sections.single.table.footer!.last.text, '₹1,745.00');
    });
  });
}
