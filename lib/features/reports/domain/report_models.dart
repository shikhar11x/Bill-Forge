import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';

/// 12345 -> "123.45", -50 -> "-0.50": plain numbers a spreadsheet can add up.
String csvRupees(int paise) {
  final sign = paise < 0 ? '-' : '';
  final abs = paise.abs();
  return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}

int sumBy<T>(Iterable<T> items, int Function(T item) pick) =>
    items.fold<int>(0, (total, item) => total + pick(item));

/// One value in a report: [text] is shown on screen and in the PDF, [csv] is
/// the plain value written to spreadsheets.
class ReportCell {
  const ReportCell(this.text, {String? csv}) : csv = csv ?? text;

  factory ReportCell.money(int paise) =>
      ReportCell(formatPaise(paise), csv: csvRupees(paise));

  factory ReportCell.count(int value) => ReportCell('$value');

  factory ReportCell.qty(int milli, String unit) =>
      ReportCell('${formatMilli(milli)} $unit', csv: formatMilli(milli));

  factory ReportCell.percent(int value) => ReportCell('$value%', csv: '$value');

  static const empty = ReportCell('—', csv: '');

  final String text;
  final String csv;
}

class ReportColumn {
  const ReportColumn(this.label, {this.numeric = false});

  final String label;

  /// Numbers are right-aligned.
  final bool numeric;
}

class ReportTable {
  const ReportTable({required this.columns, required this.rows, this.footer});

  final List<ReportColumn> columns;
  final List<List<ReportCell>> rows;
  final List<ReportCell>? footer;
}

class ReportSection {
  const ReportSection({required this.title, required this.table});

  final String title;
  final ReportTable table;
}

class ReportMetric {
  const ReportMetric(this.label, this.value);

  final String label;
  final ReportCell value;
}

class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.valuePaise,
    this.tooltip,
  });

  final String label;
  final int valuePaise;
  final String? tooltip;
}

/// Everything one report tab shows, and everything that is exported.
class ReportDocument {
  const ReportDocument({
    required this.title,
    required this.periodLabel,
    this.metrics = const [],
    this.sections = const [],
    this.notes = const [],
    this.chartTitle,
    this.chart = const [],
  });

  final String title;
  final String periodLabel;
  final List<ReportMetric> metrics;
  final List<ReportSection> sections;
  final List<String> notes;
  final String? chartTitle;
  final List<ChartPoint> chart;

  /// A safe file name stem, e.g. "sales-report-01-jun-2026-to-15-jun-2026".
  String get fileStem => '$title $periodLabel'
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
