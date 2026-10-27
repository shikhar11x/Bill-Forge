import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/reports/data/pdf/report_pdf_builder.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/domain/sales_report.dart';

import '../../support/fakes.dart';
import '../../support/payment_fakes.dart';
import '../../support/pdf_test_fonts.dart';

void main() {
  final fonts = loadTestFonts();
  final shop = sampleShop();
  final range = ReportRange.between(
    DateTime(2026, 6, 10),
    DateTime(2026, 6, 12),
  );

  bool isPdf(List<int> bytes) =>
      bytes.length > 4 && String.fromCharCodes(bytes.take(4)) == '%PDF';

  test('builds a sales report PDF', () async {
    final doc = buildSalesDocument(
      ReportData(
        invoices: [
          sampleOpenInvoice(total: 105000, issuedAt: DateTime(2026, 6, 10, 12)),
        ],
      ),
      range,
    );
    final bytes = await buildReportPdf(shop: shop, document: doc, fonts: fonts);
    expect(isPdf(bytes), isTrue);
  });

  test('builds an empty report', () async {
    final bytes = await buildReportPdf(
      shop: shop,
      document: const ReportDocument(title: 'Empty', periodLabel: 'Today'),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('a long table flows onto extra pages', () async {
    final doc = ReportDocument(
      title: 'Long report',
      periodLabel: 'This year',
      sections: [
        ReportSection(
          title: 'Rows',
          table: ReportTable(
            columns: const [
              ReportColumn('Name'),
              ReportColumn('Amount', numeric: true),
            ],
            rows: [
              for (var i = 0; i < 150; i++)
                [ReportCell('Row $i'), ReportCell.money(i * 100)],
            ],
            footer: [const ReportCell('Total'), ReportCell.money(1)],
          ),
        ),
      ],
      notes: const ['A note'],
    );
    final bytes = await buildReportPdf(shop: shop, document: doc, fonts: fonts);
    expect(isPdf(bytes), isTrue);
  });
}
