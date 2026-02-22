// lib/features/production/mixer/view/mixer_production_screen.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';

import '../model/mixer_production_model.dart';
import '../view_model/mixer_production_view_model.dart';
import '../widgets/mixer_production_action_bar.dart';
import '../widgets/mixer_production_delete_dialog.dart';
import '../widgets/mixer_production_form_dialog.dart';
import '../widgets/mixer_production_header_table.dart';
import '../widgets/mixer_production_row_popover.dart';
import 'mixer_production_input_screen.dart';

class MixerProductionScreen extends StatefulWidget {
  const MixerProductionScreen({super.key});

  @override
  State<MixerProductionScreen> createState() => _MixerProductionScreenState();
}

class _MixerProductionScreenState extends State<MixerProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  late final MixerProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MixerProductionViewModel();
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
    required MixerProduction row,
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
              child: MixerProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MixerProductionInputScreen(
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
                      return MixerProductionDeleteDialog(
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
                onPrint: () {},
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

  void _navigateToAuditHistory(MixerProduction header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noProduksi),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<MixerProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<MixerProductionViewModel>.value(
        value: _viewModel,
        child: const MixerProductionFormDialog(),
      ),
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

  Future<void> _openEditDialog(BuildContext ctx, MixerProduction row) async {
    final updated = await showDialog<MixerProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<MixerProductionViewModel>.value(
        value: _viewModel,
        child: MixerProductionFormDialog(header: row),
      ),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MixerProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<MixerProductionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mixer Production'),
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
                MixerProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: MixerProductionHeaderTable(
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
}
