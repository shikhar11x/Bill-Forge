import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
