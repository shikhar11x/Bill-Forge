import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/reports/domain/report_range.dart';

void main() {
  final now = DateTime(2026, 6, 15, 10, 30);

  ReportRange range(ReportPreset p, [DateTime? at]) => p.range(at ?? now)!;

  test('presets', () {
    expect(range(ReportPreset.today).from, DateTime(2026, 6, 15));
    expect(range(ReportPreset.today).to, DateTime(2026, 6, 15));
    expect(range(ReportPreset.yesterday).from, DateTime(2026, 6, 14));
    expect(range(ReportPreset.yesterday).to, DateTime(2026, 6, 14));

    final week = range(ReportPreset.last7Days);
    expect(week.from, DateTime(2026, 6, 9));
    expect(week.to, DateTime(2026, 6, 15));
    expect(week.dayCount, 7);

    final month = range(ReportPreset.thisMonth);
    expect(month.from, DateTime(2026, 6, 1));
    expect(month.to, DateTime(2026, 6, 15));

    final last = range(ReportPreset.lastMonth);
    expect(last.from, DateTime(2026, 5, 1));
    expect(last.to, DateTime(2026, 5, 31));

    final thirty = range(ReportPreset.last30Days);
    expect(thirty.from, DateTime(2026, 5, 17));
    expect(thirty.dayCount, 30);

    expect(ReportPreset.custom.range(now), isNull);
  });

  test('last month across a year boundary', () {
    final january = range(ReportPreset.lastMonth, DateTime(2026, 1, 10));
    expect(january.from, DateTime(2025, 12, 1));
    expect(january.to, DateTime(2025, 12, 31));
  });

  test('the financial year starts on 1 April', () {
    final after = range(ReportPreset.thisFinancialYear);
    expect(after.from, DateTime(2026, 4, 1));
    expect(after.to, DateTime(2026, 6, 15));

    final before = range(ReportPreset.thisFinancialYear, DateTime(2026, 2, 10));
    expect(before.from, DateTime(2025, 4, 1));

    expect(
      range(ReportPreset.thisFinancialYear, DateTime(2026, 4, 1)).from,
      DateTime(2026, 4, 1),
    );
  });

  test('between orders and normalises dates', () {
    final r = ReportRange.between(
      DateTime(2026, 6, 20, 18),
      DateTime(2026, 6, 10, 8),
    );
    expect(r.from, DateTime(2026, 6, 10));
    expect(r.to, DateTime(2026, 6, 20));
    expect(
      r,
      ReportRange.between(DateTime(2026, 6, 10), DateTime(2026, 6, 20)),
    );
  });

  test('contains includes the whole last day only', () {
    final r = ReportRange.between(DateTime(2026, 6, 10), DateTime(2026, 6, 12));
    expect(r.toExclusive, DateTime(2026, 6, 13));
    expect(r.contains(DateTime(2026, 6, 10)), isTrue);
    expect(r.contains(DateTime(2026, 6, 12, 23, 59)), isTrue);
    expect(r.contains(DateTime(2026, 6, 13)), isFalse);
    expect(r.contains(DateTime(2026, 6, 9, 23, 59)), isFalse);
  });

  test('labels', () {
    expect(
      ReportRange.between(DateTime(2026, 6, 10), DateTime(2026, 6, 10)).label,
      '10 Jun 2026',
    );
    expect(
      ReportRange.between(DateTime(2026, 6, 1), DateTime(2026, 6, 15)).label,
      '01 Jun 2026 to 15 Jun 2026',
    );
  });
}
