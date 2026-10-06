import 'dart:math';

final _random = Random();

/// Local, collision-resistant id. The server will assign tenant-scoped ids
/// during sync (Phase 11-12).
String newId(String prefix) {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = _random.nextInt(1 << 24).toRadixString(36);
  return '${prefix}_$time$salt';
}
