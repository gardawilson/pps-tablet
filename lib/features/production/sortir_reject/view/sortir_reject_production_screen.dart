import 'package:flutter/material.dart';
import 'package:pps_tablet/features/production/sortir_reject/view/sortir_reject_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/sortir_reject_production_model.dart';
import '../view_model/sortir_reject_production_view_model.dart';
import '../widgets/sortir_reject_production_action_bar.dart';
import '../widgets/sortir_reject_production_delete_dialog.dart';
import '../widgets/sortir_reject_production_form_dialog.dart';
import '../widgets/sortir_reject_production_row_popover.dart';


// TODO: ganti ke input screen sortir reject kamu
// import 'sortir_reject_production_input_screen.dart';

class SortirRejectProductionScreen extends StatefulWidget {
  const SortirRejectProductionScreen({super.key});

  @override
  State<SortirRejectProductionScreen> createState() =>
      _SortirRejectProductionScreenState();
}

class _SortirRejectProductionScreenState
    extends State<SortirRejectProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoBJSortir;

  late final SortirRejectProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = SortirRejectProductionViewModel();

    debugPrint(
      '🟩🟩🟩 [SORTIR_REJECT_SCREEN] initState: Created VM hash=${_viewModel.hashCode}',
    );
    debugPrint(
      '🟩🟩🟩 [SORTIR_REJECT_SCREEN] initState: PagingController hash=${_viewModel.pagingController.hashCode}',
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
    required SortirRejectProduction row,
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
              child: SortirRejectProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),

                onInput: () {
                  // TODO: arahkan ke input screen sortir reject kalau sudah ada
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SortirRejectInputScreen(
                          noBJSortir: row.noBJSortir,
                          isLocked: row.isLocked,
                          lastClosedDate: row.lastClosedDate,
                        ),
                      ),
                    );
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('TODO: Open input screen')),
                  );
                },

                onEdit: () async {
                  await _openEditDialog(context, row);
                },

                onDelete: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      return SortirRejectProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success =
                          await _viewModel.deleteSortirReject(row.noBJSortir);

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                'No. BJ Sortir ${row.noBJSortir} berhasil dihapus.',
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
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SortirRejectProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<SortirRejectProductionViewModel>(
        builder: (context, vm, _) {
          debugPrint(
            '🟩 [SORTIR_REJECT_SCREEN] Consumer.builder() called, VM hash=${vm.hashCode}',
          );
          debugPrint(
            '🟩 [SORTIR_REJECT_SCREEN] Consumer pagingController: hash=${vm.pagingController.hashCode}',
          );

          final columns = <TableColumnSpec<SortirRejectProduction>>[
            TableColumnSpec(
              title: 'NO. BJ SORTIR',
              width: 170,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.noBJSortir,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'TANGGAL',
              width: 130,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(formatDateToShortId(r.tanggal)),
            ),
            TableColumnSpec(
              title: 'WAREHOUSE',
              width: 140,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.idWarehouse != null ? 'WH ${r.idWarehouse}' : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'USER',
              width: 160,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.username.isNotEmpty ? r.username : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'STATUS',
              width: 110,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text(
                r.isLocked ? 'LOCKED' : 'OPEN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Sortir Reject'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    debugPrint(
                      '🟩 [SORTIR_REJECT_SCREEN] Manual refresh pressed, VM hash=${vm.hashCode}',
                    );
                    vm.refreshPaged();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                SortirRejectProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,
                ),
                Expanded(
                  child: HorizontalPagedTable<SortirRejectProduction>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) => r.noBJSortir == _selectedNoBJSortir,
                    onRowTap: (r) =>
                        setState(() => _selectedNoBJSortir = r.noBJSortir),
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
    debugPrint('🟩 [SORTIR_REJECT_SCREEN] Opening create dialog...');
    debugPrint('🟩 [SORTIR_REJECT_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟩 [SORTIR_REJECT_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final created = await showDialog<SortirRejectProduction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟩 [SORTIR_REJECT_SCREEN] Building create dialog...');
        return ChangeNotifierProvider<SortirRejectProductionViewModel>.value(
          value: _viewModel,
          child: const SortirRejectProductionFormDialog(),
        );
      },
    );

    debugPrint('🟩 [SORTIR_REJECT_SCREEN] Dialog closed, result: $created');

    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Sortir Reject ${created.noBJSortir} berhasil dibuat'),
        ),
      );
    }
  }

  Future<void> _openEditDialog(
      BuildContext context,
      SortirRejectProduction row,
      ) async {
    debugPrint('🟩 [SORTIR_REJECT_SCREEN] Opening edit dialog: ${row.noBJSortir}');
    debugPrint('🟩 [SORTIR_REJECT_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟩 [SORTIR_REJECT_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final updated = await showDialog<SortirRejectProduction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟩 [SORTIR_REJECT_SCREEN] Building edit dialog...');
        return ChangeNotifierProvider<SortirRejectProductionViewModel>.value(
          value: _viewModel,
          child: SortirRejectProductionFormDialog(header: row),
        );
      },
    );

    debugPrint(
      '🟩 [SORTIR_REJECT_SCREEN] Edit dialog closed: ${updated?.noBJSortir}',
    );

    if (!mounted) return;

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No. BJ Sortir ${updated.noBJSortir} berhasil diperbarui'),
        ),
      );
    }
  }
}
