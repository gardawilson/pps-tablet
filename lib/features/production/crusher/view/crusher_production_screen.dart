// lib/features/production/crusher/view/crusher_production_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../view_model/crusher_production_view_model.dart';
import '../repository/crusher_production_repository.dart';
import '../model/crusher_production_model.dart';
import '../../../../core/utils/date_formatter.dart';
import '../widgets/broker_delete_dialog.dart';
import '../widgets/crusher_production_action_bar.dart';
import '../widgets/crusher_production_form_dialog.dart';
import '../widgets/crusher_production_row_popover.dart';
import 'crusher_production_input_screen.dart';

// Action bar
// import '../widgets/reject_delete_dialog.dart';
// import '../widgets/crusher_production_action_bar.dart';
// Inputs screen (Scan action)
// import '../widgets/crusher_production_form_dialog.dart';
// import 'crusher_production_input_screen.dart';
// ⬇️ New: the popover panel
// import '../widgets/crusher_production_row_popover.dart';

class CrusherProductionScreen extends StatefulWidget {
  const CrusherProductionScreen({super.key});

  @override
  State<CrusherProductionScreen> createState() => _CrusherProductionScreenState();
}

class _CrusherProductionScreenState extends State<CrusherProductionScreen> {
  final _searchCtl = TextEditingController();
  String? _selectedNoCrusherProduksi;

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _showRowPopover({
    required BuildContext context,
    required CrusherProduction row,
    required Offset globalPos,
  }) async {
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final local = overlay.globalToLocal(globalPos);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (dialogCtx) { // ⬅️ pakai dialogCtx
        final safeLeft = local.dx.clamp(8.0, overlay.size.width - 320.0);
        final safeTop  = local.dy.clamp(8.0, overlay.size.height - 220.0);

        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop,
              child: CrusherProductionRowPopover(
                row: row,
                // ⬅️ CLOSE popover dengan context dialog, bukan context screen
                onClose: () => Navigator.of(dialogCtx).pop(),

                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CrusherProductionInputScreen(
                          noCrusherProduksi: row.noCrusherProduksi,
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
                      return CrusherProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final vm = context.read<CrusherProductionViewModel>();

                          final success = await vm.deleteProduksi(row.noCrusherProduksi);

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
                                message: 'No. Crusher Produksi ${row.noCrusherProduksi} berhasil dihapus.',
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

                onPrint: () async {
                  // optional
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
      create: (_) => CrusherProductionViewModel(
        repository: CrusherProductionRepository(),
      )..refreshPaged(),
      child: Consumer<CrusherProductionViewModel>(
        builder: (context, vm, _) {
          final columns = <TableColumnSpec<CrusherProduction>>[
            TableColumnSpec(
              title: 'NO. PRODUKSI',
              width: 180,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.noCrusherProduksi,
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
              width: 90,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text('${r.jamKerja}'),
            ),
            // TableColumnSpec(
            //   title: 'WAKTU',
            //   width: 130,
            //   headerAlign: TextAlign.center,
            //   cellAlign: TextAlign.center,
            //   cellBuilder: (_, r) => Text(
            //     r.hourRangeText.isEmpty ? '-' : r.hourRangeText,
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: r.hourRangeText.isEmpty ? Colors.black45 : Colors.black87,
            //     ),
            //   ),
            // ),
            TableColumnSpec(
              title: 'HM',
              width: 80,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text(
                r.hourMeter != null ? '${r.hourMeter}' : '0',
              ),
            ),
            TableColumnSpec(
              title: 'ANGGOTA/HADIR',
              width: 150,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text('${r.jmlhAnggota ?? 0}/${r.hadir ?? 0}'),
            ),
            // TableColumnSpec(
            //   title: 'OUTPUT',
            //   width: 120,
            //   headerAlign: TextAlign.center,
            //   cellAlign: TextAlign.center,
            //   cellBuilder: (_, r) {
            //     final outputs = r.outputNoCrusherList;
            //     if (outputs.isEmpty) {
            //       return const Text('-', style: TextStyle(color: Colors.black54));
            //     }
            //     return Text(
            //       '${outputs.length} item',
            //       style: const TextStyle(
            //         fontSize: 12,
            //         color: Colors.blue,
            //         fontWeight: FontWeight.w500,
            //       ),
            //     );
            //   },
            // ),
            // TableColumnSpec(
            //   title: 'APPROVED',
            //   width: 110,
            //   headerAlign: TextAlign.center,
            //   cellAlign: TextAlign.center,
            //   cellBuilder: (_, r) => (r.approveBy != null && r.approveBy!.isNotEmpty)
            //       ? const Icon(Icons.verified, size: 18, color: Colors.green)
            //       : const Text('-', style: TextStyle(color: Colors.black54)),
            // ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Crusher Production'),
              actions: [
                if (vm.isByDateMode)
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    tooltip: 'Kembali ke mode list',
                    onPressed: vm.exitByDateModeAndRefreshPaged,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: vm.refreshPaged,
                  ),
              ],
            ),
            body: Column(
              children: [
                // 🔹 ACTION BAR (search + create)
                /// TODO: Implementasi setelah action bar widget siap
                CrusherProductionActionBar(
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
                  child: HorizontalPagedTable<CrusherProduction>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) => r.noCrusherProduksi == _selectedNoCrusherProduksi,
                    onRowTap: (r) => setState(() => _selectedNoCrusherProduksi = r.noCrusherProduksi),
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
    final vm = context.read<CrusherProductionViewModel>();

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CrusherProductionFormDialog(
        // header: null  // create mode
        onSave: (draft) async {
          try {
            // await vm.createProduksi(draft);
            if (context.mounted) {
              Navigator.of(context).pop(true); // signal success to caller
            }
          } catch (e) {
            // optional: show error
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal membuat crusher produksi: $e')),
              );
            }
          }
        },
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crusher produksi berhasil dibuat')),
      );
    }
  }

  Future<void> _openEditDialog(BuildContext context, CrusherProduction row) async {
    final vm = context.read<CrusherProductionViewModel>();

    // Open the form in EDIT mode by passing `header: row`
    final updated = await showDialog<CrusherProduction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CrusherProductionFormDialog(
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
        SnackBar(
          content: Text('No. Crusher Produksi ${updated.noCrusherProduksi} berhasil diperbarui'),
        ),
      );
    }
  }

}