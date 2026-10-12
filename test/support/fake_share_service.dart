import 'dart:typed_data';

import 'package:billforge/features/billing/domain/invoice_share_service.dart';

class FakeShareService implements InvoiceShareService {
  bool chatResult = true;
  bool pdfThrows = false;

  int chatCalls = 0;
  String? chatPhone;
  String? chatMessage;

  int pdfCalls = 0;
  Uint8List? pdfBytes;
  String? pdfName;
  String? pdfMessage;

  @override
  Future<bool> openChat({String? phone, required String message}) async {
    chatCalls++;
    chatPhone = phone;
    chatMessage = message;
    return chatResult;
  }

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    String? message,
  }) async {
    pdfCalls++;
    pdfBytes = bytes;
    pdfName = fileName;
    pdfMessage = message;
    if (pdfThrows) throw StateError('share failed');
  }
}
