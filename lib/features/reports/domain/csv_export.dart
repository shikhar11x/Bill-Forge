import 'package:billforge/features/reports/domain/report_models.dart';

/// Quotes a value when needed and defuses spreadsheet formulas: a cell that
/// starts with "=" or "@" would otherwise be run by Excel or Sheets.
String csvEscape(String value) {
  var v = value;
  if (v.startsWith('=') ||
      v.startsWith('@') ||
      v.startsWith('\t') ||
      v.startsWith('\r')) {
    v = "'$v";
  }
  if (v.contains(RegExp(r'[",\r\n]'))) {
    v = '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String _row(Iterable<String> cells) => cells.map(csvEscape).join(',');

/// The whole report as CSV: title, period, summary, then every table. Money
/// is written as plain numbers so a spreadsheet can add it up.
String reportToCsv(ReportDocument doc) {
  final lines = <String>[
    _row([doc.title]),
    _row([doc.periodLabel]),
    '',
  ];

  if (doc.metrics.isNotEmpty) {
    lines.add(_row(['Summary']));
    for (final m in doc.metrics) {
      lines.add(_row([m.label, m.value.csv]));
    }
    lines.add('');
  }

  for (final section in doc.sections) {
    final table = section.table;
    lines
      ..add(_row([section.title]))
      ..add(_row(table.columns.map((c) => c.label)));
    for (final row in table.rows) {
      lines.add(_row(row.map((c) => c.csv)));
    }
    final footer = table.footer;
    if (footer != null) lines.add(_row(footer.map((c) => c.csv)));
    lines.add('');
  }

  for (final note in doc.notes) {
    lines.add(_row([note]));
  }
  return lines.join('\r\n');
}
