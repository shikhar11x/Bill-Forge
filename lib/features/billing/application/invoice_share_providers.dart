import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/features/billing/data/sharing/whatsapp_share_service.dart';
import 'package:billforge/features/billing/domain/invoice_share_service.dart';

/// Override this to plug in another sender (e.g. the WhatsApp Business API).
final invoiceShareServiceProvider = Provider<InvoiceShareService>(
  (ref) => const WhatsAppShareService(),
);
