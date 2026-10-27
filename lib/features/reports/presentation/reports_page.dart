import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/application/invoice_share_providers.dart';
import 'package:billforge/features/reports/application/report_providers.dart';
import 'package:billforge/features/reports/data/pdf/report_pdf_builder.dart';
import 'package:billforge/features/reports/domain/csv_export.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/presentation/widgets/report_view.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportPreset _preset = ReportPreset.thisMonth;
  ReportRange? _custom;
  ReportTab _tab = ReportTab.sales;

  /// Bumped to redraw the dropdown when a pick is cancelled.
  int _dropdownRevision = 0;

  ReportRange get _range {
    final now = DateTime.now();
    return _preset.range(now) ?? _custom ?? ReportPreset.thisMonth.range(now)!;
  }

  Future<void> _pickCustom() async {
    final range = _range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: range.from, end: range.to),
    );
    if (!mounted) return;
    setState(() {
      if (picked != null) {
        _custom = ReportRange.between(picked.start, picked.end);
        _preset = ReportPreset.custom;
      }
      _dropdownRevision++;
    });
  }

  void _onPreset(ReportPreset? preset) {
    if (preset == null) return;
    if (preset == ReportPreset.custom) {
      _pickCustom();
    } else {
      setState(() => _preset = preset);
    }
  }

  Future<void> _copyCsv(ReportDocument doc) async {
    await Clipboard.setData(ClipboardData(text: reportToCsv(doc)));
    if (!mounted) return;
    AppToast.show(
      context,
      'CSV copied. Paste it into Excel or Google Sheets.',
      type: ToastType.success,
    );
  }

  Future<void> _sharePdf(ReportDocument doc) async {
    final shop = shopOrNull(ref.read(shopProfileProvider));
    if (shop == null) return;
    try {
      final fonts = await ref.read(pdfFontsProvider.future);
      final bytes = await buildReportPdf(
        shop: shop,
        document: doc,
        fonts: fonts,
      );
      await ref
          .read(invoiceShareServiceProvider)
          .sharePdf(bytes: bytes, fileName: '${doc.fileStem}.pdf');
    } catch (error, stack) {
      AppLogger.error('Sharing report failed', error: error, stackTrace: stack);
      if (!mounted) return;
      AppToast.show(
        context,
        'Could not share the PDF. Please try again.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sharing needs the shop, so keep it loaded while this page is open.
    ref.watch(shopProfileProvider);

    final theme = Theme.of(context);
    final range = _range;
    final key = (_tab, range);
    final docAsync = ref.watch(reportDocumentProvider(key));

    final Widget body = docAsync.when(
      loading: () => const SizedBox(height: 320, child: AppListSkeleton()),
      error: (error, stack) {
        AppLogger.error('Report failed', error: error, stackTrace: stack);
        return SizedBox(
          height: 320,
          child: AppErrorState(
            message: const StorageFailure().message,
            onRetry: () => ref.invalidate(reportDocumentProvider(key)),
          ),
        );
      },
      data: (doc) => ReportView(
        document: doc,
        onCopyCsv: () => _copyCsv(doc),
        onSharePdf: () => _sharePdf(doc),
      ),
    );

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 240,
                child: AppDropdown<ReportPreset>(
                  key: ValueKey('preset-$_preset-$_dropdownRevision'),
                  label: 'Period',
                  value: _preset,
                  items: ReportPreset.values,
                  itemLabel: (p) => p.label,
                  onChanged: _onPreset,
                ),
              ),
              if (_preset == ReportPreset.custom)
                AppButton(
                  label: 'Choose dates',
                  icon: Icons.event_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _pickCustom,
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  range.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in ReportTab.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: t == _tab,
                  onSelected: (_) => setState(() => _tab = t),
                ),
            ],
          ),
          body,
        ],
      ),
    );
  }
}
