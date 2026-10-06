import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/app_constants.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/brand_mark.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';
import 'package:billforge/features/auth/domain/auth_state.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(shopProfileProvider, (previous, next) {
      if (next.hasError) {
        AppLogger.error(
          'Could not load shop',
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    final signedIn =
        ref.watch(authControllerProvider).status == AuthStatus.authenticated;
    if (signedIn) {
      final shop = ref.watch(shopProfileProvider);
      if (shop.hasError && !shop.hasValue) {
        // In debug builds, show the real cause to speed up diagnosis.
        final detail = kDebugMode ? '\n\nDebug: ${shop.error}' : '';
        return Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: AppErrorState(
                message: '${const StorageFailure().message}$detail',
                onRetry: () => ref.invalidate(shopProfileProvider),
              ),
            ),
          ),
        );
      }
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 56),
            const SizedBox(height: AppSpacing.lg),
            Text(AppConstants.appName, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppConstants.tagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
