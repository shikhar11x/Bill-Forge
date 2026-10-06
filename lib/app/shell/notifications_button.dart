import 'package:flutter/material.dart';

import 'package:billforge/app/shell/notifications_panel.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/responsive/breakpoints.dart';

class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  void _open(BuildContext context) {
    final isMobile = Breakpoints.fromWidth(MediaQuery.sizeOf(context).width)
        .isMobile;

    if (isMobile) {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const SafeArea(child: NotificationsPanel()),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => const Dialog(
        alignment: Alignment.topRight,
        insetPadding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          64,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: SizedBox(width: 380, child: NotificationsPanel()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      icon: const Icon(Icons.notifications_none_rounded),
      onPressed: () => _open(context),
    );
  }
}
