import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueX<T> on AsyncValue<T> {
  /// Current or previous data. Null only if nothing has loaded yet.
  /// Lets lists keep showing old rows while a refreshed query loads.
  T? get dataOrNull => hasValue ? requireValue : null;
}
