import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/whatsapp_link.dart';
import 'package:billforge/features/billing/domain/invoice_share_service.dart';

class WhatsAppShareService implements InvoiceShareService {
  const WhatsAppShareService();

  @override
  Future<bool> openChat({String? phone, required String message}) async {
    try {
      return await launchUrl(
        buildWhatsAppUri(phone: phone, message: message),
        mode: LaunchMode.externalApplication,
      );
    } catch (error, stack) {
      AppLogger.error(
        'Opening WhatsApp failed',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    String? message,
  }) async {
    // A false result usually means the user dismissed the menu, so it is not
    // treated as an error. Real failures throw.
    await Printing.sharePdf(bytes: bytes, filename: fileName, body: message);
  }
}
