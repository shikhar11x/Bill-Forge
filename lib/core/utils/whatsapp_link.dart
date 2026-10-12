import 'package:billforge/core/utils/phone.dart';

/// A WhatsApp click-to-chat link with [message] prefilled.
///
/// With a valid [phone] it opens that chat. Without one, WhatsApp lets the
/// user pick a contact. The text is percent-encoded (spaces as %20, newlines
/// as %0A), which WhatsApp reads correctly.
Uri buildWhatsAppUri({String? phone, required String message}) {
  final number = whatsAppNumber(phone);
  final text = Uri.encodeComponent(message);
  return Uri.parse('https://wa.me/${number ?? ''}?text=$text');
}
