import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/app_constants.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/core/widgets/brand_mark.dart';

/// Shared layout for login/register. Desktop: brand panel + form.
/// Mobile/tablet: centered form only.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ResponsiveBuilder(
        builder: (context, size) {
          final formPane = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!size.isDesktop) ...[
                      const BrandMark(size: 40),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    Text(title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    form,
                    const SizedBox(height: AppSpacing.xl),
                    footer,
                  ],
                ),
              ),
            ),
          );

          if (!size.isDesktop) return formPane;
          return Row(
            children: [
              const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(flex: 4, child: formPane),
            ],
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const BrandMark(),
                const SizedBox(width: AppSpacing.md),
                Text(AppConstants.appName, style: theme.textTheme.titleMedium),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.tagline,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _Point(
                  icon: Icons.cloud_off_rounded,
                  text: 'Keep billing even when the internet is down',
                ),
                const _Point(
                  icon: Icons.receipt_long_rounded,
                  text: 'GST-ready invoices in seconds',
                ),
                const _Point(
                  icon: Icons.chat_rounded,
                  text: 'Share invoices straight to WhatsApp',
                ),
              ],
            ),
            Text(
              'Made for Indian small businesses',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}