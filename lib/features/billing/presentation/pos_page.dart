import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/features/billing/application/bill_controller.dart';
import 'package:billforge/features/billing/presentation/widgets/cart_panel.dart';
import 'package:billforge/features/billing/presentation/widgets/product_picker.dart';

enum _PosView { products, cart }

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  _PosView _view = _PosView.products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bill = ref.watch(billControllerProvider);
    final total = ref.watch(billTotalsProvider).grandTotalPaise;

    return ResponsiveBuilder(
      builder: (context, size) {
        final header = Row(
          children: [
            IconButton(
              tooltip: 'Back to billing',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go(AppRoutes.billing),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                bill.draftId == null ? 'New bill' : 'Draft bill',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );

        final Widget body;
        if (size.isMobile) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_PosView>(
                showSelectedIcon: false,
                segments: [
                  const ButtonSegment(
                    value: _PosView.products,
                    label: Text('Products'),
                    icon: Icon(Icons.category_outlined),
                  ),
                  ButtonSegment(
                    value: _PosView.cart,
                    label: Text(
                      bill.isEmpty
                          ? 'Cart'
                          : 'Cart (${bill.itemCount}) · ${formatPaise(total, showDecimals: false)}',
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _view == _PosView.products
                    ? const ProductPicker()
                    : const CartPanel(),
              ),
            ],
          );
        } else {
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(flex: 3, child: ProductPicker(autofocus: true)),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(
                width: size.isDesktop ? 440 : 380,
                child: const CartPanel(),
              ),
            ],
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(
                size.isMobile ? AppSpacing.lg : AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
