import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../mst_barang_jadi/repository/mst_barang_jadi_repository.dart';
import '../../mst_barang_jadi/view_model/mst_barang_jadi_view_model.dart';
import '../../warehouse/repository/warehouse_repository.dart';
import '../../warehouse/view_model/warehouse_view_model.dart';
import '../model/sr_v2_transaction.dart';
import '../repository/sr_v2_repository.dart';
import '../view_model/sr_v2_create_view_model.dart';
import '../view_model/sr_v2_list_view_model.dart';
import 'sr_v2_create_screen.dart';
import 'sr_v2_detail_screen.dart';

// ─── Theme ─────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);

// ─── Screen ────────────────────────────────────────────────────────────────

class SrV2ListScreen extends StatefulWidget {
  const SrV2ListScreen({super.key});

  @override
  State<SrV2ListScreen> createState() => _SrV2ListScreenState();
}

class _SrV2ListScreenState extends State<SrV2ListScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  late final SrV2ListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SrV2ListViewModel();
    _vm.refresh();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _showRowPopover(SrV2Transaction row, Offset globalPos) async {
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
        final safeTop = local.dy.clamp(8.0, overlay.size.height - 140.0);
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
                        builder: (_) =>
                            SrV2DetailScreen(noSortir: row.noSortir),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openCreate() {
    final repo = SrV2Repository();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => SrV2CreateViewModel(repository: repo),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  WarehouseViewModel(repository: WarehouseRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  MstBarangJadiViewModel(repository: MstBarangJadiRepository()),
            ),
          ],
          child: SrV2CreateScreen(onSubmitted: () => _vm.refresh()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SrV2ListViewModel>.value(
      value: _vm,
      child: Consumer<SrV2ListViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: _kSurface,
            appBar: _buildAppBar(),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Buat Baru',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
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
                  child: AtlasPagedDataTable<SrV2Transaction>(
                    pagingController: vm.pagingController,
                    columns: _columns(),
                    rowColorBuilder: (row) =>
                        (row.balance == false) ? Colors.red.shade50 : null,
                    onRowTap: (row) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SrV2DetailScreen(noSortir: row.noSortir),
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

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    color: _kPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sortir Reject',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D23),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Riwayat transaksi',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A94A6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<AtlasTableColumn<SrV2Transaction>> _columns() {
    return [
      AtlasTableColumn<SrV2Transaction>(
        title: 'NO. SORTIR',
        width: 150,
        cellBuilder: (ctx, item, state) => Text(
          item.noSortir,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: state.isSelected
                ? const Color(0xFF0C66E4)
                : const Color(0xFF1A1D23),
            letterSpacing: -0.2,
          ),
        ),
      ),
      AtlasTableColumn<SrV2Transaction>(
        title: 'TANGGAL',
        width: 120,
        cellBuilder: (ctx, item, state) => Text(
          formatDateToShortId(item.tanggal),
          style: TextStyle(
            fontSize: 13,
            color: state.isSelected
                ? const Color(0xFF0C66E4)
                : const Color(0xFF4B5563),
          ),
        ),
      ),
      AtlasTableColumn<SrV2Transaction>(
        title: 'WAREHOUSE',
        width: 140,
        cellBuilder: (ctx, item, state) => Text(
          item.namaWarehouse ?? '-',
          style: TextStyle(
            fontSize: 13,
            color: state.isSelected
                ? const Color(0xFF0C66E4)
                : const Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      AtlasTableColumn<SrV2Transaction>(
        title: 'CREATE BY',
        width: 150,
        cellBuilder: (ctx, item, state) {
          final name = item.username;
          if (name == null || name.isEmpty) {
            return Text(
              '—',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    color: state.isSelected
                        ? const Color(0xFF0C66E4)
                        : const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      AtlasTableColumn<SrV2Transaction>(
        title: 'IN → OUT',
        width: 110,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        showDivider: false,
        cellBuilder: (ctx, item, state) {
          final inputCount = item.inputLabelCount ?? item.inputs.length;
          final outputCount = item.outputLabelCount ?? item.outputs.length;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CountPill(count: inputCount, color: const Color(0xFF1E6FD9)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: Colors.grey.shade400,
                ),
              ),
              _CountPill(count: outputCount, color: const Color(0xFF0A7349)),
            ],
          );
        },
      ),
    ];
  }
}

// ─── Count Pill ────────────────────────────────────────────────────────────

class _CountPill extends StatelessWidget {
  final int count;
  final Color color;

  const _CountPill({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Search Bar ────────────────────────────────────────────────────────────

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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari nomor sortir...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: onClear,
                      )
                    : null,
                filled: true,
                fillColor: _kSurface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
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

// ─── Row Popover ───────────────────────────────────────────────────────────

class _RowPopover extends StatelessWidget {
  final SrV2Transaction row;
  final VoidCallback onClose;
  final VoidCallback onDetail;

  const _RowPopover({
    required this.row,
    required this.onClose,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black26,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: const Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.content_cut_rounded,
                    size: 14,
                    color: Color(0xFF8A94A6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      row.noSortir,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _tile(
              Icons.open_in_new_rounded,
              'Lihat Detail',
              onDetail,
              color: _kPrimary,
            ),
            const Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: _kBorder,
            ),
            _tile(Icons.close_rounded, 'Tutup', onClose),
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
    final c = color ?? const Color(0xFF374151);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
