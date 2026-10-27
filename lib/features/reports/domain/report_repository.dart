import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

abstract interface class ReportRepository {
  /// All the rows needed to build any report for [range].
  Future<ReportData> load(ReportRange range);
}
