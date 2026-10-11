const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];
const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _below100(int n) {
  if (n < 20) return _ones[n];
  final tens = _tens[n ~/ 10];
  final ones = _ones[n % 10];
  return ones.isEmpty ? tens : '$tens $ones';
}

String _below1000(int n) {
  final parts = <String>[];
  if (n ~/ 100 > 0) parts.add('${_ones[n ~/ 100]} Hundred');
  if (n % 100 > 0) parts.add(_below100(n % 100));
  return parts.join(' ');
}

/// Indian grouping (thousand, lakh, crore). [n] must be positive.
String _words(int n) {
  final parts = <String>[];
  final crore = n ~/ 10000000;
  final lakh = (n % 10000000) ~/ 100000;
  final thousand = (n % 100000) ~/ 1000;
  final rest = n % 1000;
  if (crore > 0) parts.add('${_words(crore)} Crore');
  if (lakh > 0) parts.add('${_below100(lakh)} Lakh');
  if (thousand > 0) parts.add('${_below100(thousand)} Thousand');
  if (rest > 0) parts.add(_below1000(rest));
  return parts.join(' ');
}

/// 123456 paise -> "Rupees One Thousand Two Hundred Thirty Four and Fifty Six Paise Only".
String amountInWordsInr(int paise) {
  if (paise <= 0) return 'Rupees Zero Only';
  final rupees = paise ~/ 100;
  final remainder = paise % 100;
  final parts = [
    if (rupees > 0) 'Rupees ${_words(rupees)}',
    if (remainder > 0) '${_below100(remainder)} Paise',
  ];
  return '${parts.join(' and ')} Only';
}
