// lib/features/production/crusher/view/crusher_production_screen.dart
import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../view_model/crusher_production_view_model.dart';
import '../repository/crusher_production_repository.dart';
import '../model/crusher_production_model.dart';
import '../widgets/broker_delete_dialog.dart';
import '../widgets/crusher_production_action_bar.dart';
import '../widgets/crusher_production_form_dialog.dart';
import '../widgets/crusher_production_header_table.dart';
import '../widgets/crusher_production_row_popover.dart';
import 'crusher_production_input_screen.dart';

class CrusherProductionScreen extends StatefulWidget {
  const CrusherProductionScreen({super.key});

  @override
  State<CrusherProductionScreen> createState() =>
      _CrusherProductionScreenState();
}

class _CrusherProductionScreenState extends State<CrusherProductionScreen> {
  late final CrusherProductionViewModel _viewModel;
  final _searchCtl = TextEditingController();
  String? _selectedNoCrusherProduksi;

  @override
  void initState() {
    super.initState();
    _viewModel = CrusherProductionViewModel(
      repository: CrusherProductionRepository(),
    );
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
    required CrusherProduction row,
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
              child: CrusherProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),

                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CrusherProductionInputScreen(
                          noCrusherProduksi: row.noCrusherProduksi,
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
                      return CrusherProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success = await _viewModel.deleteProduksi(
                            row.noCrusherProduksi,
                          );

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                    'No. Crusher Produksi ${row.noCrusherProduksi} berhasil dihapus.',
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

                onPrint: () async {},

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

  void _navigateToAuditHistory(CrusherProduction header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noCrusherProduksi),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<CrusherProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: _viewModel,
        child: const CrusherProductionFormDialog(),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (created != null) {
      _viewModel.refreshPaged();
      setState(() => _selectedNoCrusherProduksi = created.noCrusherProduksi);
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message:
              'No. Crusher Produksi ${created.noCrusherProduksi} berhasil dibuat.',
        ),
      );
    }
  }

  Future<void> _openEditDialog(BuildContext ctx, CrusherProduction row) async {
    final updated = await showDialog<CrusherProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: _viewModel,
        child: CrusherProductionFormDialog(header: row),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (updated != null) {
      _viewModel.refreshPaged();
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Mengupdate',
          message:
              'No. Crusher Produksi ${updated.noCrusherProduksi} berhasil diperbarui.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<CrusherProductionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Crusher Production'),
              actions: [
                if (vm.isByDateMode)
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    tooltip: 'Kembali ke mode list',
                    onPressed: vm.exitByDateModeAndRefreshPaged,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: vm.refreshPaged,
                  ),
              ],
            ),
            body: Column(
              children: [
                CrusherProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: CrusherProductionHeaderTable(
                    selectedNoCrusherProduksi: _selectedNoCrusherProduksi,
                    onRowTap: (r) => setState(
                      () => _selectedNoCrusherProduksi = r.noCrusherProduksi,
                    ),
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
