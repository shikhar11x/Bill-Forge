import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/billing/application/invoice_share_providers.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/payments/domain/payment_messages.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

/// Phone + message editor for WhatsApp, with an optional "Share PDF" action.
/// Used for payment reminders and statements.
class CustomerMessageDialog extends ConsumerStatefulWidget {
  const CustomerMessageDialog({
    required this.title,
    required this.message,
    this.phone,
    this.buildPdf,
    this.pdfFileName = 'document.pdf',
    super.key,
  });

  final String title;
  final String message;
  final String? phone;

  /// When set, a "Share PDF" button is shown.
  final Future<Uint8List> Function()? buildPdf;
  final String pdfFileName;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? phone,
    Future<Uint8List> Function()? buildPdf,
    String pdfFileName = 'document.pdf',
  }) => showDialog<void>(
    context: context,
    builder: (_) => CustomerMessageDialog(
      title: title,
      message: message,
      phone: phone,
      buildPdf: buildPdf,
      pdfFileName: pdfFileName,
    ),
  );

  @override
  ConsumerState<CustomerMessageDialog> createState() =>
      _CustomerMessageDialogState();
}

class _CustomerMessageDialogState extends ConsumerState<CustomerMessageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.phone);
  late final _message = TextEditingController(text: widget.message);
  bool _sharing = false;
  String? _problem;

  @override
  void dispose() {
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  String? get _phoneOrNull {
    final text = _phone.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _openChat() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _problem = null);
    // Launch before any await: browsers block pop-ups opened after a gap.
    final opened = await ref
        .read(invoiceShareServiceProvider)
        .openChat(phone: _phoneOrNull, message: _message.text.trim());
    if (!mounted || opened) return;
    setState(() {
      _problem = 'Could not open WhatsApp. Check that it is installed.';
    });
  }

  Future<void> _sharePdf() async {
    final build = widget.buildPdf;
    if (build == null || _sharing) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sharing = true;
      _problem = null;
    });
    try {
      final bytes = await build();
      await ref
          .read(invoiceShareServiceProvider)
          .sharePdf(
            bytes: bytes,
            fileName: widget.pdfFileName,
            message: _message.text.trim(),
          );
      if (mounted) setState(() => _sharing = false);
    } catch (error, stack) {
      AppLogger.error('Sharing PDF failed', error: error, stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _sharing = false;
        _problem = 'Could not share the PDF. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final hasPdf = widget.buildPdf != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.lg,
                    children: [
                      AppTextField(
                        label: 'Customer WhatsApp number (optional)',
                        hint: '98765 43210',
                        helper:
                            'Leave empty to choose a contact inside WhatsApp.',
                        controller: _phone,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.optional(Validators.phone),
                      ),
                      AppTextField(
                        label: 'Message',
                        controller: _message,
                        maxLines: 9,
                        validator: (v) => Validators.required(
                          v,
                          message: 'Message cannot be empty',
                        ),
                      ),
                      Text(
                        hasPdf
                            ? 'Open WhatsApp starts a chat with this message. WhatsApp links cannot attach files, so use Share PDF to send the PDF.'
                            : 'Open WhatsApp starts a chat with this message. Press send inside WhatsApp.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                      if (_problem != null)
                        Text(
                          _problem!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (hasPdf) ...[
                    Expanded(
                      child: AppButton(
                        label: 'Share PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        variant: AppButtonVariant.secondary,
                        expanded: true,
                        isLoading: _sharing,
                        onPressed: _sharePdf,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: AppButton(
                      label: 'Open WhatsApp',
                      icon: Icons.chat_outlined,
                      expanded: true,
                      onPressed: _sharing ? null : _openChat,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the reminder dialog for [customer]. Does nothing until the shop has
/// loaded.
Future<void> showReminderDialog(
  BuildContext context,
  WidgetRef ref, {
  required Customer customer,
  required List<Invoice> openInvoices,
}) async {
  final shop = shopOrNull(ref.read(shopProfileProvider));
  if (shop == null) return;
  await CustomerMessageDialog.show(
    context,
    title: 'Payment reminder',
    phone: customer.phone,
    message: buildReminderMessage(
      shop: shop,
      customerName: customer.name,
      openInvoices: openInvoices,
      now: DateTime.now(),
    ),
  );
}
