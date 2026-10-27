import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/reports/domain/csv_export.dart';
import 'package:billforge/features/reports/domain/report_models.dart';

void main() {
  test('csvRupees writes plain signed numbers', () {
    expect(csvRupees(150000), '1500.00');
    expect(csvRupees(5), '0.05');
    expect(csvRupees(0), '0.00');
    expect(csvRupees(-150), '-1.50');
    expect(csvRupees(-50), '-0.50');
  });

  group('csvEscape', () {
    test('quotes values with commas, quotes or line breaks', () {
      expect(csvEscape('plain'), 'plain');
      expect(csvEscape('a,b'), '"a,b"');
      expect(csvEscape('say "hi"'), '"say ""hi"""');
      expect(csvEscape('two\nlines'), '"two\nlines"');
    });

    test('defuses spreadsheet formulas', () {
      expect(csvEscape('=SUM(A1:A9)'), "'=SUM(A1:A9)");
      expect(csvEscape('@cmd'), "'@cmd");
      expect(csvEscape('-1.50'), '-1.50');
    });
  });

  test('a whole report', () {
    final doc = ReportDocument(
      title: 'Sales, "June"',
      periodLabel: '01 Jun 2026',
      metrics: [ReportMetric('Net', ReportCell.money(-50))],
      sections: [
        ReportSection(
          title: 'By day',
          table: ReportTable(
            columns: const [
              ReportColumn('Name'),
              ReportColumn('Amount', numeric: true),
            ],
            rows: [
              [const ReportCell('=SUM(A1)'), ReportCell.money(150000)],
              [const ReportCell('He said "hi", ok'), ReportCell.money(5)],
            ],
            footer: [const ReportCell('Total'), ReportCell.money(150005)],
          ),
        ),
      ],
      notes: const ['Note one'],
    );

    expect(reportToCsv(doc).split('\r\n'), [
      '"Sales, ""June"""',
      '01 Jun 2026',
      '',
      'Summary',
      'Net,-0.50',
      '',
      'By day',
      'Name,Amount',
      "'=SUM(A1),1500.00",
      '"He said ""hi"", ok",0.05',
      'Total,1500.05',
      '',
      'Note one',
    ]);
  });

  test('a report with no summary or sections still exports', () {
    final csv = reportToCsv(
      const ReportDocument(title: 'Empty', periodLabel: 'Today'),
    );
    expect(csv, 'Empty\r\nToday\r\n');
  });
}
