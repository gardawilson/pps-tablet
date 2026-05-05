import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/atlas_data_table.dart';
import 'package:pps_tablet/common/widgets/atlas_paged_data_table.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';
import 'package:provider/provider.dart';
import '../model/stock_opname_model.dart';
import '../view_model/stock_opname_list_view_model.dart';
import 'stock_opname_detail_screen.dart';
import 'stock_opname_ascend_detail_screen.dart';

class StockOpnameListScreen extends StatefulWidget {
  const StockOpnameListScreen({super.key});

  @override
  State<StockOpnameListScreen> createState() => _StockOpnameListScreenState();
}

class _StockOpnameListScreenState extends State<StockOpnameListScreen> {
  final _searchCtrl = TextEditingController();

  static const _primary = Color(0xFF0D47A1);
  static const _primaryLt = Color(0xFFE3F0FF);
  static const _primaryMid = Color(0xFF90CAF9);
  static const _bgPage = Color(0xFFF8F9FB);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E6EE);
  static const _border2 = Color(0xFFDCDFE4);
  static const _textPrimary = Color(0xFF1A2340);
  static const _textSec = Color(0xFF4A5568);
  static const _textHint = Color(0xFF8896A6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<StockOpnameViewModel>(context, listen: false);
      vm.pagingController.refresh();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Consumer<StockOpnameViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              _buildToolbar(vm),
              Expanded(child: _buildTable(vm)),
              _buildStatsBar(vm),
            ],
          );
        },
      ),
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────
  Widget _buildToolbar(StockOpnameViewModel vm) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => vm.setSearchQuery(v),
                style: const TextStyle(fontSize: 13, color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari Nomor SO...',
                  hintStyle: const TextStyle(fontSize: 13, color: _textHint),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: _textHint,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38),
                  filled: true,
                  fillColor: _bgPage,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primary, width: 1.4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ..._filterChips(vm),
        ],
      ),
    );
  }

  List<Widget> _filterChips(StockOpnameViewModel vm) {
    return ['Semua', 'Ascend', 'PPS'].map((f) {
      final active = vm.activeFilter == f;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => vm.setFilter(f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 38,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active ? _primaryLt : _surface,
              border: Border.all(color: active ? _primaryMid : _border2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              f,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _primary : _textSec,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTable(StockOpnameViewModel vm) {
    return AtlasPagedDataTable<StockOpname>(
      pagingController: vm.pagingController,
      columns: _columns(),
      selectedPredicate: (row) => false,
      onRowTap: (row) {
        Future.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;

          if (row.isAscend == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockOpnameAscendDetailScreen(
                  noSO: row.noSO,
                  tgl: row.tanggal,
                  idWarehouses: row.idWarehouses,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StockOpnameDetailScreen(noSO: row.noSO, tgl: row.tanggal),
              ),
            );
          }
        });
      },
      firstPageProgress: (_) =>
          const Center(child: CircularProgressIndicator()),
      newPageProgress: (_) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      ),
      firstPageError: (_) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Terjadi kesalahan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                vm.errorMessage.isNotEmpty
                    ? vm.errorMessage
                    : 'Gagal memuat data Stock Opname',
                style: const TextStyle(fontSize: 12, color: _textHint),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => vm.pagingController.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
      noItems: (_) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgPage,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 40,
                color: _textHint,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Belum ada dokumen stock opname',
              style: TextStyle(fontSize: 12, color: _textHint),
            ),
          ],
        ),
      ),
    );
  }

  List<AtlasTableColumn<StockOpname>> _columns() {
    return [
      AtlasTableColumn<StockOpname>(
        title: 'NOMOR SO',
        width: 170,
        cellBuilder: (_, row, state) => Text(
          row.noSO,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: state.isSelected ? const Color(0xFF0C66E4) : _textPrimary,
          ),
        ),
      ),
      AtlasTableColumn<StockOpname>(
        title: 'TANGGAL',
        width: 120,
        cellBuilder: (_, row, state) => Text(
          formatDateToShortId(row.tanggal),
          style: TextStyle(
            fontSize: 13,
            color: state.isSelected ? const Color(0xFF0C66E4) : _textSec,
          ),
        ),
      ),

      AtlasTableColumn<StockOpname>(
        title: 'SOURCE',
        width: 110,
        cellBuilder: (_, row, state) {
          return Text(
            row.isAscend ? 'Ascend' : 'PPS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: state.isSelected ? const Color(0xFF0C66E4) : _textSec,
            ),
          );
        },
      ),

      AtlasTableColumn<StockOpname>(
        title: 'WAREHOUSE',
        width: 220,
        cellBuilder: (_, row, state) => Text(
          row.namaWarehouse,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: state.isSelected ? const Color(0xFF0C66E4) : _textSec,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),

      AtlasTableColumn<StockOpname>(
        title: 'KATEGORI',
        width: 360,
        showDivider: false,
        cellBuilder: (_, row, state) {
          final cats = _activeCats(row);
          if (cats.isEmpty) {
            return Text(
              '-',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            );
          }

          return Text(
            cats.join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: state.isSelected ? const Color(0xFF0C66E4) : _textSec,
            ),
          );
        },
      ),
    ];
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar(StockOpnameViewModel vm) {
    final total = vm.totalResults;

    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: _border,
          ),
          _statItem('Total', '$total'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 11, color: _textHint),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: val,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<String> _activeCats(dynamic so) => [
    if (so.isBahanBaku == true) 'Bahan Baku',
    if (so.isWashing == true) 'Washing',
    if (so.isBonggolan == true) 'Bonggolan',
    if (so.isCrusher == true) 'Crusher',
    if (so.isBroker == true) 'Broker',
    if (so.isGilingan == true) 'Gilingan',
    if (so.isMixer == true) 'Mixer',
    if (so.isFurnitureWIP == true) 'Furniture WIP',
    if (so.isBarangJadi == true) 'Barang Jadi',
    if (so.isReject == true) 'Reject',
  ];
}
