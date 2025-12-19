// lib/features/production/broker/view/broker_production_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../view_model/broker_production_view_model.dart';
import '../model/broker_production_model.dart';
import '../../../../core/utils/date_formatter.dart';

// Action bar
import '../widgets/broker_delete_dialog.dart';
import '../widgets/broker_production_action_bar.dart';
// Inputs screen (Scan action)
import '../widgets/broker_production_form_dialog.dart';
import 'broker_production_input_screen.dart';
// ⬇️ New: the popover panel
import '../widgets/broker_production_row_popover.dart';

class BrokerProductionScreen extends StatefulWidget {
  const BrokerProductionScreen({super.key});

  @override
  State<BrokerProductionScreen> createState() => _BrokerProductionScreenState();
}

class _BrokerProductionScreenState extends State<BrokerProductionScreen> {
  final _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  // ✅ Store VM instance as field
  late final BrokerProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    // ✅ Create VM once in initState
    _viewModel = BrokerProductionViewModel();

    debugPrint(
      '🟦🟦🟦 [BROKER_SCREEN] initState: Created VM hash=${_viewModel.hashCode}',
    );
    debugPrint(
      '🟦🟦🟦 [BROKER_SCREEN] initState: PagingController hash=${_viewModel.pagingController.hashCode}',
    );

    // Initialize first load
    _viewModel.refreshPaged();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _viewModel.dispose(); // ✅ Dispose VM
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
                          final success =
                          await _viewModel.deleteProduksi(row.noProduksi);

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
                onPrint: () async {
                  // optional
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use .value to provide existing VM instance
    return ChangeNotifierProvider<BrokerProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<BrokerProductionViewModel>(
        builder: (context, vm, _) {
          debugPrint(
            '🟦 [BROKER_SCREEN] Consumer.builder() called, VM hash=${vm.hashCode}',
          );
          debugPrint(
            '🟦 [BROKER_SCREEN] Consumer pagingController: hash=${vm.pagingController.hashCode}',
          );

          final columns = <TableColumnSpec<BrokerProduction>>[
            TableColumnSpec(
              title: 'NO. PRODUKSI',
              width: 160,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.noProduksi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'TANGGAL',
              width: 130,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(formatDateToShortId(r.tglProduksi)),
            ),
            TableColumnSpec(
              title: 'SHIFT',
              width: 70,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text('${r.shift}'),
            ),
            TableColumnSpec(
              title: 'MESIN',
              width: 180,
              cellBuilder: (_, r) => Text(
                r.namaMesin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'OPERATOR',
              width: 200,
              cellBuilder: (_, r) => Text(
                r.namaOperator,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'JAM',
              width: 70,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text('${r.jamKerja}'),
            ),
            TableColumnSpec(
              title: 'HM',
              width: 80,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text('${r.hourMeter ?? 0}'),
            ),
            TableColumnSpec(
              title: 'ANGGOTA/HADIR',
              width: 150,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) =>
                  Text('${r.jmlhAnggota ?? 0}/${r.hadir ?? 0}'),
            ),
            TableColumnSpec(
              title: 'APPROVED',
              width: 110,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) =>
              (r.approveBy != null && r.approveBy!.isNotEmpty)
                  ? const Icon(Icons.verified, size: 18, color: Colors.green)
                  : const Text('-', style: TextStyle(color: Colors.black54)),
            ),
          ];

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
                    onPressed: () {
                      debugPrint(
                        '🟦 [BROKER_SCREEN] Manual refresh button pressed, VM hash=${vm.hashCode}',
                      );
                      vm.refreshPaged();
                    },
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
                  onAddPressed: _openCreateDialog,
                ),
                Expanded(
                  child: HorizontalPagedTable<BrokerProduction>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) =>
                    r.noProduksi == _selectedNoProduksi,
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

  Future<void> _openCreateDialog() async {
    debugPrint('🟦 [BROKER_SCREEN] Opening create dialog...');
    debugPrint('🟦 [BROKER_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [BROKER_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [BROKER_SCREEN] Building create dialog...');

        // ✅ Share the SAME VM instance using .value
        return ChangeNotifierProvider<BrokerProductionViewModel>.value(
          value: _viewModel,
          child: BrokerProductionFormDialog(
            onSave: (draft) async {
              try {
                if (context.mounted) {
                  // VM already auto-refreshed in createProduksi
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuat label: $e')),
                  );
                }
              }
            },
          ),
        );
      },
    );

    debugPrint('🟦 [BROKER_SCREEN] Dialog closed, result: $created');

    if (!mounted) return;

    if (created == true) {
      debugPrint('🟦 [BROKER_SCREEN] Success detected (create).');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label berhasil dibuat')),
      );
    } else {
      debugPrint('🟦 [BROKER_SCREEN] Result was null or false: $created');
    }
  }

  Future<void> _openEditDialog(
      BuildContext context,
      BrokerProduction row,
      ) async {
    debugPrint('🟦 [BROKER_SCREEN] Opening edit dialog for: ${row.noProduksi}');
    debugPrint('🟦 [BROKER_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [BROKER_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final updated = await showDialog<BrokerProduction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [BROKER_SCREEN] Building edit dialog...');

        // ✅ Share the SAME VM instance
        return ChangeNotifierProvider<BrokerProductionViewModel>.value(
          value: _viewModel,
          child: BrokerProductionFormDialog(
            header: row,
          ),
        );
      },
    );

    debugPrint(
      '🟦 [BROKER_SCREEN] Edit dialog closed, result: ${updated?.noProduksi}',
    );

    if (!mounted) return;

    if (updated != null) {
      debugPrint('🟦 [BROKER_SCREEN] Success detected (update).');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No. Produksi ${updated.noProduksi} berhasil diperbarui',
          ),
        ),
      );
    } else {
      debugPrint('🟦 [BROKER_SCREEN] Result was null');
    }
  }
}