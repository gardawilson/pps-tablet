// lib/features/production/hot_stamp/view/hot_stamp_production_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';

import '../model/hot_stamp_production_model.dart';
import '../view_model/hot_stamp_production_view_model.dart';
import '../widgets/hot_stamp_production_action_bar.dart';
import '../widgets/hot_stamp_production_delete_dialog.dart';
import '../widgets/hot_stamp_production_form_dialog.dart';
import '../widgets/hot_stamp_production_row_popover.dart';
import 'hot_stamp_production_input_screen.dart';

class HotStampProductionScreen extends StatefulWidget {
  const HotStampProductionScreen({super.key});

  @override
  State<HotStampProductionScreen> createState() =>
      _HotStampProductionScreenState();
}

class _HotStampProductionScreenState extends State<HotStampProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  // ✅ Store VM instance as field
  late final HotStampProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    // ✅ Create VM once in initState
    _viewModel = HotStampProductionViewModel();

    debugPrint(
      '🟦🟦🟦 [HOTSTAMP_SCREEN] initState: Created VM hash=${_viewModel.hashCode}',
    );
    debugPrint(
      '🟦🟦🟦 [HOTSTAMP_SCREEN] initState: PagingController hash=${_viewModel.pagingController.hashCode}',
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
    required HotStampProduction row,
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
              child: HotStampProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HotStampingProductionInputScreen(
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
                      return HotStampProductionDeleteDialog(
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
                onPrint: () {
                  // TODO: kalau nanti ada cetak label hot stamp
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
    return ChangeNotifierProvider<HotStampProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<HotStampProductionViewModel>(
        builder: (context, vm, _) {
          debugPrint(
            '🟦 [HOTSTAMP_SCREEN] Consumer.builder() called, VM hash=${vm.hashCode}',
          );
          debugPrint(
            '🟦 [HOTSTAMP_SCREEN] Consumer pagingController: hash=${vm.pagingController.hashCode}',
          );

          final columns = <TableColumnSpec<HotStampProduction>>[
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
              title: 'JAM KERJA',
              width: 100,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text(
                '${r.jamKerja ?? 0} jam',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'JAM',
              width: 140,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text(
                r.hourRangeText.isNotEmpty ? r.hourRangeText : '--:-- - --:--',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'HM',
              width: 130,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text('${r.hourMeter ?? 0}'),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Hot Stamp Production'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    debugPrint(
                      '🟦 [HOTSTAMP_SCREEN] Manual refresh button pressed, VM hash=${vm.hashCode}',
                    );
                    vm.refreshPaged();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                HotStampProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,
                ),
                Expanded(
                  child: HorizontalPagedTable<HotStampProduction>(
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
    debugPrint('🟦 [HOTSTAMP_SCREEN] Opening create dialog...');
    debugPrint('🟦 [HOTSTAMP_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [HOTSTAMP_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [HOTSTAMP_SCREEN] Building create dialog...');

        // ✅ Share the SAME VM instance using .value
        return ChangeNotifierProvider<HotStampProductionViewModel>.value(
          value: _viewModel,
          child: const HotStampProductionFormDialog(),
        );
      },
    );

    debugPrint('🟦 [HOTSTAMP_SCREEN] Dialog closed, result: $created');

    if (!mounted) return;

    if (created == true) {
      debugPrint('🟦 [HOTSTAMP_SCREEN] Success detected (create).');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produksi hot stamp berhasil dibuat'),
        ),
      );
    } else {
      debugPrint('🟦 [HOTSTAMP_SCREEN] Result was null or false: $created');
    }
  }

  Future<void> _openEditDialog(
      BuildContext context,
      HotStampProduction row,
      ) async {
    debugPrint(
        '🟦 [HOTSTAMP_SCREEN] Opening edit dialog for: ${row.noProduksi}');
    debugPrint('🟦 [HOTSTAMP_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [HOTSTAMP_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final updated = await showDialog<HotStampProduction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [HOTSTAMP_SCREEN] Building edit dialog...');

        // ✅ Share the SAME VM instance
        return ChangeNotifierProvider<HotStampProductionViewModel>.value(
          value: _viewModel,
          child: HotStampProductionFormDialog(
            header: row,
          ),
        );
      },
    );

    debugPrint(
      '🟦 [HOTSTAMP_SCREEN] Edit dialog closed, result: ${updated?.noProduksi}',
    );

    if (!mounted) return;

    if (updated != null) {
      debugPrint('🟦 [HOTSTAMP_SCREEN] Success detected (update).');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No. Produksi ${updated.noProduksi} berhasil diperbarui',
          ),
        ),
      );
    } else {
      debugPrint('🟦 [HOTSTAMP_SCREEN] Result was null');
    }
  }
}
