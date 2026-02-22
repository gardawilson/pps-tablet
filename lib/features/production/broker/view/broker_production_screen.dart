// lib/features/production/broker/view/broker_production_screen.dart
import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../view_model/broker_production_view_model.dart';
import '../model/broker_production_model.dart';

// Action bar
import '../widgets/broker_delete_dialog.dart';
import '../widgets/broker_production_action_bar.dart';
import '../widgets/broker_production_form_dialog.dart';
import '../widgets/broker_production_header_table.dart';
import 'broker_production_input_screen.dart';
import '../widgets/broker_production_row_popover.dart';

class BrokerProductionScreen extends StatefulWidget {
  const BrokerProductionScreen({super.key});

  @override
  State<BrokerProductionScreen> createState() => _BrokerProductionScreenState();
}

class _BrokerProductionScreenState extends State<BrokerProductionScreen> {
  final _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  late final BrokerProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BrokerProductionViewModel();
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
    required BrokerProduction row,
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
              child: BrokerProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BrokerProductionInputScreen(
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
                      return BrokerProductionDeleteDialog(
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
                            final rawMsg =
                                _viewModel.saveError ?? 'Gagal menghapus data';
                            showDialog(
                              context: context,
                              builder: (_) => ErrorStatusDialog(
                                title: 'Gagal Menghapus!',
                                message: rawMsg,
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

  void _navigateToAuditHistory(BrokerProduction header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noProduksi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BrokerProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<BrokerProductionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Broker Production'),
              actions: [
                if (vm.isByDateMode)
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    onPressed: vm.exitByDateModeAndRefreshPaged,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: vm.refreshPaged,
                  ),
              ],
            ),
            body: Column(
              children: [
                BrokerProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: BrokerProductionHeaderTable(
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

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<BrokerProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const BrokerProductionFormDialog(),
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

  Future<void> _openEditDialog(BuildContext ctx, BrokerProduction row) async {
    final updated = await showDialog<BrokerProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => BrokerProductionFormDialog(header: row),
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
}
