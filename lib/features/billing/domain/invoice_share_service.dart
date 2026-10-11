import 'dart:typed_data';

/// How an invoice leaves the app. Today: WhatsApp click-to-chat and the
/// system share sheet. The WhatsApp Business API can later be another
/// implementation, swapped in through `invoiceShareServiceProvider`.
abstract interface class InvoiceShareService {
  /// Opens a chat with [message] prefilled. With no [phone], the user picks
  /// the contact. Returns false when nothing could be opened.
  Future<bool> openChat({String? phone, required String message});

  /// Opens the system share menu with the PDF attached. [message] is shared
  /// along with it where the platform supports that. Throws on failure.
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    String? message,
  });
}