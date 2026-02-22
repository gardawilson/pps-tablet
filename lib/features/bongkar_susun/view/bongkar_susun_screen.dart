// lib/features/shared/bongkar_susun/view/bongkar_susun_screen.dart
import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:pps_tablet/features/bongkar_susun/view/bongkar_susun_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';

import '../model/bongkar_susun_model.dart';
import '../view_model/bongkar_susun_view_model.dart';
import '../widgets/bongkar_susun_action_bar.dart';
import '../widgets/bongkar_susun_delete_dialog.dart';
import '../widgets/bongkar_susun_form_dialog.dart';
import '../widgets/bongkar_susun_header_table.dart';
import '../widgets/bongkar_susun_row_popover.dart';

class BongkarSusunScreen extends StatefulWidget {
  const BongkarSusunScreen({super.key});

  @override
  State<BongkarSusunScreen> createState() => _BongkarSusunScreenState();
}

class _BongkarSusunScreenState extends State<BongkarSusunScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoBongkarSusun;

  late final BongkarSusunViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BongkarSusunViewModel();
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
    required BongkarSusun row,
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
              child: BongkarSusunRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BongkarSusunInputScreen(
                          noBongkarSusun: row.noBongkarSusun,
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
                      return BongkarSusunDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success = await _viewModel.deleteBongkarSusun(
                            row.noBongkarSusun,
                          );

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                    'No. Bongkar/Susun ${row.noBongkarSusun} berhasil dihapus.',
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

  void _navigateToAuditHistory(BongkarSusun header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noBongkarSusun),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<BongkarSusun>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<BongkarSusunViewModel>.value(
        value: _viewModel,
        child: const BongkarSusunFormDialog(),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (created != null) {
      _viewModel.refreshPaged();
      setState(() => _selectedNoBongkarSusun = created.noBongkarSusun);
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message:
              'No. Bongkar/Susun ${created.noBongkarSusun} berhasil dibuat.',
        ),
      );
    }
  }

  Future<void> _openEditDialog(
    BuildContext ctx,
    BongkarSusun row,
  ) async {
    final updated = await showDialog<BongkarSusun>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<BongkarSusunViewModel>.value(
        value: _viewModel,
        child: BongkarSusunFormDialog(header: row),
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
              'No. Bongkar/Susun ${updated.noBongkarSusun} berhasil diperbarui.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BongkarSusunViewModel>.value(
      value: _viewModel,
      child: Consumer<BongkarSusunViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Bongkar Susun'),
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
                BongkarSusunActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: BongkarSusunHeaderTable(
                    selectedNoBongkarSusun: _selectedNoBongkarSusun,
                    onRowTap: (r) => setState(
                      () => _selectedNoBongkarSusun = r.noBongkarSusun,
                    ),
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
