import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

class _G {
  _G(this.hsn, this.rate);

  final String hsn;
  final int rate;
  int taxable = 0;
  int cgst = 0;
  int sgst = 0;
  int igst = 0;

  int get tax => cgst + sgst + igst;
}

/// Taxable value and tax net of credit notes, grouped by [keyOf].
List<_G> _group(ReportData d, String Function(String hsn, int rate) keyOf) {
  final groups = <String, _G>{};

  void add({
    required String? hsn,
    required int rate,
    required int taxable,
    required int cgst,
    required int sgst,
    required int igst,
    required int sign,
  }) {
    final code = hsn ?? '';
    final g = groups.putIfAbsent(keyOf(code, rate), () => _G(code, rate));
    g.taxable += sign * taxable;
    g.cgst += sign * cgst;
    g.sgst += sign * sgst;
    g.igst += sign * igst;
  }

  for (final i in d.invoiceItems) {
    add(
      hsn: i.hsnCode,
      rate: i.gstRatePercent,
      taxable: i.taxablePaise,
      cgst: i.cgstPaise,
      sgst: i.sgstPaise,
      igst: i.igstPaise,
      sign: 1,
    );
  }
  for (final i in d.creditNoteItems) {
    add(
      hsn: i.hsnCode,
      rate: i.gstRatePercent,
      taxable: i.taxablePaise,
      cgst: i.cgstPaise,
      sgst: i.sgstPaise,
      igst: i.igstPaise,
      sign: -1,
    );
  }

  return groups.values.toList()..sort((a, b) {
    final byRate = a.rate.compareTo(b.rate);
    return byRate != 0 ? byRate : a.hsn.compareTo(b.hsn);
  });
}

ReportTable _table(
  List<_G> groups, {
  required bool withHsn,
  required String firstLabel,
}) {
  return ReportTable(
    columns: [
      ReportColumn(firstLabel),
      if (withHsn) const ReportColumn('Rate', numeric: true),
      const ReportColumn('Taxable value', numeric: true),
      const ReportColumn('CGST', numeric: true),
      const ReportColumn('SGST', numeric: true),
      const ReportColumn('IGST', numeric: true),
      const ReportColumn('Total tax', numeric: true),
    ],
    rows: [
      for (final g in groups)
        [
          ReportCell(withHsn ? (g.hsn.isEmpty ? '—' : g.hsn) : '${g.rate}%'),
          if (withHsn) ReportCell.percent(g.rate),
          ReportCell.money(g.taxable),
          ReportCell.money(g.cgst),
          ReportCell.money(g.sgst),
          ReportCell.money(g.igst),
          ReportCell.money(g.tax),
        ],
    ],
    footer: [
      const ReportCell('Total'),
      if (withHsn) const ReportCell(''),
      ReportCell.money(sumBy(groups, (g) => g.taxable)),
      ReportCell.money(sumBy(groups, (g) => g.cgst)),
      ReportCell.money(sumBy(groups, (g) => g.sgst)),
      ReportCell.money(sumBy(groups, (g) => g.igst)),
      ReportCell.money(sumBy(groups, (g) => g.tax)),
    ],
  );
}

ReportDocument buildGstDocument(ReportData data, ReportRange range) {
  final byRate = _group(data, (hsn, rate) => '$rate');
  final byHsn = _group(data, (hsn, rate) => '$hsn|$rate');

  final collected = sumBy(data.invoices, (i) => i.taxPaise);
  final reversed = sumBy(data.creditNotes, (n) => n.taxPaise);
  final net = collected - reversed;

  return ReportDocument(
    title: 'GST report',
    periodLabel: range.label,
    metrics: [
      ReportMetric(
        'Taxable value',
        ReportCell.money(sumBy(byRate, (g) => g.taxable)),
      ),
      ReportMetric('CGST', ReportCell.money(sumBy(byRate, (g) => g.cgst))),
      ReportMetric('SGST', ReportCell.money(sumBy(byRate, (g) => g.sgst))),
      ReportMetric('IGST', ReportCell.money(sumBy(byRate, (g) => g.igst))),
      ReportMetric('Net GST', ReportCell.money(net)),
      ReportMetric('GST on invoices', ReportCell.money(collected)),
      ReportMetric('GST on credit notes', ReportCell.money(reversed)),
    ],
    sections: [
      ReportSection(
        title: 'By GST rate',
        table: _table(byRate, withHsn: false, firstLabel: 'Rate'),
      ),
      ReportSection(
        title: 'By HSN / SAC',
        table: _table(byHsn, withHsn: true, firstLabel: 'HSN / SAC'),
      ),
    ],
    notes: [
      if (collected == 0 && reversed == 0) 'No GST was charged in this period. GST applies to regular taxpayers only.',
      'Figures are net of credit notes issued in this period. Check them '
          'with your accountant before filing returns.',
    ],
  );
}
