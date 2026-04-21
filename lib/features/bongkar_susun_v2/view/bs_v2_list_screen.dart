import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/bs_v2_transaction.dart';
import '../repository/bs_v2_repository.dart';
import '../view_model/bs_v2_list_view_model.dart';
import '../view_model/bs_v2_create_view_model.dart';
import 'bs_v2_create_screen.dart';
import 'bs_v2_detail_screen.dart';

class BsV2ListScreen extends StatefulWidget {
  const BsV2ListScreen({super.key});

  @override
  State<BsV2ListScreen> createState() => _BsV2ListScreenState();
}

class _BsV2ListScreenState extends State<BsV2ListScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  late final BsV2ListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = BsV2ListViewModel();
    _vm.refresh();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _showRowPopover(BsV2Transaction row, Offset globalPos) async {
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final local = overlay.globalToLocal(globalPos);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        final safeLeft = local.dx.clamp(8.0, overlay.size.width - 240.0);
        final safeTop = local.dy.clamp(8.0, overlay.size.height - 160.0);
        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop,
              child: _RowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onDetail: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BsV2DetailScreen(
                          noBongkarSusun: row.noBongkarSusun,
                        ),
                      ),
                    );
                  });
                },
                onDelete: () async {
                  Navigator.of(dialogCtx).pop();
                  await _confirmDelete(row);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BsV2Transaction row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Hapus ${row.noBongkarSusun}? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await _vm.delete(row.noBongkarSusun);
    if (!mounted) return;
    if (success) {
      showDialog(
        context: context,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Dihapus',
          message: '${row.noBongkarSusun} berhasil dihapus.',
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => ErrorStatusDialog(
          title: 'Gagal Menghapus',
          message: _vm.saveError ?? 'Gagal menghapus data',
        ),
      );
    }
  }

  void _openCreate() {
    final repo = BsV2Repository();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BsV2CreateViewModel(repository: repo),
          child: BsV2CreateScreen(onSubmitted: () => _vm.refresh()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BsV2ListViewModel>.value(
      value: _vm,
      child: Consumer<BsV2ListViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Bongkar Susun V2'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: vm.refresh,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Buat Transaksi'),
            ),
            body: Column(
              children: [
                _SearchBar(
                  controller: _searchCtl,
                  onChanged: vm.setSearchDebounced,
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearSearch();
                  },
                ),
                Expanded(
                  child: AtlasPagedDataTable<BsV2Transaction>(
                    pagingController: vm.pagingController,
                    columns: _columns(),
                    onRowTap: (row) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BsV2DetailScreen(
                          noBongkarSusun: row.noBongkarSusun,
                        ),
                      ),
                    ),
                    onRowLongPress: (row, pos) => _showRowPopover(row, pos),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<AtlasTableColumn<BsV2Transaction>> _columns() {
    return [
      AtlasTableColumn<BsV2Transaction>(
        title: 'NO. TRANSAKSI',
        width: 200,
        cellBuilder: (ctx, item, state) => Text(
          item.noBongkarSusun,
          style: TextStyle(
            fontSize: 14,
            fontWeight: state.isSelected ? FontWeight.w700 : FontWeight.w600,
            color: state.isSelected ? const Color(0xFF0C66E4) : Colors.black87,
          ),
        ),
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'TANGGAL',
        width: 130,
        cellBuilder: (ctx, item, state) => Text(
          formatDateToShortId(item.tanggal),
          style: TextStyle(fontSize: 14, color: state.textColor),
        ),
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'KATEGORI',
        width: 120,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (ctx, item, state) {
          final isWashing =
              item.inputs.isNotEmpty && item.inputs.first.isWashing;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isWashing ? Colors.blue.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isWashing ? 'Washing' : 'Bonggolan',
              style: TextStyle(
                fontSize: 12,
                color: isWashing
                    ? Colors.blue.shade800
                    : Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'OPERATOR',
        width: 130,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (ctx, item, state) => Text(
          item.username ?? '-',
          style: TextStyle(fontSize: 14, color: state.textColor),
        ),
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'INPUT',
        width: 80,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (ctx, item, state) => Text(
          '${item.inputs.length}',
          style: TextStyle(fontSize: 14, color: state.textColor),
        ),
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'OUTPUT',
        width: 80,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (ctx, item, state) => Text(
          '${item.outputs.length}',
          style: TextStyle(fontSize: 14, color: state.textColor),
        ),
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'CATATAN',
        width: 300,
        showDivider: false,
        cellBuilder: (ctx, item, state) => Text(
          item.note ?? '-',
          style: TextStyle(fontSize: 14, color: state.textColor),
          softWrap: true,
        ),
      ),
    ];
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Cari no. transaksi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowPopover extends StatelessWidget {
  final BsV2Transaction row;
  final VoidCallback onClose;
  final VoidCallback onDetail;
  final VoidCallback onDelete;

  const _RowPopover({
    required this.row,
    required this.onClose,
    required this.onDetail,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tile(Icons.info_outline, 'Lihat Detail', onDetail),
            const Divider(height: 1),
            _tile(Icons.delete_outline, 'Hapus', onDelete, color: Colors.red),
            const Divider(height: 1),
            _tile(Icons.close, 'Tutup', onClose),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: color),
      title: Text(label, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
    );
  }
}
