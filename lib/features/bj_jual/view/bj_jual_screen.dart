import 'package:flutter/material.dart';
import 'package:pps_tablet/features/bj_jual/view/bj_jual_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';

import '../model/bj_jual_model.dart';
import '../view_model/bj_jual_view_model.dart';

import '../widgets/bj_jual_action_bar.dart';
import '../widgets/bj_jual_delete_dialog.dart';
import '../widgets/bj_jual_form_dialog.dart';
import '../widgets/bj_jual_row_popover.dart';

class BJJualScreen extends StatefulWidget {
  const BJJualScreen({super.key});

  @override
  State<BJJualScreen> createState() => _BJJualScreenState();
}

class _BJJualScreenState extends State<BJJualScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNo;

  // ✅ Store VM instance as field
  late final BJJualViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    // ✅ Create VM once in initState
    _viewModel = BJJualViewModel();

    debugPrint('🟦🟦🟦 [BJ_JUAL_SCREEN] initState: VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦🟦🟦 [BJ_JUAL_SCREEN] initState: PagingController hash=${_viewModel.pagingController.hashCode}',
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
    required BJJual row,
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
              child: BJJualRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),

                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BJJualInputScreen(
                          noBJJual: row.noBJJual,
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
                      return BJJualDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success =
                          await _viewModel.deleteBJJual(row.noBJJual);

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                'No. BJ Jual ${row.noBJJual} berhasil dihapus.',
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
    return ChangeNotifierProvider<BJJualViewModel>.value(
      value: _viewModel,
      child: Consumer<BJJualViewModel>(
        builder: (context, vm, _) {
          debugPrint(
            '🟦 [BJ_JUAL_SCREEN] Consumer.builder() called, VM hash=${vm.hashCode}',
          );
          debugPrint(
            '🟦 [BJ_JUAL_SCREEN] Consumer pagingController: hash=${vm.pagingController.hashCode}',
          );

          final columns = <TableColumnSpec<BJJual>>[
            TableColumnSpec(
              title: 'NO. BJ JUAL',
              width: 170,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.noBJJual,
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
              title: 'PEMBELI',
              width: 260,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.namaPembeli,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'REMARK',
              width: 300,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                (r.remark?.trim().isNotEmpty ?? false) ? r.remark!.trim() : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('BJ Jual'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    debugPrint(
                      '🟦 [BJ_JUAL_SCREEN] Manual refresh pressed, VM hash=${vm.hashCode}',
                    );
                    vm.refreshPaged();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                BJJualActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,
                ),
                Expanded(
                  child: HorizontalPagedTable<BJJual>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) => r.noBJJual == _selectedNo,
                    onRowTap: (r) => setState(() => _selectedNo = r.noBJJual),
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
    debugPrint('🟦 [BJ_JUAL_SCREEN] Opening create dialog...');
    debugPrint('🟦 [BJ_JUAL_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [BJ_JUAL_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [BJ_JUAL_SCREEN] Building create dialog...');

        return ChangeNotifierProvider<BJJualViewModel>.value(
          value: _viewModel,
          child: const BJJualFormDialog(),
        );
      },
    );

    debugPrint('🟦 [BJ_JUAL_SCREEN] Dialog closed, result: $created');

    if (!mounted) return;

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('BJ Jual berhasil dibuat'),
        ),
      );
    }
  }

  Future<void> _openEditDialog(BuildContext context, BJJual row) async {
    debugPrint('🟦 [BJ_JUAL_SCREEN] Opening edit dialog: ${row.noBJJual}');
    debugPrint('🟦 [BJ_JUAL_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [BJ_JUAL_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final updated = await showDialog<BJJual>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [BJ_JUAL_SCREEN] Building edit dialog...');

        return ChangeNotifierProvider<BJJualViewModel>.value(
          value: _viewModel,
          child: BJJualFormDialog(header: row),
        );
      },
    );

    debugPrint('🟦 [BJ_JUAL_SCREEN] Edit dialog closed: ${updated?.noBJJual}');

    if (!mounted) return;

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No. BJ Jual ${updated.noBJJual} berhasil diperbarui'),
        ),
      );
    }
  }
}
