import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../features/mesin/model/mesin_model.dart';
import '../model/broker_production_model.dart';
import '../repository/broker_production_repository.dart';
import '../view_model/broker_production_view_model.dart';
import '../widgets/broker_delete_dialog.dart';
import '../widgets/broker_production_form_dialog.dart';
import 'broker_production_input_screen.dart';

class BrokerProductionMesinScreen extends StatefulWidget {
  const BrokerProductionMesinScreen({super.key});

  @override
  State<BrokerProductionMesinScreen> createState() =>
      _BrokerProductionMesinScreenState();
}

class _BrokerProductionMesinScreenState
    extends State<BrokerProductionMesinScreen> {
  final _prodRepo = BrokerProductionRepository();
  Future<List<BrokerMesinInfo>> _mesinFuture = Future.value(
    <BrokerMesinInfo>[],
  );

  // Right panel state — all produksi (paginated)
  final List<BrokerProduction> _produksiItems = [];
  bool _produksiLoading = false;
  bool _produksiFetchingMore = false;
  bool _produksiHasMore = true;
  int _produksiPage = 1;
  static const _pageSize = 30;
  final _produksiScrollCtl = ScrollController();
  int? _filterIdMesin;

  @override
  void initState() {
    super.initState();
    _loadMesin();
    _loadProduksiPage();
    _produksiScrollCtl.addListener(_onProduksiScroll);
  }

  Future<void> _loadMesin() async {
    final future = _prodRepo.fetchBrokerMesin();
    if (mounted) setState(() => _mesinFuture = future);
  }

  @override
  void dispose() {
    _produksiScrollCtl.dispose();
    super.dispose();
  }

  void _onProduksiScroll() {
    if (_produksiScrollCtl.position.pixels >=
            _produksiScrollCtl.position.maxScrollExtent - 100 &&
        !_produksiFetchingMore &&
        _produksiHasMore) {
      _loadMoreProduksi();
    }
  }

  Future<void> _loadProduksiPage() async {
    if (!mounted) return;
    setState(() {
      _produksiLoading = true;
      _produksiItems.clear();
      _produksiPage = 1;
      _produksiHasMore = true;
    });
    try {
      final res = await _prodRepo.fetchAll(
        page: 1,
        pageSize: _pageSize,
        idMesin: _filterIdMesin,
      );
      if (!mounted) return;
      final newItems = res['items'] as List<BrokerProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;
      setState(() {
        _produksiItems.addAll(newItems);
        _produksiHasMore = 1 < totalPages;
        _produksiLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _produksiLoading = false);
    }
  }

  Future<void> _loadMoreProduksi() async {
    if (!mounted || _produksiFetchingMore || !_produksiHasMore) return;
    setState(() => _produksiFetchingMore = true);
    try {
      final nextPage = _produksiPage + 1;
      final res = await _prodRepo.fetchAll(
        page: nextPage,
        pageSize: _pageSize,
        idMesin: _filterIdMesin,
      );
      if (!mounted) return;
      final newItems = res['items'] as List<BrokerProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;
      setState(() {
        _produksiItems.addAll(newItems);
        _produksiPage = nextPage;
        _produksiHasMore = nextPage < totalPages;
        _produksiFetchingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _produksiFetchingMore = false);
    }
  }

  Future<({int shift, String hourStart, String hourEnd})?>
  _fetchCurrentShift() async {
    try {
      final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');
      final url = Uri.parse('$base/api/mst/shift/current');
      final token = await TokenStorage.getToken();
      final res = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final shift = data['shift'] as int?;
      String trim(String? v) =>
          (v != null && v.length >= 5) ? v.substring(0, 5) : (v ?? '');
      final hourStart = trim(data['hourStart'] as String?);
      final hourEnd = trim(data['hourEnd'] as String?);
      if (shift == null) return null;
      return (shift: shift, hourStart: hourStart, hourEnd: hourEnd);
    } catch (_) {
      return null;
    }
  }

  void _refreshAll() {
    _loadMesin();
    _loadProduksiPage();
  }

  Future<void> _openCreateDialog({
    required BrokerMesinInfo mesin,
    required DateTime today,
  }) async {
    if (!mounted) return;
    final mstMesin = MstMesin(
      idMesin: mesin.idMesin,
      namaMesin: mesin.namaMesin,
      bagian: mesin.bagian,
      enable: true,
    );
    final defaultShift = await _fetchCurrentShift();
    if (!mounted) return;
    final created = await showDialog<BrokerProduction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrokerProductionFormDialog(
        initialMesin: mstMesin,
        initialDate: today,
        existingProduksiList: mesin.produksiList,
        initialShift: defaultShift?.shift,
        initialHourStart: defaultShift?.hourStart,
        initialHourEnd: defaultShift?.hourEnd,
      ),
    );
    if (!mounted) return;
    if (created != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BrokerProductionInputScreen(
            noProduksi: created.noProduksi,
            idMesin: created.idMesin,
            namaMesin: created.namaMesin.isNotEmpty
                ? created.namaMesin
                : mesin.namaMesin,
            shift: created.shift,
            tglProduksi: created.tglProduksi,
            isLocked: created.isLocked,
            lastClosedDate: created.lastClosedDate,
            hourStart: created.hourStart,
            hourEnd: created.hourEnd,
            namaJenis: created.outputJenisNama,
            outputJenisId: created.outputJenisId,
          ),
        ),
      );
      if (!mounted) return;
    }
    _refreshAll();
  }

  Future<void> _onMesinTap(BrokerMesinInfo mesin) async {
    if (!mounted) return;
    final item = mesin.produksiList.isNotEmpty
        ? mesin.produksiList.first
        : null;
    if (item == null) {
      await _openCreateDialog(mesin: mesin, today: DateTime.now());
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrokerProductionInputScreen(
          noProduksi: item.noProduksi,
          idMesin: mesin.idMesin,
          namaMesin: mesin.namaMesin,
          shift: item.shift ?? 1,
          tglProduksi: item.tglProduksi,
          isLocked: false,
          lastClosedDate: null,
          hourStart: item.hourStart,
          hourEnd: item.hourEnd,
          namaJenis: item.outputJenisNama,
          outputJenisId: item.outputJenisId,
        ),
      ),
    );
    if (!mounted) return;
    _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── LEFT: mesin grid (3/4) ──────────────────────────────
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<BrokerMesinInfo>>(
                  future: _mesinFuture,
                  builder: (context, snapshot) {
                    final allMesin = snapshot.data ?? [];
                    final activeCount = allMesin
                        .where((m) => m.isActive)
                        .length;
                    final inactiveCount = allMesin.length - activeCount;
                    return _MesinSectionHeader(
                      onRefresh: _refreshAll,
                      activeCount: activeCount,
                      inactiveCount: inactiveCount,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
                Expanded(
                  child: FutureBuilder<List<BrokerMesinInfo>>(
                    future: _mesinFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Gagal memuat mesin\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }
                      final allMesin = snapshot.data ?? [];
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisExtent: 110,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: allMesin.length,
                        itemBuilder: (context, index) {
                          final mesin = allMesin[index];
                          return _MesinCard(
                            mesin: mesin,
                            onTap: () => _onMesinTap(mesin),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── DIVIDER ─────────────────────────────────────────────
          const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),

          // ── RIGHT: riwayat produksi (1/4) ───────────────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<BrokerMesinInfo>>(
                  future: _mesinFuture,
                  builder: (context, snapshot) {
                    return _RiwayatSectionHeader(
                      mesinList: snapshot.data ?? [],
                      selectedIdMesin: _filterIdMesin,
                      onFilterChanged: (id) {
                        setState(() => _filterIdMesin = id);
                        _loadProduksiPage();
                      },
                    );
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadProduksiPage,
                    child: _ProduksiList(
                      items: _produksiItems,
                      isLoading: _produksiLoading,
                      isFetchingMore: _produksiFetchingMore,
                      scrollController: _produksiScrollCtl,
                      filterIdMesin: _filterIdMesin,
                      onTap: (row) async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BrokerProductionInputScreen(
                              noProduksi: row.noProduksi,
                              idMesin: row.idMesin,
                              namaMesin: row.namaMesin,
                              shift: row.shift,
                              tglProduksi: row.tglProduksi,
                              isLocked: row.isLocked,
                              lastClosedDate: row.lastClosedDate,
                              hourStart: row.hourStart,
                              hourEnd: row.hourEnd,
                              namaJenis: row.outputJenisNama,
                              outputJenisId: row.outputJenisId,
                            ),
                          ),
                        );
                        if (mounted) _refreshAll();
                      },
                      onEdit: (row) async {
                        final editVm = BrokerProductionViewModel();
                        try {
                          await showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => ChangeNotifierProvider.value(
                              value: editVm,
                              child: BrokerProductionFormDialog(header: row),
                            ),
                          );
                        } finally {
                          editVm.dispose();
                        }
                        if (mounted) _refreshAll();
                      },
                      onDelete: (row) async {
                        await showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => BrokerProductionDeleteDialog(
                            header: row,
                            onConfirm: () async {
                              final deleteVm = BrokerProductionViewModel();
                              final success = await deleteVm.deleteProduksi(
                                row.noProduksi,
                              );
                              final errMsg = deleteVm.saveError;
                              deleteVm.dispose();
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (!mounted) return;
                              if (success) {
                                // ignore: use_build_context_synchronously
                                showDialog(
                                  context: context,
                                  builder: (_) => SuccessStatusDialog(
                                    title: 'Berhasil Menghapus',
                                    message:
                                        'No. Produksi ${row.noProduksi} berhasil dihapus.',
                                  ),
                                );
                              } else {
                                // ignore: use_build_context_synchronously
                                showDialog(
                                  context: context,
                                  builder: (_) => ErrorStatusDialog(
                                    title: 'Gagal Menghapus!',
                                    message: errMsg ?? 'Gagal menghapus data',
                                  ),
                                );
                              }
                              _refreshAll();
                            },
                          ),
                        );
                      },
                      onInput: (row) async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BrokerProductionInputScreen(
                              noProduksi: row.noProduksi,
                              idMesin: row.idMesin,
                              namaMesin: row.namaMesin,
                              shift: row.shift,
                              tglProduksi: row.tglProduksi,
                              isLocked: row.isLocked,
                              lastClosedDate: row.lastClosedDate,
                              hourStart: row.hourStart,
                              hourEnd: row.hourEnd,
                              namaJenis: row.outputJenisNama,
                              outputJenisId: row.outputJenisId,
                            ),
                          ),
                        );
                        if (mounted) _refreshAll();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _MesinSectionHeader extends StatelessWidget {
  const _MesinSectionHeader({
    required this.onRefresh,
    required this.activeCount,
    required this.inactiveCount,
    required this.isLoading,
  });
  final VoidCallback onRefresh;
  final int activeCount;
  final int inactiveCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Text(
            'Status Mesin Broker',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          if (!isLoading) ...[
            const SizedBox(width: 10),
            _StatBadge(
              count: activeCount,
              label: 'Aktif',
              color: const Color(0xFF16A34A),
              bg: const Color(0xFFDCFCE7),
            ),
            const SizedBox(width: 6),
            _StatBadge(
              count: inactiveCount,
              label: 'Tidak Aktif',
              color: const Color(0xFFDC2626),
              bg: const Color(0xFFFEE2E2),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF6B7280)),
            tooltip: 'Refresh',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });
  final int count;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiwayatSectionHeader extends StatelessWidget {
  const _RiwayatSectionHeader({
    required this.mesinList,
    required this.selectedIdMesin,
    required this.onFilterChanged,
  });

  final List<BrokerMesinInfo> mesinList;
  final int? selectedIdMesin;
  final ValueChanged<int?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row + chip "Semua" sejajar (44px)
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Text(
                    'Riwayat Produksi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Semua',
                    selected: selectedIdMesin == null,
                    onTap: () => onFilterChanged(null),
                  ),
                ],
              ),
            ),
          ),
          // Chips mesin di bawah
          if (mesinList.isNotEmpty)
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                children: mesinList
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: m.namaMesin,
                          selected: selectedIdMesin == m.idMesin,
                          onTap: () => onFilterChanged(m.idMesin),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Produksi list panel (right side)
// ─────────────────────────────────────────────────────────────────────────────
class _ProduksiList extends StatelessWidget {
  const _ProduksiList({
    required this.items,
    required this.isLoading,
    required this.isFetchingMore,
    required this.scrollController,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onInput,
    this.filterIdMesin,
  });

  final List<BrokerProduction> items;
  final bool isLoading;
  final bool isFetchingMore;
  final ScrollController scrollController;
  final Future<void> Function(BrokerProduction) onTap;
  final Future<void> Function(BrokerProduction) onEdit;
  final Future<void> Function(BrokerProduction) onDelete;
  final Future<void> Function(BrokerProduction) onInput;
  final int? filterIdMesin;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data produksi',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length + (isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final row = items[index];
        return _ProduksiRow(
          row: row,
          showRegu: filterIdMesin != null,
          onTap: () => onTap(row),
          onEdit: () => onEdit(row),
          onDelete: () => onDelete(row),
          onInput: () => onInput(row),
        );
      },
    );
  }
}

class _ProduksiRow extends StatelessWidget {
  const _ProduksiRow({
    required this.row,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onInput,
    this.showRegu = false,
  });

  final BrokerProduction row;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onInput;
  final bool showRegu;

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final jenis = (row.outputJenisNama ?? '').trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Date + shift + jam dalam 1 kolom
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtDate(row.tglProduksi),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Shift ${row.shift}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    '${row.hourStart ?? '--:--'} – ${row.hourEnd ?? '--:--'}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Mesin / Regu name
              Expanded(
                flex: 2,
                child: Text(
                  showRegu
                      ? (row.namaRegu?.trim().isNotEmpty == true
                            ? row.namaRegu!.trim()
                            : '-')
                      : row.namaMesin,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Jenis output
              Expanded(
                flex: 3,
                child: Text(
                  jenis.isEmpty ? '-' : jenis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: jenis.isEmpty
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF374151),
                    fontStyle: jenis.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                tooltip: 'Aksi',
                onSelected: (value) {
                  if (value == 'input') onInput();
                  if (value == 'edit') onEdit();
                  if (value == 'hapus') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'input',
                    child: Row(
                      children: [
                        Icon(
                          Icons.input_outlined,
                          size: 16,
                          color: Color(0xFF00897B),
                        ),
                        SizedBox(width: 8),
                        Text('Input', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF0D47A1),
                        ),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hapus',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mesin card (compact for narrow left panel)
// ─────────────────────────────────────────────────────────────────────────────
class _MesinCard extends StatelessWidget {
  const _MesinCard({required this.mesin, required this.onTap});

  final BrokerMesinInfo mesin;
  final VoidCallback onTap;

  BrokerProduksiItem? _currentItem() {
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;

    TimeOfDay? parse(String? s) {
      if (s == null || s.isEmpty) return null;
      final parts = s.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    }

    for (final p in mesin.produksiList) {
      final start = parse(p.hourStart);
      final end = parse(p.hourEnd);
      if (start == null || end == null) continue;
      final s = start.hour * 60 + start.minute;
      final e = end.hour * 60 + end.minute;
      final inRange = s <= e
          ? nowMin >= s && nowMin < e
          : nowMin >= s || nowMin < e;
      if (inRange) return p;
    }
    return mesin.produksiList.isNotEmpty ? mesin.produksiList.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final active = mesin.isActive;
    final current = active ? _currentItem() : null;
    final borderColor = active
        ? const Color(0xFF86EFAC)
        : const Color(0xFFFCA5A5);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      mesin.namaMesin,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _StatusDot(active: active),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 6),
              if (current != null) ...[
                if (current.shift != null ||
                    current.hourStart != null ||
                    current.hourEnd != null)
                  _SmallInfo(
                    icon: Icons.access_time_outlined,
                    text: [
                      if (current.shift != null) 'Shift ${current.shift}',
                      '${current.hourStart ?? '--:--'} – ${current.hourEnd ?? '--:--'}',
                    ].join('  |  '),
                    bold: true,
                  ),
                if (current.operator_ != null) ...[
                  const SizedBox(height: 2),
                  _SmallInfo(
                    icon: Icons.person_outline,
                    text: current.operator_!,
                  ),
                ],
                if (current.outputJenisNama != null &&
                    current.outputJenisNama!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _SmallInfo(
                    icon: Icons.inventory_2_outlined,
                    text: current.outputJenisNama!.trim(),
                    color: const Color(0xFF374151),
                  ),
                ],
              ] else
                const Text(
                  'Belum aktif',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFFB91C1C),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({
    required this.icon,
    required this.text,
    this.bold = false,
    this.color,
  });
  final IconData icon;
  final String text;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? const Color(0xFF4B5563);
    return Row(
      children: [
        Icon(icon, size: 10, color: textColor),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: textColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
