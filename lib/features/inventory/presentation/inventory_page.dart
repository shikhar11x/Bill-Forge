import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/features/inventory/presentation/widgets/purchases_tab.dart';
import 'package:billforge/features/inventory/presentation/widgets/stock_tab.dart';
import 'package:billforge/features/inventory/presentation/widgets/suppliers_tab.dart';

enum _InventoryTab { stock, purchases, suppliers }

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  _InventoryTab _tab = _InventoryTab.stock;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        final wide = !size.isMobile;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
            child: Padding(
              padding: EdgeInsets.all(wide ? AppSpacing.xxl : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<_InventoryTab>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _InventoryTab.stock,
                        label: Text('Stock'),
                      ),
                      ButtonSegment(
                        value: _InventoryTab.purchases,
                        label: Text('Purchases'),
                      ),
                      ButtonSegment(
                        value: _InventoryTab.suppliers,
                        label: Text('Suppliers'),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (s) => setState(() => _tab = s.first),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: switch (_tab) {
                      _InventoryTab.stock => const StockTab(),
                      _InventoryTab.purchases => const PurchasesTab(),
                      _InventoryTab.suppliers => const SuppliersTab(),
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}