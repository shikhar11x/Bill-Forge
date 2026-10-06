import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/database_providers.dart';
import 'package:billforge/features/shop/data/drift_shop_repository.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';
import 'package:billforge/features/shop/domain/shop_repository.dart';

final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => DriftShopRepository(ref.watch(appDatabaseProvider)),
);

/// AsyncData(null) means "loaded, no shop yet" (needs onboarding).
final shopProfileProvider = StreamProvider<ShopProfile?>(
  (ref) => ref.watch(shopRepositoryProvider).watchShop(),
);

ShopProfile? shopOrNull(AsyncValue<ShopProfile?> value) => switch (value) {
  AsyncData(:final value) => value,
  _ => null,
};
