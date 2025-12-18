// lib/features/production/gilingan/view/gilingan_production_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';

import '../model/gilingan_production_model.dart';
import '../repository/gilingan_production_repository.dart';
import '../view_model/gilingan_production_view_model.dart';

// Action bar
import '../widgets/gilingan_production_action_bar.dart';
import '../widgets/gilingan_production_delete_dialog.dart';
import '../widgets/gilingan_production_form_dialog.dart';
import '../widgets/gilingan_production_row_popover.dart';

class GilinganProductionScreen extends StatefulWidget {
  const GilinganProductionScreen({super.key});

  @override
  State<GilinganProductionScreen> createState() =>
      _GilinganProductionScreenState();
}

class _GilinganProductionScreenState extends State<GilinganProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _showRowPopover({
    required BuildContext context,
    required GilinganProduction row,
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
        final safeLeft =
        local.dx.clamp(8.0, overlay.size.width - 320.0);
        final safeTop =
        local.dy.clamp(8.0, overlay.size.height - 220.0);

        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop,
              child: GilinganProductionRowPopover(
                row: row,
                // tutup popover pakai context dialog
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  // TODO: kalau nanti ada screen input khusus gilingan, panggil di sini.
                  // Sekarang biarkan kosong.
                },
                onEdit: () async {
                  await _openEditDialog(context, row);
                },
                onDelete: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      return GilinganProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final vm =
                          context.read<GilinganProductionViewModel>();

                          final success =
                          await vm.deleteProduksi(row.noProduksi);

                          // tutup dialog konfirmasi
                          if (ctx.mounted) Navigator.of(ctx).pop();

                          if (!context.mounted) return;

                          if (success) {
                            // dialog sukses
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                'No. Produksi ${row.noProduksi} berhasil dihapus.',
                              ),
                            );
                          } else {
                            final rawMsg = vm.saveError ??
                                'Gagal menghapus data';
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
                  // TODO: kalau nanti ada cetak label gilingan
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
    return ChangeNotifierProvider(
      create: (_) => GilinganProductionViewModel(
        repository: GilinganProductionRepository(),
      )..refreshPaged(), // mulai dengan mode paged
      child: Consumer<GilinganProductionViewModel>(
        builder: (context, vm, _) {
          final columns = <TableColumnSpec<GilinganProduction>>[
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
              cellBuilder: (_, r) =>
                  Text(formatDateToShortId(r.tglProduksi)),
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
            // ⬇️ Tidak ada JamKerja → pakai range HourStart–HourEnd
            TableColumnSpec(
              title: 'JAM',
              width: 140,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text(
                '${r.hourStart ?? '--:--'} - ${r.hourEnd ?? '--:--'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Gilingan Production'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: vm.refreshPaged,
                ),
              ],
            ),
            body: Column(
              children: [
                // 🔹 ACTION BAR (search + create)
                GilinganProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) =>
                      vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,
                ),

                // 🔹 TABLE PAGED
                Expanded(
                  child: HorizontalPagedTable<GilinganProduction>(
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
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GilinganProductionFormDialog(),
    );

    if (!mounted) return;

    if (created == true) {
      // refresh list paged
      final vm = context.read<GilinganProductionViewModel>();
      vm.refreshPaged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produksi gilingan berhasil dibuat'),
        ),
      );
    }
  }

  Future<void> _openEditDialog(
      BuildContext context,
      GilinganProduction row,
      ) async {
    final updated = await showDialog<GilinganProduction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GilinganProductionFormDialog(
        header: row,
      ),
    );

    if (!mounted) return;

    if (updated != null) {
      // refresh paged list
      final vm = context.read<GilinganProductionViewModel>();
      vm.refreshPaged();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No. Produksi ${updated.noProduksi} berhasil diperbarui',
          ),
        ),
      );
    }
  }
}
