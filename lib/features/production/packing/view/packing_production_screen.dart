// lib/features/production/packing/view/packing_production_screen.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/features/production/packing/view/packing_production_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';

// ✅ adjust these imports to your packing folder structure
import '../model/packing_production_model.dart';
import '../view_model/packing_production_view_model.dart';

import '../widgets/packing_production_action_bar.dart';
import '../widgets/packing_production_delete_dialog.dart';
import '../widgets/packing_production_form_dialog.dart';
import '../widgets/packing_production_row_popover.dart';

class PackingProductionScreen extends StatefulWidget {
  const PackingProductionScreen({super.key});

  @override
  State<PackingProductionScreen> createState() => _PackingProductionScreenState();
}

class _PackingProductionScreenState extends State<PackingProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoPacking;

  // ✅ Store VM instance as field
  late final PackingProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    // ✅ Create VM once in initState
    _viewModel = PackingProductionViewModel();

    debugPrint(
      '🟩🟩🟩 [PACKING_SCREEN] initState: Created VM hash=${_viewModel.hashCode}',
    );
    debugPrint(
      '🟩🟩🟩 [PACKING_SCREEN] initState: PagingController hash=${_viewModel.pagingController.hashCode}',
    );

    // Initialize first load
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
                          final success =
                          await _viewModel.deleteProduksi(row.noPacking);

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
                  // TODO: kalau nanti ada cetak / print packing
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
    return ChangeNotifierProvider<PackingProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<PackingProductionViewModel>(
        builder: (context, vm, _) {
          debugPrint(
            '🟩 [PACKING_SCREEN] Consumer.builder() called, VM hash=${vm.hashCode}',
          );
          debugPrint(
            '🟩 [PACKING_SCREEN] Consumer pagingController: hash=${vm.pagingController.hashCode}',
          );

          final columns = <TableColumnSpec<PackingProduction>>[
            TableColumnSpec(
              title: 'NO. PACKING',
              width: 160,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.noPacking,
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
              title: const Text('Packing'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    debugPrint(
                      '🟩 [PACKING_SCREEN] Manual refresh pressed, VM hash=${vm.hashCode}',
                    );
                    vm.refreshPaged();
                  },
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
                  onAddPressed: _openCreateDialog,
                ),
                Expanded(
                  child: HorizontalPagedTable<PackingProduction>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) => r.noPacking == _selectedNoPacking,
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

  Future<void> _openCreateDialog() async {
    debugPrint('🟩 [PACKING_SCREEN] Opening create dialog...');
    debugPrint('🟩 [PACKING_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟩 [PACKING_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟩 [PACKING_SCREEN] Building create dialog...');

        return ChangeNotifierProvider<PackingProductionViewModel>.value(
          value: _viewModel,
          child: const PackingProductionFormDialog(),
        );
      },
    );

    debugPrint('🟩 [PACKING_SCREEN] Dialog closed, result: $created');

    if (!mounted) return;

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produksi packing berhasil dibuat'),
        ),
      );
    }
  }

  Future<void> _openEditDialog(
      BuildContext context,
      PackingProduction row,
      ) async {
    debugPrint('🟩 [PACKING_SCREEN] Opening edit dialog: ${row.noPacking}');
    debugPrint('🟩 [PACKING_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟩 [PACKING_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final updated = await showDialog<PackingProduction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟩 [PACKING_SCREEN] Building edit dialog...');

        return ChangeNotifierProvider<PackingProductionViewModel>.value(
          value: _viewModel,
          child: PackingProductionFormDialog(header: row),
        );
      },
    );

    debugPrint(
      '🟩 [PACKING_SCREEN] Edit dialog closed: ${updated?.noPacking}',
    );

    if (!mounted) return;

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No. Packing ${updated.noPacking} berhasil diperbarui'),
        ),
      );
    }
  }
}
