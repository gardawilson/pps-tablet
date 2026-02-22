import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:pps_tablet/features/production/sortir_reject/view/sortir_reject_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../model/sortir_reject_production_model.dart';
import '../view_model/sortir_reject_production_view_model.dart';
import '../widgets/sortir_reject_production_action_bar.dart';
import '../widgets/sortir_reject_production_delete_dialog.dart';
import '../widgets/sortir_reject_production_form_dialog.dart';
import '../widgets/sortir_reject_production_header_table.dart';
import '../widgets/sortir_reject_production_row_popover.dart';

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
                          final success = await _viewModel.deleteSortirReject(
                            row.noBJSortir,
                          );

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

  void _navigateToAuditHistory(SortirRejectProduction header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noBJSortir),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<SortirRejectProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) =>
          ChangeNotifierProvider<SortirRejectProductionViewModel>.value(
            value: _viewModel,
            child: const SortirRejectProductionFormDialog(),
          ),
    );
    if (!mounted || !ctx.mounted) return;
    if (created != null) {
      _viewModel.refreshPaged();
      setState(() => _selectedNoBJSortir = created.noBJSortir);
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message: 'No. BJ Sortir ${created.noBJSortir} berhasil dibuat.',
        ),
      );
    }
  }

  Future<void> _openEditDialog(
    BuildContext ctx,
    SortirRejectProduction row,
  ) async {
    final updated = await showDialog<SortirRejectProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) =>
          ChangeNotifierProvider<SortirRejectProductionViewModel>.value(
            value: _viewModel,
            child: SortirRejectProductionFormDialog(header: row),
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
              'No. BJ Sortir ${updated.noBJSortir} berhasil diperbarui.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SortirRejectProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<SortirRejectProductionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Sortir Reject'),
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
                SortirRejectProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: SortirRejectProductionHeaderTable(
                    selectedNoBJSortir: _selectedNoBJSortir,
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
}
