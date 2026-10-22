import 'package:billforge/core/utils/formatters.dart';

/// What the billing screen knows about the selected customer's credit.
class CreditContext {
  const CreditContext({this.limitPaise, required this.outstandingPaise});

  /// Null means no limit is enforced.
  final int? limitPaise;
  final int outstandingPaise;
}

class CreditCheck {
  const CreditCheck({
    this.limitPaise,
    required this.outstandingPaise,
    required this.newDuePaise,
  });

  final int? limitPaise;
  final int outstandingPaise;

  /// Credit the bill being issued would add.
  final int newDuePaise;

  int get afterPaise => outstandingPaise + newDuePaise;

  /// A bill that adds no credit is always allowed, even if the customer is
  /// already over their limit.
  bool get allowed =>
      limitPaise == null || newDuePaise <= 0 || afterPaise <= limitPaise!;

  int get overByPaise => allowed ? 0 : afterPaise - limitPaise!;
}

CreditCheck checkCredit({
  int? limitPaise,
  required int outstandingPaise,
  required int newDuePaise,
}) => CreditCheck(
  limitPaise: limitPaise,
  outstandingPaise: outstandingPaise,
  newDuePaise: newDuePaise,
);

/// Only meaningful when [check] is not allowed.
String creditLimitMessage(CreditCheck check) =>
    'Credit limit of ${formatPaise(check.limitPaise!)} would be exceeded: '
    '${formatPaise(check.outstandingPaise)} is already owed and this bill adds '
    '${formatPaise(check.newDuePaise)}. Take more payment now, or raise the '
    'limit in the customer profile.';
