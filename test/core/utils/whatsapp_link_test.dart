import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/phone.dart';
import 'package:billforge/core/utils/whatsapp_link.dart';

void main() {
  group('whatsAppNumber', () {
    test('adds the country code to valid mobiles', () {
      expect(whatsAppNumber('9876543210'), '919876543210');
      expect(whatsAppNumber('98765 43210'), '919876543210');
      expect(whatsAppNumber('+91 98765-43210'), '919876543210');
    });

    test('rejects anything that is not an Indian mobile', () {
      expect(whatsAppNumber(null), isNull);
      expect(whatsAppNumber(''), isNull);
      expect(whatsAppNumber('12345'), isNull);
      expect(whatsAppNumber('5876543210'), isNull);
      expect(whatsAppNumber('98765432101'), isNull);
    });
  });

  group('buildWhatsAppUri', () {
    test('opens a specific chat when the number is valid', () {
      final uri = buildWhatsAppUri(
        phone: '9876543210',
        message: 'Hello World\nline 2',
      );
      expect(
        uri.toString(),
        'https://wa.me/919876543210?text=Hello%20World%0Aline%202',
      );
    });

    test('lets the user pick a contact when there is no number', () {
      expect(
        buildWhatsAppUri(message: 'Hi').toString(),
        'https://wa.me/?text=Hi',
      );
      expect(
        buildWhatsAppUri(phone: '123', message: 'Hi').toString(),
        'https://wa.me/?text=Hi',
      );
    });

    test('percent-encodes the rupee sign and keeps bold markers readable', () {
      // Dart leaves "*" unescaped, which WhatsApp reads as bold markers.
      final uri = buildWhatsAppUri(message: '*Total* ₹5');
      expect(uri.toString(), 'https://wa.me/?text=*Total*%20%E2%82%B95');
    });
  });
}
