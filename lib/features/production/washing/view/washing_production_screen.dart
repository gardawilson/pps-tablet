// lib/features/production/washing/view/washing_production_screen.dart
import 'package:flutter/material.dart';
import 'package:pps_tablet/features/production/washing/view/washing_production_input_screen.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';

// VM + Repo + Model washing
import '../view_model/washing_production_view_model.dart';
import '../repository/washing_production_repository.dart';
import '../model/washing_production_model.dart';

// Action bar & form dialog washing
import '../widgets/washing_delete_dialog.dart';
import '../widgets/washing_production_action_bar.dart';
import '../widgets/washing_production_form_dialog.dart';
import '../widgets/washing_production_row_popover.dart';



class WashingProductionScreen extends StatefulWidget {
  const WashingProductionScreen({super.key});

  @override
  State<WashingProductionScreen> createState() =>
      _WashingProductionScreenState();
}

class _WashingProductionScreenState extends State<WashingProductionScreen> {
  final _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  // =========================================================
  //  POPOVER (format sama dengan BrokerProductionScreen)
  // =========================================================
  Future<void> _showRowPopover({
    required BuildContext context,
    required WashingProduction row,
    required Offset globalPos,
  }) async {
    final overlayBox =
    Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    // konversi global → lokal terhadap overlay
    final local = overlayBox.globalToLocal(globalPos);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        final safeLeft =
        local.dx.clamp(8.0, overlayBox.size.width - 320.0); // max width popover
        final safeTop =
        local.dy.clamp(8.0, overlayBox.size.height - 220.0); // max height popover

        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop,
              child: WashingProductionRowPopover(
                row: row,
                // CLOSE popover pakai dialogCtx (bukan context screen)
                onClose: () => Navigator.of(dialogCtx).pop(),

                // ⬇️ Saat ini modul washing belum punya screen input detail
                onInput: () {
                  // popover sudah tertutup oleh _runAndClose di dalam popover
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WashingProductionInputScreen(
                          noProduksi: row.noProduksi,
                        ),
                      ),
                    );
                  });
                },

                // ⬇️ Edit: sementara tampilkan info belum tersedia
                onEdit: () async {
                  await _openEditDialog(context, row);
                  // gak perlu maybePop di sini, popover sudah di-close lewat onClose
                },

                // ⬇️ Delete header
                onDelete: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      return WashingProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final vm = context.read<WashingProductionViewModel>();

                          final success = await vm.deleteProduksi(row.noProduksi);

                          // 1) Tutup dialog konfirmasi
                          if (ctx.mounted) Navigator.of(ctx).pop();

                          if (!context.mounted) return;

                          // 2) JANGAN pop lagi di sini — popover sudah ditutup oleh onClose()

                          if (success) {
                            // ✅ dialog sukses
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message: 'No. Produksi ${row.noProduksi} berhasil dihapus.',
                              ),
                            );
                          } else {
                            final rawMsg = vm.saveError ?? 'Gagal menghapus data';

                            // ❌ dialog error
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

                // ⬇️ Print: placeholder
                onPrint: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text('Fitur print Washing belum tersedia untuk saat ini.'),
                      duration: Duration(milliseconds: 1200),
                    ),
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
    return ChangeNotifierProvider(
      create: (_) => WashingProductionViewModel(
        repository: WashingProductionRepository(),
      )..refreshPaged(),
      child: Consumer<WashingProductionViewModel>(
        builder: (context, vm, _) {
          final columns = <TableColumnSpec<WashingProduction>>[
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
            TableColumnSpec(
              title: 'JAM',
              width: 70,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text('${r.jamKerja}'),
            ),
            TableColumnSpec(
              title: 'HM',
              width: 80,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text('${r.hourMeter}'),
            ),
            TableColumnSpec(
              title: 'ANGGOTA/HADIR',
              width: 150,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) =>
                  Text('${r.jmlhAnggota}/${r.hadir}'),
            ),
            TableColumnSpec(
              title: 'APPROVED',
              width: 110,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) =>
              (r.approveBy != null && r.approveBy!.isNotEmpty)
                  ? const Icon(Icons.verified,
                  size: 18, color: Colors.green)
                  : const Text(
                '-',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Washing Production'),
              actions: [
                if (vm.isByDateMode)
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    onPressed: vm.exitByDateModeAndRefreshPaged,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: vm.refreshPaged,
                  ),
              ],
            ),
            body: Column(
              children: [
                // 🔹 ACTION BAR (search + create) — mirip BrokerProductionActionBar
                WashingProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,
                ),

                // 🔹 TABLE
                Expanded(
                  child: HorizontalPagedTable<WashingProduction>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) =>
                    r.noProduksi == _selectedNoProduksi,
                    onRowTap: (r) =>
                        setState(() => _selectedNoProduksi = r.noProduksi),

                    // format sama dengan broker: long-press + posisi global
                    onRowLongPress: (row, globalPos) async {
                      await _showRowPopover(
                        context: context,
                        row: row,
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

  // =========================================================
  //  DIALOG CREATE (format mirip broker, tapi simple)
  // =========================================================
  Future<void> _openCreateDialog() async {
    // VM sebenarnya dipakai di dalam dialog via Provider,
    // jadi di sini kita hanya terima hasilnya saja.
    final created = await showDialog<WashingProduction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WashingProductionFormDialog(
        header: null, // mode create
        onSave: (saved) {
          // kembalikan ke caller
          Navigator.of(ctx).pop(saved);
        },
      ),
    );

    if (!mounted) return;

    if (created != null) {
      setState(() {
        _selectedNoProduksi = created.noProduksi;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Washing No. Produksi ${created.noProduksi} berhasil dibuat'),
        ),
      );
    }
  }

  // =========================================================
  //  DIALOG EDIT (kalau nanti sudah ada endpoint update)
  // =========================================================
  Future<void> _openEditDialog(BuildContext context, WashingProduction row) async {
    final vm = context.read<WashingProductionViewModel>();

    // Open the form in EDIT mode by passing `header: row`
    final updated = await showDialog<WashingProduction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WashingProductionFormDialog(
        header: row, // ← send current values here
        onSave: (v) {
          // return the saved/updated item to this screen
          Navigator.of(ctx).pop(v);
        },
      ),
    );

    if (!mounted) return;

    if (updated != null) {
      // (Optional) Give feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No. Produksi ${updated.noProduksi} berhasil diperbarui')),
      );
    }
  }
}
