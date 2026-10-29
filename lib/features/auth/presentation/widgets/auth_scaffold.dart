import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/app_constants.dart';
import 'package:billforge/core/motion/app_motion.dart';
import 'package:billforge/core/motion/reveal.dart';
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
                child: Reveal(
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
        border: Border(right: BorderSide(color: scheme.outline)),
        gradient: RadialGradient(
          center: const Alignment(-0.9, -1),
          radius: 1.3,
          colors: [scheme.primary.withValues(alpha: 0.28), scheme.surface],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -80,
            bottom: -80,
            child: _Orb(size: 320, color: scheme.primary.withValues(alpha: 0.10)),
          ),
          Positioned(
            right: 120,
            top: 90,
            child: _Orb(size: 90, color: scheme.primary.withValues(alpha: 0.12)),
          ),
          Padding(
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
                    Reveal(
                      child: Text(
                        AppConstants.tagline,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Reveal(
                      index: 2,
                      child: _Point(
                        icon: Icons.cloud_off_rounded,
                        text: 'Keep billing even when the internet is down',
                      ),
                    ),
                    const Reveal(
                      index: 3,
                      child: _Point(
                        icon: Icons.receipt_long_rounded,
                        text: 'GST-ready invoices in seconds',
                      ),
                    ),
                    const Reveal(
                      index: 4,
                      child: _Point(
                        icon: Icons.chat_rounded,
                        text: 'Share invoices straight to WhatsApp',
                      ),
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
        ],
      ),
    );
  }
}

/// A soft circle that grows into place once.
class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.of(context, const Duration(milliseconds: 900)),
      curve: AppMotion.standard,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}