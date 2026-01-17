// lib/features/shared/return_production/view/return_production_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';

import '../model/return_production_model.dart';
import '../view_model/return_production_view_model.dart';

// ✅ create these widgets similar to sortir reject
import '../widgets/return_production_action_bar.dart';
import '../widgets/return_production_delete_dialog.dart';
import '../widgets/return_production_form_dialog.dart';
import '../widgets/return_production_row_popover.dart';



class ReturnProductionScreen extends StatefulWidget {
  const ReturnProductionScreen({super.key});

  @override
  State<ReturnProductionScreen> createState() => _ReturnProductionScreenState();
}

class _ReturnProductionScreenState extends State<ReturnProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoRetur;

  late final ReturnProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = ReturnProductionViewModel();

    debugPrint(
      '🟩🟩🟩 [RETURN_SCREEN] initState: Created VM hash=${_viewModel.hashCode}',
    );
    debugPrint(
      '🟩🟩🟩 [RETURN_SCREEN] initState: PagingController hash=${_viewModel.pagingController.hashCode}',
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
    required ReturnProduction row,
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
              child: ReturnProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),

                onEdit: () async {
                  await _openEditDialog(context, row);
                },

                onDelete: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      return ReturnProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success =
                          await _viewModel.deleteReturn(row.noRetur);

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                'No. Retur ${row.noRetur} berhasil dihapus.',
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
    return ChangeNotifierProvider<ReturnProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<ReturnProductionViewModel>(
        builder: (context, vm, _) {
          debugPrint(
            '🟩 [RETURN_SCREEN] Consumer.builder() called, VM hash=${vm.hashCode}',
          );
          debugPrint(
            '🟩 [RETURN_SCREEN] Consumer pagingController: hash=${vm.pagingController.hashCode}',
          );

          final columns = <TableColumnSpec<ReturnProduction>>[
            TableColumnSpec(
              title: 'NO. RETUR',
              width: 160,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.noRetur,
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
              title: 'INVOICE',
              width: 160,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                (r.invoice).trim().isNotEmpty ? r.invoice.trim() : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'PEMBELI',
              width: 220,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.namaPembeli.isNotEmpty ? r.namaPembeli : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'NO. BJ SORTIR',
              width: 170,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                (r.noBJSortir).trim().isNotEmpty ? r.noBJSortir.trim() : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Return'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    debugPrint(
                      '🟩 [RETURN_SCREEN] Manual refresh pressed, VM hash=${vm.hashCode}',
                    );
                    vm.refreshPaged();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                ReturnProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,
                ),
                Expanded(
                  child: HorizontalPagedTable<ReturnProduction>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) => r.noRetur == _selectedNoRetur,
                    onRowTap: (r) => setState(() => _selectedNoRetur = r.noRetur),
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
    debugPrint('🟩 [RETURN_SCREEN] Opening create dialog...');
    debugPrint('🟩 [RETURN_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟩 [RETURN_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final created = await showDialog<ReturnProduction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟩 [RETURN_SCREEN] Building create dialog...');
        return ChangeNotifierProvider<ReturnProductionViewModel>.value(
          value: _viewModel,
          child: const ReturnProductionFormDialog(),
        );
      },
    );

    debugPrint('🟩 [RETURN_SCREEN] Dialog closed, result: $created');

    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Return ${created.noRetur} berhasil dibuat'),
        ),
      );
    }
  }

  Future<void> _openEditDialog(
      BuildContext context,
      ReturnProduction row,
      ) async {
    debugPrint('🟩 [RETURN_SCREEN] Opening edit dialog: ${row.noRetur}');
    debugPrint('🟩 [RETURN_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟩 [RETURN_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final updated = await showDialog<ReturnProduction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟩 [RETURN_SCREEN] Building edit dialog...');
        return ChangeNotifierProvider<ReturnProductionViewModel>.value(
          value: _viewModel,
          child: ReturnProductionFormDialog(header: row),
        );
      },
    );

    debugPrint(
      '🟩 [RETURN_SCREEN] Edit dialog closed: ${updated?.noRetur}',
    );

    if (!mounted) return;

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No. Retur ${updated.noRetur} berhasil diperbarui'),
        ),
      );
    }
  }
}
