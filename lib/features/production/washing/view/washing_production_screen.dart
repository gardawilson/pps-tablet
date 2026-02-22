// lib/features/production/washing/view/washing_production_screen.dart
import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:pps_tablet/features/production/washing/view/washing_production_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';

// VM + Repo + Model washing
import '../view_model/washing_production_view_model.dart';
import '../repository/washing_production_repository.dart';
import '../model/washing_production_model.dart';

// Action bar & form dialog washing
import '../widgets/washing_delete_dialog.dart';
import '../widgets/washing_production_action_bar.dart';
import '../widgets/washing_production_form_dialog.dart';
import '../widgets/washing_production_header_table.dart';
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
        final safeLeft = local.dx.clamp(
          8.0,
          overlayBox.size.width - 320.0,
        ); // max width popover
        final safeTop = local.dy.clamp(
          8.0,
          overlayBox.size.height - 220.0,
        ); // max height popover

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
                          isLocked: row.isLocked,
                          lastClosedDate: row.lastClosedDate,
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

                          final success = await vm.deleteProduksi(
                            row.noProduksi,
                          );

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
                                message:
                                    'No. Produksi ${row.noProduksi} berhasil dihapus.',
                              ),
                            );
                          } else {
                            final rawMsg =
                                vm.saveError ?? 'Gagal menghapus data';

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
                      content: Text(
                        'Fitur print Washing belum tersedia untuk saat ini.',
                      ),
                      duration: Duration(milliseconds: 1200),
                    ),
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

  void _navigateToAuditHistory(WashingProduction header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noProduksi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          WashingProductionViewModel(repository: WashingProductionRepository())
            ..refreshPaged(),
      child: Consumer<WashingProductionViewModel>(
        builder: (context, vm, _) {
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
                WashingProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: WashingProductionHeaderTable(
                    selectedNoProduksi: _selectedNoProduksi,
                    onRowTap: (r) =>
                        setState(() => _selectedNoProduksi = r.noProduksi),
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
  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<WashingProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const WashingProductionFormDialog(header: null),
    );

    if (!mounted || !ctx.mounted) return;

    if (created != null) {
      ctx.read<WashingProductionViewModel>().refreshPaged();
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

  // =========================================================
  //  DIALOG EDIT (kalau nanti sudah ada endpoint update)
  // =========================================================
  Future<void> _openEditDialog(
    BuildContext ctx,
    WashingProduction row,
  ) async {
    final updated = await showDialog<WashingProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => WashingProductionFormDialog(header: row),
    );

    if (!mounted || !ctx.mounted) return;

    if (updated != null) {
      ctx.read<WashingProductionViewModel>().refreshPaged();
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Mengupdate',
          message: 'No. Produksi ${updated.noProduksi} berhasil diperbarui.',
        ),
      );
    }
  }
}
