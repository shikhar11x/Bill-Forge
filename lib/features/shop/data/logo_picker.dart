import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:billforge/core/utils/app_logger.dart';

class LogoPickResult {
  const LogoPickResult.picked(Uint8List this.bytes) : error = null;
  const LogoPickResult.cancelled() : bytes = null, error = null;
  const LogoPickResult.failed(String this.error) : bytes = null;

  final Uint8List? bytes;

  /// User-friendly message when picking failed.
  final String? error;
}

/// The only file that touches `file_picker` (pinned to 10.x; v12+ changed the
/// API, so a future migration is confined to this file).
abstract final class LogoPicker {
  static const maxBytes = 512 * 1024;

  static Future<LogoPickResult> pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const LogoPickResult.cancelled();
      }
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        return const LogoPickResult.failed('Could not read that image.');
      }
      if (bytes.length > maxBytes) {
        return const LogoPickResult.failed(
          'Logo is too large. Choose an image under 512 KB.',
        );
      }
      return LogoPickResult.picked(bytes);
    } catch (error, stack) {
      AppLogger.error('Logo pick failed', error: error, stackTrace: stack);
      return const LogoPickResult.failed('Could not open the file picker.');
    }
  }
}
