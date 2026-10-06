import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/widgets/app_dialog.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';

Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  // Read before awaiting so we don't touch `ref` after a possible dispose.
  final controller = ref.read(authControllerProvider.notifier);
  final confirmed = await AppDialog.confirm(
    context,
    title: 'Sign out?',
    message: 'You will need to sign in again to continue.',
    confirmLabel: 'Sign out',
  );
  if (confirmed) controller.signOut();
}
