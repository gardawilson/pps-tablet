// lib/features/production/broker/view/broker_production_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../view_model/broker_production_view_model.dart';
import '../repository/broker_production_repository.dart';
import '../model/broker_production_model.dart';
import '../../../../core/utils/date_formatter.dart';

// Action bar
import '../widgets/broker_production_action_bar.dart';
// Inputs screen (Scan action)
import 'broker_inputs_screen.dart';
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
    required Offset globalPos, // from onRowLongPress
  }) async {
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    // Position the popover relative to the tap point
    final local = overlay.globalToLocal(globalPos);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (_) {
        // Keep popover within the screen bounds a bit
        final safeLeft = local.dx.clamp(8.0, overlay.size.width - 320.0);
        final safeTop  = local.dy.clamp(8.0, overlay.size.height - 220.0);

        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop,
              child: BrokerProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(context).maybePop(),
                onEdit: () async {
                  // TODO: open your edit modal/screen with `row`
                  // After success, refresh if needed:
                  // context.read<BrokerProductionViewModel>().refreshPaged();
                },
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Data'),
                      content: Text('Hapus NoProduksi "${row.noProduksi}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    // TODO: call delete API here
                    // await repository.delete(row.noProduksi);
                    context.read<BrokerProductionViewModel>().refreshPaged();
                  }
                },
                onPrint: () async {
                  // This hook is optional since the popover already implements print
                  // If you want extra behavior, put it here.
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
                  onAddPressed: () {
                    // TODO: open your create flow
                    // after create => vm.refreshPaged();
                  },
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
}
