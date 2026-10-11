import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/amount_in_words.dart';

void main() {
  test('zero and invalid amounts', () {
    expect(amountInWordsInr(0), 'Rupees Zero Only');
    expect(amountInWordsInr(-5), 'Rupees Zero Only');
  });

  test('small amounts', () {
    expect(amountInWordsInr(100), 'Rupees One Only');
    expect(amountInWordsInr(1900), 'Rupees Nineteen Only');
    expect(amountInWordsInr(2100), 'Rupees Twenty One Only');
    expect(amountInWordsInr(10000), 'Rupees One Hundred Only');
  });

  test('uses Indian grouping', () {
    expect(
      amountInWordsInr(123400),
      'Rupees One Thousand Two Hundred Thirty Four Only',
    );
    expect(amountInWordsInr(10000000), 'Rupees One Lakh Only');
    expect(amountInWordsInr(1000000000), 'Rupees One Crore Only');
    expect(
      amountInWordsInr(1234567800),
      'Rupees One Crore Twenty Three Lakh Forty Five Thousand Six Hundred Seventy Eight Only',
    );
  });

  test('very large amounts keep stacking crores', () {
    expect(amountInWordsInr(100000000000), 'Rupees One Hundred Crore Only');
    expect(amountInWordsInr(1000000000000), 'Rupees One Thousand Crore Only');
  });

  test('paise', () {
    expect(amountInWordsInr(50), 'Fifty Paise Only');
    expect(amountInWordsInr(10050), 'Rupees One Hundred and Fifty Paise Only');
    expect(amountInWordsInr(105), 'Rupees One and Five Paise Only');
  });
}
