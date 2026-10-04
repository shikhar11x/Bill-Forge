import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/validators.dart';

void main() {
  test('email', () {
    expect(Validators.email(''), 'Email is required');
    expect(Validators.email('nope'), 'Enter a valid email address');
    expect(Validators.email(' a@b.co '), isNull);
  });

  test('password', () {
    expect(Validators.password(''), 'Password is required');
    expect(Validators.password('short'), 'Use at least 8 characters');
    expect(Validators.password('longenough'), isNull);
  });

  test('matches', () {
    final check = Validators.matches(() => 'abc12345');
    expect(check('abc12345'), isNull);
    expect(check('different'), 'Passwords do not match');
  });
}