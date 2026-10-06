/// e.g. ("INV", 7) -> "INV-0007". Phase 5 owns the actual counter.
String formatInvoiceNumber(String prefix, int number, {int pad = 4}) =>
    '$prefix-${number.toString().padLeft(pad, '0')}';
