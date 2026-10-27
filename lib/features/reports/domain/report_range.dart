import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/core/utils/date_format.dart';

part 'report_range.freezed.dart';

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// A span of whole days. Both ends are inclusive and sit at midnight.
@freezed
abstract class ReportRange with _$ReportRange {
  const ReportRange._();

  const factory ReportRange({required DateTime from, required DateTime to}) =
      _ReportRange;

  /// Orders two dates and moves them to midnight.
  static ReportRange between(DateTime a, DateTime b) {
    final x = dayOf(a);
    final y = dayOf(b);
    return x.isAfter(y)
        ? ReportRange(from: y, to: x)
        : ReportRange(from: x, to: y);
  }

  /// Midnight after the last day, for `< toExclusive` comparisons.
  DateTime get toExclusive => DateTime(to.year, to.month, to.day + 1);

  int get dayCount =>
      DateTime.utc(
        to.year,
        to.month,
        to.day,
      ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
      1;

  bool contains(DateTime moment) =>
      !moment.isBefore(from) && moment.isBefore(toExclusive);

  String get label => from == to
      ? formatDate(from)
      : '${formatDate(from)} to ${formatDate(to)}';
}

enum ReportPreset {
  today('Today'),
  yesterday('Yesterday'),
  last7Days('Last 7 days'),
  thisMonth('This month'),
  lastMonth('Last month'),
  last30Days('Last 30 days'),
  thisFinancialYear('This financial year'),
  custom('Custom range');

  const ReportPreset(this.label);

  final String label;

  /// Null for [custom], which comes from the date picker.
  ReportRange? range(DateTime now) {
    final today = dayOf(now);
    switch (this) {
      case ReportPreset.today:
        return ReportRange(from: today, to: today);
      case ReportPreset.yesterday:
        final y = DateTime(now.year, now.month, now.day - 1);
        return ReportRange(from: y, to: y);
      case ReportPreset.last7Days:
        return ReportRange(
          from: DateTime(now.year, now.month, now.day - 6),
          to: today,
        );
      case ReportPreset.thisMonth:
        return ReportRange(from: DateTime(now.year, now.month), to: today);
      case ReportPreset.lastMonth:
        return ReportRange(
          from: DateTime(now.year, now.month - 1),
          to: DateTime(now.year, now.month, 0),
        );
      case ReportPreset.last30Days:
        return ReportRange(
          from: DateTime(now.year, now.month, now.day - 29),
          to: today,
        );
      case ReportPreset.thisFinancialYear:
        // The Indian financial year runs from 1 April to 31 March.
        final startYear = now.month >= 4 ? now.year : now.year - 1;
        return ReportRange(from: DateTime(startYear, 4), to: today);
      case ReportPreset.custom:
        return null;
    }
  }
}
