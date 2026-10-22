import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/payments/domain/credit_check.dart';

void main() {
  test('no limit means always allowed', () {
    final check = checkCredit(outstandingPaise: 999999, newDuePaise: 999999);
    expect(check.allowed, isTrue);
    expect(check.overByPaise, 0);
  });

  test('allowed up to and including the limit', () {
    expect(
      checkCredit(
        limitPaise: 100000,
        outstandingPaise: 60000,
        newDuePaise: 40000,
      ).allowed,
      isTrue,
    );
  });

  test('blocked when the bill would take the customer over', () {
    final check = checkCredit(
      limitPaise: 100000,
      outstandingPaise: 60000,
      newDuePaise: 40001,
    );
    expect(check.allowed, isFalse);
    expect(check.afterPaise, 100001);
    expect(check.overByPaise, 1);
  });

  test('a bill that adds no credit is always allowed', () {
    final check = checkCredit(
      limitPaise: 100000,
      outstandingPaise: 150000, // already over the limit
      newDuePaise: 0,
    );
    expect(check.allowed, isTrue);
  });

  test('a limit of zero allows no credit at all', () {
    expect(
      checkCredit(limitPaise: 0, outstandingPaise: 0, newDuePaise: 1).allowed,
      isFalse,
    );
  });

  test('the message states the limit, balance and new credit', () {
    final message = creditLimitMessage(
      checkCredit(
        limitPaise: 100000,
        outstandingPaise: 60000,
        newDuePaise: 50000,
      ),
    );
    expect(message, contains('₹1,000.00'));
    expect(message, contains('₹600.00'));
    expect(message, contains('₹500.00'));
    expect(message, contains('would be exceeded'));
  });
}
