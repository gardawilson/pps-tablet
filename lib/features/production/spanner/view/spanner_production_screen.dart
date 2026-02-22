// lib/features/production/spanner/view/spanner_production_screen.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:pps_tablet/features/production/spanner/view/spanner_production_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';

import '../model/spanner_production_model.dart';
import '../view_model/spanner_production_view_model.dart';
import '../widgets/spanner_production_action_bar.dart';
import '../widgets/spanner_production_delete_dialog.dart';
import '../widgets/spanner_production_form_dialog.dart';
import '../widgets/spanner_production_header_table.dart';
import '../widgets/spanner_production_row_popover.dart';

class SpannerProductionScreen extends StatefulWidget {
  const SpannerProductionScreen({super.key});

  @override
  State<SpannerProductionScreen> createState() =>
      _SpannerProductionScreenState();
}

class _SpannerProductionScreenState extends State<SpannerProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  late final SpannerProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SpannerProductionViewModel();
    _viewModel.refreshPaged();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _showRowPopover({
    required BuildContext context,
    required SpannerProduction row,
    required Offset globalPos,
  }) async {
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final local = overlay.globalToLocal(globalPos);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        final safeLeft = local.dx.clamp(8.0, overlay.size.width - 320.0);
        final safeTop = local.dy.clamp(8.0, overlay.size.height - 220.0);

        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop,
              child: SpannerProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SpannerProductionInputScreen(
                          noProduksi: row.noProduksi,
                          isLocked: row.isLocked,
                          lastClosedDate: row.lastClosedDate,
                        ),
                      ),
                    );
                  });
                },
                onEdit: () async {
                  await _openEditDialog(context, row);
                },
                onDelete: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      return SpannerProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success = await _viewModel.deleteProduksi(
                            row.noProduksi,
                          );

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                    'No. Produksi ${row.noProduksi} berhasil dihapus.',
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (_) => ErrorStatusDialog(
                                title: 'Gagal Menghapus!',
                                message:
                                    _viewModel.saveError ??
                                    'Gagal menghapus data',
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
                onPrint: () {},
                onAuditHistory: () {
                  _navigateToAuditHistory(row);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAuditHistory(SpannerProduction header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noProduksi),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<SpannerProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<SpannerProductionViewModel>.value(
        value: _viewModel,
        child: const SpannerProductionFormDialog(),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (created != null) {
      _viewModel.refreshPaged();
      setState(() => _selectedNoProduksi = created.noProduksi);
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message: 'No. Produksi ${created.noProduksi} berhasil dibuat.',
        ),
      );
    }
  }

  Future<void> _openEditDialog(
    BuildContext ctx,
    SpannerProduction row,
  ) async {
    final updated = await showDialog<SpannerProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<SpannerProductionViewModel>.value(
        value: _viewModel,
        child: SpannerProductionFormDialog(header: row),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (updated != null) {
      _viewModel.refreshPaged();
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Mengupdate',
          message: 'No. Produksi ${updated.noProduksi} berhasil diperbarui.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpannerProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<SpannerProductionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Spanner'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: vm.refreshPaged,
                ),
              ],
            ),
            body: Column(
              children: [
                SpannerProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: SpannerProductionHeaderTable(
                    selectedNoProduksi: _selectedNoProduksi,
                    onRowTap: (r) =>
                        setState(() => _selectedNoProduksi = r.noProduksi),
                    onRowLongPress: (r, globalPos) async {
                      await _showRowPopover(
                        context: context,
                        row: r,
                        globalPos: globalPos,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
