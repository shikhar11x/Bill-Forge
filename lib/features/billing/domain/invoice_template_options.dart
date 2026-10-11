import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_template_options.freezed.dart';

enum InvoicePaper {
  a4('A4', 210),
  thermal80('80 mm', 80),
  thermal58('58 mm', 58);

  const InvoicePaper(this.label, this.widthMm);

  final String label;
  final double widthMm;

  bool get isThermal => this != a4;
}

@freezed
abstract class InvoiceTemplateOptions with _$InvoiceTemplateOptions {
  const factory InvoiceTemplateOptions({
    @Default(InvoicePaper.a4) InvoicePaper paper,
    @Default(true) bool showLogo,
    @Default(true) bool showHsn,
    @Default(true) bool showTaxSummary,
    @Default(true) bool showAmountInWords,
    @Default(true) bool showPaymentInstructions,
    @Default(true) bool showFooter,
    @Default(true) bool showSignature,
  }) = _InvoiceTemplateOptions;
}
