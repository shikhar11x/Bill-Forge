import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/domain/sales_report.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/payment_fakes.dart';

void main() {
  // A: ₹1,050.00 with ₹50.00 GST (10 Jun). B: ₹500.00 (11 Jun).
  // C: ₹200.00, cancelled (11 Jun), offset by credit note CN-2 the same day.
  // CN-1: ₹105.00 return with ₹5.00 GST (12 Jun).
  final data = ReportData(
    invoices: [
      sampleOpenInvoice(
        id: 'a',
        number: 'INV-0001',
        total: 105000,
        paid: 105000,
        issuedAt: DateTime(2026, 6, 10, 12),
      ).copyWith(taxablePaise: 100000, cgstPaise: 2500, sgstPaise: 2500),
      sampleOpenInvoice(
        id: 'b',
        number: 'INV-0002',
        total: 50000,
        paid: 50000,
        issuedAt: DateTime(2026, 6, 11, 9),
      ),
      sampleOpenInvoice(
        id: 'c',
        number: 'INV-0003',
        total: 20000,
        issuedAt: DateTime(2026, 6, 11, 15),
      ).copyWith(status: InvoiceStatus.cancelled),
    ],
    creditNotes: [
      sampleCreditNote(
        id: 'cn1',
        total: 10500,
        refund: 10500,
        issuedAt: DateTime(2026, 6, 12, 10),
      ).copyWith(taxablePaise: 10000, cgstPaise: 250, sgstPaise: 250),
      sampleCreditNote(
        id: 'cn2',
        number: 'CN-0002',
        total: 20000,
        refund: 20000,
        issuedAt: DateTime(2026, 6, 11, 16),
      ),
    ],
  );
  final range = ReportRange.between(
    DateTime(2026, 6, 10),
    DateTime(2026, 6, 12),
  );

  group('buildSalesSummary', () {
    final s = buildSalesSummary(data);

    test('gross, returns and net', () {
      expect(s.grossPaise, 175000);
      expect(s.returnsPaise, 30500);
      expect(s.netPaise, 144500);
    });

    test('GST is net of credit notes', () {
      expect(s.taxPaise, 4500);
    });

    test('cancelled invoices are not orders', () {
      expect(s.orders, 2);
      expect(s.averageBillPaise, 72250);
    });

    test('an empty period is all zeros', () {
      final empty = buildSalesSummary(const ReportData());
      expect(empty.netPaise, 0);
      expect(empty.orders, 0);
      expect(empty.averageBillPaise, 0);
    });
  });

  group('buildSalesBuckets', () {
    test('one bucket per day with sales and returns on their own dates', () {
      final buckets = buildSalesBuckets(data, range);
      expect(buckets.map((b) => b.start), [
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 11),
        DateTime(2026, 6, 12),
      ]);
      expect(buckets.map((b) => b.grossPaise), [105000, 70000, 0]);
      expect(buckets.map((b) => b.returnsPaise), [0, 20000, 10500]);
      expect(buckets.map((b) => b.orders), [1, 1, 0]);
      expect(buckets.map((b) => b.netPaise), [105000, 50000, -10500]);
    });

    test('days with no activity still appear', () {
      final buckets = buildSalesBuckets(
        const ReportData(),
        ReportRange.between(DateTime(2026, 6, 1), DateTime(2026, 6, 5)),
      );
      expect(buckets, hasLength(5));
      expect(buckets.every((b) => b.netPaise == 0), isTrue);
    });

    test('long ranges are grouped by month', () {
      final longRange = ReportRange.between(
        DateTime(2026, 5, 1),
        DateTime(2026, 7, 31),
      );
      expect(defaultGranularity(longRange), SalesGranularity.month);

      final buckets = buildSalesBuckets(data, longRange);
      expect(buckets.map((b) => b.start), [
        DateTime(2026, 5),
        DateTime(2026, 6),
        DateTime(2026, 7),
      ]);
      expect(buckets[1].netPaise, 144500);
      expect(buckets[0].netPaise, 0);
    });

    test('data outside the range is still counted, not lost', () {
      final late = ReportData(
        invoices: [
          sampleOpenInvoice(
            id: 'z',
            total: 1000,
            issuedAt: DateTime(2026, 6, 20),
          ),
        ],
      );
      final buckets = buildSalesBuckets(late, range);
      expect(buckets, hasLength(4));
      expect(buckets.last.start, DateTime(2026, 6, 20));
    });

    test('labels', () {
      final day = buildSalesBuckets(data, range).first;
      expect(bucketLabel(day, SalesGranularity.day), '10 Jun');
      expect(bucketLabel(day, SalesGranularity.month), 'Jun 2026');
    });
  });

  group('buildSalesDocument', () {
    final doc = buildSalesDocument(data, range);

    String metric(String label) =>
        doc.metrics.firstWhere((m) => m.label == label).value.text;

    test('summary metrics', () {
      expect(metric('Gross sales'), '₹1,750.00');
      expect(metric('Returns'), '₹305.00');
      expect(metric('Net sales'), '₹1,445.00');
      expect(metric('of which GST'), '₹45.00');
      expect(metric('Orders'), '2');
      expect(metric('Average bill'), '₹722.50');
      expect(metric('Est. profit'), '—');
    });

    test('the table adds up to the summary', () {
      final table = doc.sections.single.table;
      expect(table.rows, hasLength(3));
      expect(table.footer![0].text, 'Total');
      expect(table.footer![4].text, '₹1,445.00');
    });

    test('the chart never goes below zero', () {
      expect(doc.chart.map((p) => p.valuePaise), [105000, 50000, 0]);
      expect(doc.chart.first.label, '10 Jun');
    });

    test('titles and file name', () {
      expect(doc.title, 'Sales report');
      expect(doc.periodLabel, '10 Jun 2026 to 12 Jun 2026');
      expect(doc.fileStem, 'sales-report-10-jun-2026-to-12-jun-2026');
    });
  });
}
