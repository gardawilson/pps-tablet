// lib/features/production/broker/view/bongkar_susun_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../view_model/broker_production_view_model.dart';
import '../repository/broker_production_repository.dart';
import '../model/broker_production_model.dart';
import '../../../../core/utils/date_formatter.dart';

// Action bar
import '../widgets/broker_delete_dialog.dart';
import '../widgets/broker_production_action_bar.dart';
// Inputs screen (Scan action)
import '../widgets/broker_production_form_dialog.dart';
import 'broker_production_input_screen.dart';
// ⬇️ New: the popover panel you created
import '../widgets/broker_production_row_popover.dart';

class BrokerProductionScreen extends StatefulWidget {
  const BrokerProductionScreen({super.key});

  @override
  State<BrokerProductionScreen> createState() => _BrokerProductionScreenState();
}

class _BrokerProductionScreenState extends State<BrokerProductionScreen> {
  final _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _showRowPopover({
    required BuildContext context,
    required BrokerProduction row,
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
              child: BrokerProductionRowPopover(
                row: row,
                // ⬅️ CLOSE popover dengan context dialog, bukan context screen
                onClose: () => Navigator.of(dialogCtx).pop(),

                onInput: () {
                  // popover sudah tertutup oleh _runAndClose di dalam popover
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BrokerProductionInputScreen(
                          noProduksi: row.noProduksi,
                        ),
                      ),
                    );
                  });
                },

                onEdit: () async {
                  await _openEditDialog(context, row);
                  // gak perlu maybePop di sini, popover sudah di-close lewat onClose
                },

                onDelete: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      return BrokerProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final vm = context.read<BrokerProductionViewModel>();

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
      create: (_) => BrokerProductionViewModel(
        repository: BrokerProductionRepository(),
      )..refreshPaged(),
      child: Consumer<BrokerProductionViewModel>(
        builder: (context, vm, _) {
          final columns = <TableColumnSpec<BrokerProduction>>[
            TableColumnSpec(
              title: 'NO. PRODUKSI',
              width: 160,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(r.noProduksi, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            TableColumnSpec(
              title: 'TANGGAL',
              width: 130,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(formatDateToShortId(r.tglProduksi)),
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
              cellBuilder: (_, r) => Text(r.namaMesin, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            TableColumnSpec(
              title: 'OPERATOR',
              width: 200,
              cellBuilder: (_, r) => Text(r.namaOperator, maxLines: 1, overflow: TextOverflow.ellipsis),
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
              cellBuilder: (_, r) => Text('${r.hourMeter ?? 0}'),
            ),
            TableColumnSpec(
              title: 'ANGGOTA/HADIR',
              width: 150,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text('${r.jmlhAnggota ?? 0}/${r.hadir ?? 0}'),
            ),
            TableColumnSpec(
              title: 'APPROVED',
              width: 110,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => (r.approveBy != null && r.approveBy!.isNotEmpty)
                  ? const Icon(Icons.verified, size: 18, color: Colors.green)
                  : const Text('-', style: TextStyle(color: Colors.black54)),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Broker Production'),
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
                // 🔹 ACTION BAR (search + create)
                BrokerProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,   // ⬅️ open dialog here

                ),

                // 🔹 TABLE
                Expanded(
                  child: HorizontalPagedTable<BrokerProduction>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) => r.noProduksi == _selectedNoProduksi,
                    onRowTap: (r) => setState(() => _selectedNoProduksi = r.noProduksi),
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
    final vm = context.read<BrokerProductionViewModel>();

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrokerProductionFormDialog(
        // header: null  // create mode
        onSave: (draft) async {
          try {
            // await vm.create(draft);      // implement in your VM/repo
            if (context.mounted) {
            }
          } catch (e) {
            // optional: show error
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal membuat label: $e')),
              );
            }
          }
        },
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label berhasil dibuat')),
      );
    }
  }


  Future<void> _openEditDialog(BuildContext context, BrokerProduction row) async {
    final vm = context.read<BrokerProductionViewModel>();

    // Open the form in EDIT mode by passing `header: row`
    final updated = await showDialog<BrokerProduction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BrokerProductionFormDialog(
        header: row, // ← send current values here
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
