import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'package:billforge/features/billing/data/pdf/pdf_fonts.dart';

/// The real Inter font from the project's assets, so tests render ₹ without
/// "font not found" warnings.
PdfFonts loadTestFonts() {
  pw.Font load(String path) =>
      pw.Font.ttf(ByteData.sublistView(File(path).readAsBytesSync()));
  return PdfFonts(
    regular: load('assets/fonts/Inter-Regular.ttf'),
    bold: load('assets/fonts/Inter-Bold.ttf'),
  );
}