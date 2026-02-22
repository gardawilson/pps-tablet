// lib/features/production/packing/view/packing_production_screen.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:pps_tablet/features/production/packing/view/packing_production_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';

import '../model/packing_production_model.dart';
import '../view_model/packing_production_view_model.dart';
import '../widgets/packing_production_action_bar.dart';
import '../widgets/packing_production_delete_dialog.dart';
import '../widgets/packing_production_form_dialog.dart';
import '../widgets/packing_production_header_table.dart';
import '../widgets/packing_production_row_popover.dart';

class PackingProductionScreen extends StatefulWidget {
  const PackingProductionScreen({super.key});

  @override
  State<PackingProductionScreen> createState() =>
      _PackingProductionScreenState();
}

class _PackingProductionScreenState extends State<PackingProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoPacking;

  late final PackingProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PackingProductionViewModel();
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
    required PackingProduction row,
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
              child: PackingProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PackingProductionInputScreen(
                          noProduksi: row.noPacking,
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
                      return PackingProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success = await _viewModel.deleteProduksi(
                            row.noPacking,
                          );

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                    'No. Packing ${row.noPacking} berhasil dihapus.',
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

  void _navigateToAuditHistory(PackingProduction header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noPacking),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<PackingProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<PackingProductionViewModel>.value(
        value: _viewModel,
        child: const PackingProductionFormDialog(),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (created != null) {
      _viewModel.refreshPaged();
      setState(() => _selectedNoPacking = created.noPacking);
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message: 'No. Packing ${created.noPacking} berhasil dibuat.',
        ),
      );
    }
  }

  Future<void> _openEditDialog(
    BuildContext ctx,
    PackingProduction row,
  ) async {
    final updated = await showDialog<PackingProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<PackingProductionViewModel>.value(
        value: _viewModel,
        child: PackingProductionFormDialog(header: row),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (updated != null) {
      _viewModel.refreshPaged();
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Mengupdate',
          message: 'No. Packing ${updated.noPacking} berhasil diperbarui.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PackingProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<PackingProductionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Packing'),
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
                PackingProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: PackingProductionHeaderTable(
                    selectedNoPacking: _selectedNoPacking,
                    onRowTap: (r) =>
                        setState(() => _selectedNoPacking = r.noPacking),
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
