import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../shared/widgets/mesin_section_header.dart';
import '../../shared/widgets/production_mesin_card.dart';
import '../../shared/widgets/production_produksi_list.dart';
import '../../shared/widgets/production_riwayat_header.dart';
import '../../../mesin/model/mesin_model.dart';
import '../../../shift/repository/shift_repository.dart';
import '../model/spanner_production_model.dart';
import '../repository/spanner_production_repository.dart';
import '../view_model/spanner_production_view_model.dart';
import '../widgets/spanner_production_delete_dialog.dart';
import '../widgets/spanner_production_form_dialog.dart';
import 'spanner_production_input_screen.dart';

class SpannerProductionMesinScreen extends StatefulWidget {
  const SpannerProductionMesinScreen({super.key});

  @override
  State<SpannerProductionMesinScreen> createState() =>
      _SpannerProductionMesinScreenState();
}

class _SpannerProductionMesinScreenState
    extends State<SpannerProductionMesinScreen> {
  final _repo = SpannerProductionRepository();
  late final SpannerProductionViewModel _editVmPool;

  Future<List<SpannerMesinInfo>> _mesinFuture = Future.value(
    <SpannerMesinInfo>[],
  );

  final List<SpannerProduction> _produksiItems = [];
  bool _produksiLoading = false;
  bool _produksiFetchingMore = false;
  bool _produksiHasMore = true;
  int _produksiPage = 1;
  static const _pageSize = 30;
  final _produksiScrollCtl = ScrollController();
  int? _filterIdMesin;
  SpannerMesinInfo? _selectedMesinInfo;
  bool _isRiwayatExpanded = true;

  @override
  void initState() {
    super.initState();
    _editVmPool = SpannerProductionViewModel(repository: _repo);
    _loadMesin();
    _loadProduksiPage();
    _produksiScrollCtl.addListener(_onProduksiScroll);
  }

  @override
  void dispose() {
    _produksiScrollCtl.dispose();
    _editVmPool.dispose();
    super.dispose();
  }

  Future<void> _loadMesin() async {
    final future = _repo.fetchSpannerMesin();
    if (mounted) setState(() => _mesinFuture = future);
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
      final res = await _repo.fetchAll(page: 1, pageSize: _pageSize);
      if (!mounted) return;
      final newItems = res['items'] as List<SpannerProduction>;
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
      final res = await _repo.fetchAll(page: nextPage, pageSize: _pageSize);
      if (!mounted) return;
      final newItems = res['items'] as List<SpannerProduction>;
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

  void _refreshAll() {
    _loadMesin();
    _loadProduksiPage();
  }

  // ── Card / row data converters ────────────────────────────────────────────

  static MesinCardData _toMesinCardData(SpannerMesinInfo mesin) {
    String? shiftTimeText;
    if (mesin.isActive) {
      final parts = <String>[];
      if (mesin.shift != null) parts.add('Shift ${mesin.shift}');
      parts.add('${mesin.hourStart ?? '--:--'} – ${mesin.hourEnd ?? '--:--'}');
      shiftTimeText = parts.join('  |  ');
    }
    return MesinCardData(
      namaMesin: mesin.namaMesin,
      isActive: mesin.isActive,
      shiftTimeText: shiftTimeText,
      namaRegu: mesin.namaRegu,
      outputJenisNama: mesin.outputJenisNama,
    );
  }

  static ProduksiRowData _toRowData(SpannerProduction row) {
    return ProduksiRowData(
      tglProduksi: row.tglProduksi,
      hourStart: row.hourStart,
      hourEnd: row.hourEnd,
      shift: row.shift,
      isLocked: row.isLocked,
      namaMesin: row.namaMesin,
      namaRegu: row.namaRegu,
      outputJenisNama: row.outputJenisNama,
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  Future<void> _openCreateDialog({required SpannerMesinInfo mesin}) async {
    if (!mounted) return;
    final mstMesin = MstMesin(
      idMesin: mesin.idMesin,
      namaMesin: mesin.namaMesin,
      bagian: mesin.bagian,
      enable: true,
    );
    final defaultShift = await ShiftRepository.fetchCurrentShift();
    if (!mounted) return;

    final editVm = SpannerProductionViewModel(repository: _repo);
    try {
      final created = await showDialog<SpannerProduction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: editVm,
          child: SpannerProductionFormDialog(
            initialMesin: mstMesin,
            initialDate: DateTime.now(),
            initialShift: defaultShift?.shift,
            initialHourStart: defaultShift?.hourStart,
            initialHourEnd: defaultShift?.hourEnd,
          ),
        ),
      );
      if (!mounted) return;
      if (created != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SpannerProductionInputScreen(
              noProduksi: created.noProduksi,
              isLocked: created.isLocked,
              lastClosedDate: created.lastClosedDate,
              idMesin: created.idMesin,
              namaJenis: created.outputJenisNama,
              outputJenisId: created.outputJenisId,
              tglProduksi: created.tglProduksi,
              shift: created.shift,
              hourStart: created.hourStart,
              hourEnd: created.hourEnd,
            ),
          ),
        );
        if (!mounted) return;
      }
    } finally {
      editVm.dispose();
    }
    _refreshAll();
  }

  Future<void> _onMesinTap(SpannerMesinInfo mesin) async {
    if (!mounted) return;

    if (!mesin.isActive) {
      await _openCreateDialog(mesin: mesin);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpannerProductionInputScreen(
          noProduksi: mesin.noProduksi!,
          isLocked: false,
          lastClosedDate: null,
          idMesin: mesin.idMesin,
          namaJenis: mesin.outputJenisNama,
          outputJenisId: mesin.outputJenisId,
          tglProduksi: mesin.tglProduksi,
          shift: mesin.shift,
          hourStart: mesin.hourStart,
          hourEnd: mesin.hourEnd,
        ),
      ),
    );
    if (!mounted) return;
    _refreshAll();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── LEFT: mesin grid (3/5) ──────────────────────────────
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<SpannerMesinInfo>>(
                  future: _mesinFuture,
                  builder: (context, snapshot) {
                    final allMesin = snapshot.data ?? [];
                    final activeCount = allMesin
                        .where((m) => m.isActive)
                        .length;
                    final inactiveCount = allMesin.length - activeCount;
                    return MesinSectionHeader(
                      title: 'Status Mesin Spanner',
                      onToggleRiwayat: () =>
                          setState(() => _isRiwayatExpanded = !_isRiwayatExpanded),
                      isRiwayatVisible: _isRiwayatExpanded,
                      activeCount: activeCount,
                      inactiveCount: inactiveCount,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
                Expanded(
                  child: FutureBuilder<List<SpannerMesinInfo>>(
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
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final cols =
                              (constraints.maxWidth / 150).floor().clamp(2, 6);
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisExtent: 110,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: allMesin.length,
                            itemBuilder: (context, index) {
                              final mesin = allMesin[index];
                              return ProductionMesinCard(
                                data: _toMesinCardData(mesin),
                                onTap: () => _onMesinTap(mesin),
                              );
                            },
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

          // ── RIGHT: riwayat produksi (2/5) ───────────────────────
          if (_isRiwayatExpanded)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<SpannerMesinInfo>>(
                  future: _mesinFuture,
                  builder: (context, snapshot) {
                    return ProductionRiwayatHeader(
                      mesinList: (snapshot.data ?? [])
                          .map(
                            (m) => MesinFilterItem(
                              idMesin: m.idMesin,
                              namaMesin: m.namaMesin,
                            ),
                          )
                          .toList(),
                      selectedIdMesin: _filterIdMesin,
                      onFilterChanged: (id) {
                        final mesinData = snapshot.data ?? [];
                        setState(() {
                          _filterIdMesin = id;
                          _selectedMesinInfo = id == null
                              ? null
                              : mesinData
                                    .where((m) => m.idMesin == id)
                                    .firstOrNull;
                        });
                        _loadProduksiPage();
                      },
                    );
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadProduksiPage,
                        child: ProductionProduksiList<SpannerProduction>(
                          items: _produksiItems,
                          dataOf: _toRowData,
                          isLoading: _produksiLoading,
                          isFetchingMore: _produksiFetchingMore,
                          scrollController: _produksiScrollCtl,
                          showMesin: _filterIdMesin == null,
                          onTap: (row) async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SpannerProductionInputScreen(
                                  noProduksi: row.noProduksi,
                                  isLocked: row.isLocked,
                                  lastClosedDate: row.lastClosedDate,
                                  idMesin: row.idMesin,
                                  namaJenis: row.outputJenisNama,
                                  outputJenisId: row.outputJenisId,
                                  tglProduksi: row.tglProduksi,
                                  shift: row.shift,
                                  hourStart: row.hourStart,
                                  hourEnd: row.hourEnd,
                                ),
                              ),
                            );
                            if (mounted) _refreshAll();
                          },
                          onEdit: (row) async {
                            await showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => ChangeNotifierProvider.value(
                                value: _editVmPool,
                                child: SpannerProductionFormDialog(header: row),
                              ),
                            );
                            if (mounted) _refreshAll();
                          },
                          onDelete: (row) async {
                            final screenCtx = context;
                            await showDialog<void>(
                              context: screenCtx,
                              barrierDismissible: false,
                              builder: (ctx) => SpannerProductionDeleteDialog(
                                header: row,
                                onConfirm: () async {
                                  final success = await _editVmPool
                                      .deleteProduksi(row.noProduksi);
                                  final errMsg = _editVmPool.saveError;
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  if (!screenCtx.mounted) return;
                                  if (success) {
                                    showDialog(
                                      context: screenCtx,
                                      builder: (_) => SuccessStatusDialog(
                                        title: 'Berhasil Menghapus',
                                        message:
                                            'No. Produksi ${row.noProduksi} berhasil dihapus.',
                                      ),
                                    );
                                  } else {
                                    showDialog(
                                      context: screenCtx,
                                      builder: (_) => ErrorStatusDialog(
                                        title: 'Gagal Menghapus!',
                                        message:
                                            errMsg ?? 'Gagal menghapus data',
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
                                builder: (_) => SpannerProductionInputScreen(
                                  noProduksi: row.noProduksi,
                                  isLocked: row.isLocked,
                                  lastClosedDate: row.lastClosedDate,
                                  idMesin: row.idMesin,
                                  namaJenis: row.outputJenisNama,
                                  outputJenisId: row.outputJenisId,
                                  tglProduksi: row.tglProduksi,
                                  shift: row.shift,
                                  hourStart: row.hourStart,
                                  hourEnd: row.hourEnd,
                                ),
                              ),
                            );
                            if (mounted) _refreshAll();
                          },
                        ),
                      ),
                      if (_selectedMesinInfo != null)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton.small(
                            heroTag: 'fab_add_spanner',
                            onPressed: _selectedMesinInfo == null
                                ? null
                                : () => _openCreateDialog(
                                    mesin: _selectedMesinInfo!,
                                  ),
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            tooltip: 'Tambah Produksi',
                            child: const Icon(Icons.add),
                          ),
                        ),
                    ],
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
