import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:pps_tablet/features/bj_jual/view/bj_jual_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';

import '../model/bj_jual_model.dart';
import '../view_model/bj_jual_view_model.dart';

import '../widgets/bj_jual_action_bar.dart';
import '../widgets/bj_jual_delete_dialog.dart';
import '../widgets/bj_jual_form_dialog.dart';
import '../widgets/bj_jual_header_table.dart';
import '../widgets/bj_jual_row_popover.dart';

class BJJualScreen extends StatefulWidget {
  const BJJualScreen({super.key});

  @override
  State<BJJualScreen> createState() => _BJJualScreenState();
}

class _BJJualScreenState extends State<BJJualScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoBJJual;

  late final BJJualViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BJJualViewModel();
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
                          final success = await _viewModel.deleteBJJual(
                            row.noBJJual,
                          );

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

  void _navigateToAuditHistory(BJJual header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noBJJual),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<BJJual>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<BJJualViewModel>.value(
        value: _viewModel,
        child: const BJJualFormDialog(),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (created != null) {
      _viewModel.refreshPaged();
      setState(() => _selectedNoBJJual = created.noBJJual);
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message: 'No. BJ Jual ${created.noBJJual} berhasil dibuat.',
        ),
      );
    }
  }

  Future<void> _openEditDialog(BuildContext ctx, BJJual row) async {
    final updated = await showDialog<BJJual>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<BJJualViewModel>.value(
        value: _viewModel,
        child: BJJualFormDialog(header: row),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (updated != null) {
      _viewModel.refreshPaged();
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Mengupdate',
          message: 'No. BJ Jual ${updated.noBJJual} berhasil diperbarui.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BJJualViewModel>.value(
      value: _viewModel,
      child: Consumer<BJJualViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('BJ Jual'),
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
                BJJualActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: BJJualHeaderTable(
                    selectedNoBJJual: _selectedNoBJJual,
                    onRowTap: (r) =>
                        setState(() => _selectedNoBJJual = r.noBJJual),
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
