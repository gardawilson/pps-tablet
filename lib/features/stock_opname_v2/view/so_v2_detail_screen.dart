import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/confirm_dialog.dart';
import '../../../common/widgets/scan_label_dialog.dart';
import '../model/so_v2_label_row.dart';
import '../model/so_v2_lokasi.dart';
import '../repository/so_v2_repository.dart';
import '../view_model/so_v2_blok_list_view_model.dart';
import '../view_model/so_v2_label_list_view_model.dart';
import '../view_model/so_v2_lokasi_list_view_model.dart';
import '../widgets/so_v2_label_tile.dart';
import '../widgets/so_v2_pallet_no_dialog.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);
const _kWarning = Color(0xFFB45309);
const _kWarningBg = Color(0xFFFFF7ED);
const _kWarningBorder = Color(0xFFFCD9A8);

/// Screen gabungan: panel blok, panel lokasi (dalam blok terpilih), panel
/// label (dalam lokasi terpilih). Tidak memakai AppBar sendiri karena sudah
/// ada compact app bar global dari AppShell.
class SoV2DetailScreen extends StatefulWidget {
  final String stockOpnameNo;
  final String categoryCode;

  const SoV2DetailScreen({
    super.key,
    required this.stockOpnameNo,
    required this.categoryCode,
  });

  @override
  State<SoV2DetailScreen> createState() => _SoV2DetailScreenState();
}

class _SoV2DetailScreenState extends State<SoV2DetailScreen> {
  final _repo = SoV2Repository();
  late final SoV2BlokListViewModel _blokVm;
  String? _selectedBlok;
  SoV2LokasiListViewModel? _lokasiVm;
  SoV2Lokasi? _selectedLokasi;
  SoV2LabelListViewModel? _labelVm;
  final _searchCtl = TextEditingController();
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _blokVm = SoV2BlokListViewModel(stockOpnameNo: widget.stockOpnameNo);
    _blokVm.load();
  }

  @override
  void dispose() {
    _blokVm.dispose();
    _lokasiVm?.dispose();
    _labelVm?.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  void _selectBlok(String blok) {
    if (_selectedBlok == blok) return;
    _lokasiVm?.dispose();
    _labelVm?.dispose();
    _searchCtl.clear();
    setState(() {
      _selectedBlok = blok;
      _selectedLokasi = null;
      _labelVm = null;
      _lokasiVm = SoV2LokasiListViewModel(
        stockOpnameNo: widget.stockOpnameNo,
        blok: blok,
      );
    });
    _lokasiVm!.load();
  }

  void _selectLokasi(SoV2Lokasi lokasi) {
    if (_selectedLokasi?.locationId == lokasi.locationId) return;
    _labelVm?.dispose();
    _searchCtl.clear();
    setState(() {
      _selectedLokasi = lokasi;
      _labelVm = SoV2LabelListViewModel(
        stockOpnameNo: widget.stockOpnameNo,
        blok: _selectedBlok!,
        locationId: lokasi.locationId,
        categoryCode: widget.categoryCode,
      );
    });
  }

  Future<void> _markComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Tandai Selesai',
        message:
            'Yakin ingin menandai stock opname ini selesai? Setelah selesai, scan label tidak dapat dilakukan lagi.',
        confirmLabel: 'Selesai',
        confirmIcon: Icons.check_circle_outline_rounded,
        confirmColor: Color(0xFF0A7349),
      ),
    );
    if (confirmed != true) return;

    setState(() => _completing = true);
    try {
      await _repo.completeStockOpname(widget.stockOpnameNo);
    } catch (_) {
      // completeStockOpname sudah menangani 409 idempotent di level API;
      // error lain cukup ditampilkan sebagai snackbar di bawah.
    }
    if (!mounted) return;
    setState(() => _completing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.stockOpnameNo} berhasil ditandai selesai'),
        backgroundColor: Colors.green.shade700,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<String?> _handleLookup(String code) async {
    final vm = _labelVm;
    if (vm == null) return 'Pilih lokasi terlebih dahulu';
    int? palletNo;
    if (vm.palletNoRequired) {
      final palletStr = await showDialog<String>(
        context: context,
        builder: (_) => const SoV2PalletNoDialog(),
      );
      if (palletStr == null) return 'Nomor pallet dibutuhkan';
      palletNo = int.tryParse(palletStr);
      if (palletNo == null) return 'Nomor pallet tidak valid';
    }
    return vm.scanLabel(labelNo: code, palletNo: palletNo);
  }

  void _openScanDialog() {
    if (_selectedLokasi == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => ScanLabelDialog(
        onLookup: _handleLookup,
        manualHint: 'Masukkan nomor label',
        headerSubtitle: _selectedLokasi!.description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      floatingActionButton: (_labelVm != null && !(_labelVm!.isComplete))
          ? FloatingActionButton.extended(
              onPressed: _openScanDialog,
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan'),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 160, child: _buildBlokPanel()),
          const VerticalDivider(width: 1, color: _kBorder),
          SizedBox(width: 320, child: _buildLokasiPanel()),
          const VerticalDivider(width: 1, color: _kBorder),
          Expanded(child: _buildLabelPanel()),
        ],
      ),
    );
  }

  // ── Panel 1: blok ───────────────────────────────────────────────────────

  Widget _buildBlokPanel() {
    return ChangeNotifierProvider<SoV2BlokListViewModel>.value(
      value: _blokVm,
      child: Consumer<SoV2BlokListViewModel>(
        builder: (context, vm, _) {
          return Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stockOpnameNo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1D23),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _completing ? null : _markComplete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0A7349),
                            side: const BorderSide(color: Color(0xFF0A7349)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: _completing
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                ),
                          label: const Text(
                            'Selesai',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: vm.load,
                    child: _buildBlokList(vm),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlokList(SoV2BlokListViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null && vm.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                vm.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 11),
              ),
            ),
          ),
        ],
      );
    }
    if (vm.items.isEmpty) {
      return const Center(
        child: Text('Belum ada blok', style: TextStyle(fontSize: 12)),
      );
    }
    final sortedItems = [...vm.items]..sort((a, b) {
      final aUnknown = a == kSoV2UnknownBlok;
      final bUnknown = b == kSoV2UnknownBlok;
      if (aUnknown != bUnknown) return aUnknown ? 1 : -1;
      return a.compareTo(b);
    });
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final blok = sortedItems[index];
        final isUnknown = blok == kSoV2UnknownBlok;
        final selected = _selectedBlok == blok;
        final baseColor = isUnknown ? _kWarning : _kPrimary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () => _selectBlok(blok),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? baseColor.withValues(alpha: 0.08)
                    : (isUnknown ? _kWarningBg : _kSurface),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? baseColor
                      : (isUnknown ? _kWarningBorder : _kBorder),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (isUnknown) ...[
                    Icon(
                      Icons.location_off_rounded,
                      size: 14,
                      color: selected ? baseColor : _kWarning,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      isUnknown ? 'Tanpa Blok' : 'Blok $blok',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? baseColor
                            : (isUnknown ? _kWarning : const Color(0xFF1A1D23)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Panel 2: lokasi ─────────────────────────────────────────────────────

  Widget _buildLokasiPanel() {
    final vm = _lokasiVm;
    if (_selectedBlok == null || vm == null) {
      return Center(
        child: Text(
          'Pilih blok di sebelah kiri',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }
    return ChangeNotifierProvider<SoV2LokasiListViewModel>.value(
      value: vm,
      child: Consumer<SoV2LokasiListViewModel>(
        builder: (context, vm, _) {
          return Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedBlok == kSoV2UnknownBlok
                                  ? 'Tanpa Blok'
                                  : 'Blok $_selectedBlok',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _selectedBlok == kSoV2UnknownBlok
                                    ? _kWarning
                                    : const Color(0xFF1A1D23),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${vm.items.length} lokasi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (vm.isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Selesai',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: vm.load,
                    child: _buildLokasiList(vm),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLokasiList(SoV2LokasiListViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null && vm.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              vm.error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      );
    }
    if (vm.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Belum ada lokasi',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      );
    }
    final sortedItems = [...vm.items]..sort((a, b) {
      if (a.isUnknown != b.isUnknown) return a.isUnknown ? 1 : -1;
      return 0;
    });
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sortedItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final lokasi = sortedItems[index];
        final selected = _selectedLokasi?.locationId == lokasi.locationId;
        final baseColor = lokasi.isUnknown ? _kWarning : _kPrimary;
        return InkWell(
          onTap: () => _selectLokasi(lokasi),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? baseColor.withValues(alpha: 0.08)
                  : (lokasi.isUnknown ? _kWarningBg : _kSurface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? baseColor
                    : (lokasi.isUnknown ? _kWarningBorder : _kBorder),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (lokasi.isUnknown) ...[
                  Icon(Icons.location_off_rounded, color: baseColor, size: 18),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lokasi.isUnknown
                            ? 'Lokasi Tidak Diketahui'
                            : 'Blok $_selectedBlok${lokasi.locationId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? baseColor
                              : (lokasi.isUnknown
                                  ? _kWarning
                                  : const Color(0xFF1A1D23)),
                        ),
                      ),
                      if (lokasi.isUnknown) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Label tanpa lokasi tercatat',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: _kWarning.withValues(alpha: 0.85),
                          ),
                        ),
                      ] else if (lokasi.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          lokasi.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        '${lokasi.labelCount} label · ${lokasi.totalWeight} kg',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ScannedCountBadge(
                  scanned: lokasi.scannedCount,
                  total: lokasi.labelCount,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Panel 3: label ──────────────────────────────────────────────────────

  Widget _buildLabelPanel() {
    final vm = _labelVm;
    if (vm == null || _selectedLokasi == null) {
      return Center(
        child: Text(
          'Pilih lokasi di sebelah kiri',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }
    return ChangeNotifierProvider<SoV2LabelListViewModel>.value(
      value: vm,
      child: Consumer<SoV2LabelListViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (_selectedLokasi!.isUnknown) ...[
                                const Icon(
                                  Icons.location_off_rounded,
                                  size: 16,
                                  color: _kWarning,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  _selectedLokasi!.isUnknown
                                      ? 'Lokasi Tidak Diketahui'
                                      : (_selectedLokasi!.description.isNotEmpty
                                          ? _selectedLokasi!.description
                                          : 'Lokasi ${_selectedLokasi!.locationId}'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedLokasi!.isUnknown
                                        ? _kWarning
                                        : const Color(0xFF1A1D23),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total berat: ${vm.totalWeight} kg · Discan: ${vm.totalScanned}/${vm.totalRecords}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (vm.isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.shade700,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Selesai',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (_selectedLokasi!.isUnknown)
                Container(
                  width: double.infinity,
                  color: _kWarningBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: _kWarning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Label berikut tidak memiliki blok/lokasi tercatat di sistem. Scan tetap dapat dilakukan seperti biasa.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _kWarning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _SearchBar(
                controller: _searchCtl,
                onChanged: vm.setSearchDebounced,
                onClear: () {
                  _searchCtl.clear();
                  vm.clearSearch();
                },
              ),
              Expanded(
                child: PagingListener<int, SoV2LabelRow>(
                  controller: vm.pagingController,
                  builder: (context, state, fetchNextPage) {
                    return RefreshIndicator(
                      onRefresh: () async => vm.pagingController.refresh(),
                      child: PagedListView<int, SoV2LabelRow>(
                        state: state,
                        fetchNextPage: fetchNextPage,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        builderDelegate:
                            PagedChildBuilderDelegate<SoV2LabelRow>(
                              itemBuilder: (context, row, index) =>
                                  SoV2LabelTile(row: row),
                              noItemsFoundIndicatorBuilder: (context) =>
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 80),
                                      child: Text('Belum ada label'),
                                    ),
                                  ),
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannedCountBadge extends StatelessWidget {
  final int scanned;
  final int total;

  const _ScannedCountBadge({required this.scanned, required this.total});

  @override
  Widget build(BuildContext context) {
    final complete = total > 0 && scanned >= total;
    final color = complete ? const Color(0xFF0A7349) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$scanned/$total',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari nomor label...',
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
    );
  }
}
