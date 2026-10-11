import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/application/invoice_share_providers.dart';
import 'package:billforge/features/billing/data/pdf/invoice_pdf_builder.dart';
import 'package:billforge/features/billing/domain/invoice_document.dart';
import 'package:billforge/features/billing/domain/invoice_message.dart';

class ShareInvoiceDialog extends ConsumerStatefulWidget {
  const ShareInvoiceDialog({required this.document, super.key});

  final InvoiceDocument document;

  static Future<void> show(BuildContext context, InvoiceDocument document) =>
      showDialog<void>(
        context: context,
        builder: (_) => ShareInvoiceDialog(document: document),
      );

  @override
  ConsumerState<ShareInvoiceDialog> createState() => _ShareInvoiceDialogState();
}

class _ShareInvoiceDialogState extends ConsumerState<ShareInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(
    text: widget.document.invoice.customerPhone,
  );
  late final _message = TextEditingController(
    text: buildInvoiceMessage(widget.document),
  );
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
    // The launch starts before any await: browsers block pop-ups that are
    // opened after an async gap.
    final opened = await ref.read(invoiceShareServiceProvider).openChat(
          phone: _phoneOrNull,
          message: _message.text.trim(),
        );
    if (!mounted || opened) return;
    setState(() {
      _problem =
          'Could not open WhatsApp. Check that it is installed, or use Share PDF.';
    });
  }

  Future<void> _sharePdf() async {
    if (_sharing) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sharing = true;
      _problem = null;
    });
    try {
      final fonts = await ref.read(pdfFontsProvider.future);
      final options = ref.read(invoiceTemplateProvider);
      final bytes = await buildInvoicePdf(
        document: widget.document,
        options: options,
        fonts: fonts,
      );
      final number = widget.document.invoice.invoiceNumber ?? 'invoice';
      await ref.read(invoiceShareServiceProvider).sharePdf(
            bytes: bytes,
            fileName: '$number.pdf',
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
                      'Share invoice',
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
                        'Open WhatsApp starts a chat with this message. '
                        'WhatsApp links cannot attach files, so use Share PDF '
                        'to send the PDF: on Android pick WhatsApp from the '
                        'share menu; on web and Windows the PDF is saved so '
                        'you can attach it in WhatsApp.',
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
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