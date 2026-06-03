import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../shift/repository/shift_repository.dart';
import '../../../../features/mesin/model/mesin_model.dart';
import '../../shared/widgets/mesin_section_header.dart';
import '../model/gilingan_production_model.dart';
import '../repository/gilingan_production_repository.dart';
import '../view_model/gilingan_production_view_model.dart';
import '../widgets/gilingan_mesin_card.dart';
import '../widgets/gilingan_produksi_list.dart';
import '../widgets/gilingan_production_delete_dialog.dart';
import '../widgets/gilingan_production_form_dialog.dart';
import '../widgets/gilingan_riwayat_section_header.dart';
import 'gilingan_production_input_screen.dart';

class GilinganProductionMesinScreen extends StatefulWidget {
  const GilinganProductionMesinScreen({super.key});

  @override
  State<GilinganProductionMesinScreen> createState() =>
      _GilinganProductionMesinScreenState();
}

class _GilinganProductionMesinScreenState
    extends State<GilinganProductionMesinScreen> {
  final _repo = GilinganProductionRepository();
  late final GilinganProductionViewModel _editVmPool;

  Future<List<GilinganMesinInfo>> _mesinFuture = Future.value([]);

  final List<GilinganProduction> _produksiItems = [];
  bool _produksiLoading = false;
  bool _produksiFetchingMore = false;
  bool _produksiHasMore = true;
  int _produksiPage = 1;
  static const _pageSize = 30;
  final _produksiScrollCtl = ScrollController();
  int? _filterIdMesin;
  GilinganMesinInfo? _selectedMesinInfo;

  @override
  void initState() {
    super.initState();
    _editVmPool = GilinganProductionViewModel(repository: _repo);
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
    final future = _repo.fetchGilinganMesin();
    if (!mounted) return;
    setState(() {
      _mesinFuture = future;
    });
    try {
      await future;
    } catch (_) {}
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
      final res = await _repo.fetchAll(
        page: 1,
        pageSize: _pageSize,
        idMesin: _filterIdMesin,
      );
      if (!mounted) return;
      final newItems = res['items'] as List<GilinganProduction>;
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
      final res = await _repo.fetchAll(
        page: nextPage,
        pageSize: _pageSize,
        idMesin: _filterIdMesin,
      );
      if (!mounted) return;
      final newItems = res['items'] as List<GilinganProduction>;
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

  Future<void> _openCreateDialog({required GilinganMesinInfo mesin}) async {
    if (!mounted) return;

    final mstMesin = MstMesin(
      idMesin: mesin.idMesin,
      namaMesin: mesin.namaMesin,
      bagian: mesin.bagian,
      enable: true,
    );

    final defaultShift = await ShiftRepository.fetchCurrentShift();
    if (!mounted) return;

    final created = await showDialog<GilinganProduction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: _editVmPool,
        child: GilinganProductionFormDialog(
          initialMesin: mstMesin,
          initialDate: DateTime.now(),
          initialShift: defaultShift?.shift,
          initialHourStart: defaultShift?.hourStart,
          initialHourEnd: defaultShift?.hourEnd,
          lockShiftFields: defaultShift != null,
          onSave: (p) => Navigator.of(context).pop(p),
        ),
      ),
    );

    if (!mounted) return;
    if (created != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GilinganProductionInputScreen(
            noProduksi: created.noProduksi,
            isLocked: created.isLocked,
            lastClosedDate: created.lastClosedDate,
            outputJenisId: created.outputJenisId,
            namaJenis: created.outputJenisNama,
            idMesin: created.idMesin,
            tglProduksi: created.tglProduksi,
            shift: created.shift,
            hourStart: created.hourStart,
            hourEnd: created.hourEnd,
          ),
        ),
      );
      if (!mounted) return;
    }
    _refreshAll();
  }

  Future<void> _openBackdateDialog(GilinganMesinInfo mesin) async {
    if (!mounted) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final mstMesin = MstMesin(
      idMesin: mesin.idMesin,
      namaMesin: mesin.namaMesin,
      bagian: mesin.bagian,
      enable: true,
    );
    final editVm = GilinganProductionViewModel(repository: _repo);
    try {
      final created = await showDialog<GilinganProduction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: editVm,
          child: GilinganProductionFormDialog(
            initialMesin: mstMesin,
            initialDate: yesterday,
            lockShiftFields: false,
            isBackdateInput: true,
            onSave: (p) => Navigator.of(context).pop(p),
          ),
        ),
      );
      if (!mounted) return;
      if (created != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GilinganProductionInputScreen(
              noProduksi: created.noProduksi,
              isLocked: created.isLocked,
              lastClosedDate: created.lastClosedDate,
              outputJenisId: created.outputJenisId,
              namaJenis: created.outputJenisNama,
              idMesin: created.idMesin,
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

  Future<void> _onMesinTap(GilinganMesinInfo mesin) async {
    if (!mounted) return;

    if (!mesin.isActive) {
      await _openCreateDialog(mesin: mesin);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GilinganProductionInputScreen(
          noProduksi: mesin.noProduksi!,
          isLocked: false,
          lastClosedDate: null,
          outputJenisId: mesin.outputJenisId,
          namaJenis: mesin.outputJenisNama,
          idMesin: mesin.idMesin,
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
                FutureBuilder<List<GilinganMesinInfo>>(
                  future: _mesinFuture,
                  builder: (context, snapshot) {
                    final allMesin = snapshot.data ?? [];
                    final activeCount = allMesin
                        .where((m) => m.isActive)
                        .length;
                    final inactiveCount = allMesin.length - activeCount;
                    return MesinSectionHeader(
                      title: 'Status Mesin Gilingan',
                      onRefresh: _refreshAll,
                      activeCount: activeCount,
                      inactiveCount: inactiveCount,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
                Expanded(
                  child: FutureBuilder<List<GilinganMesinInfo>>(
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
                          return GilinganMesinCard(
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

          // ── DIVIDER ──────────────────────────────────────────────
          const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),

          // ── RIGHT: riwayat produksi (2/5) ────────────────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<GilinganMesinInfo>>(
                  future: _mesinFuture,
                  builder: (context, snapshot) {
                    return GilinganRiwayatSectionHeader(
                      mesinList: snapshot.data ?? [],
                      selectedIdMesin: _filterIdMesin,
                      onFilterChanged: (id) {
                        final mesinList = snapshot.data ?? [];
                        setState(() {
                          _filterIdMesin = id;
                          _selectedMesinInfo = id == null
                              ? null
                              : mesinList
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
                        child: GilinganProduksiList(
                          items: _produksiItems,
                          isLoading: _produksiLoading,
                          isFetchingMore: _produksiFetchingMore,
                          scrollController: _produksiScrollCtl,
                          filterIdMesin: _filterIdMesin,
                          onTap: (row) async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GilinganProductionInputScreen(
                                  noProduksi: row.noProduksi,
                                  isLocked: row.isLocked,
                                  lastClosedDate: row.lastClosedDate,
                                  outputJenisId: row.outputJenisId,
                                  namaJenis: row.outputJenisNama,
                                  idMesin: row.idMesin,
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
                                child: GilinganProductionFormDialog(
                                  header: row,
                                ),
                              ),
                            );
                            if (mounted) _refreshAll();
                          },
                          onDelete: (row) async {
                            final screenCtx = context;
                            await showDialog<void>(
                              context: screenCtx,
                              barrierDismissible: false,
                              builder: (ctx) => GilinganProductionDeleteDialog(
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
                                builder: (_) => GilinganProductionInputScreen(
                                  noProduksi: row.noProduksi,
                                  isLocked: row.isLocked,
                                  lastClosedDate: row.lastClosedDate,
                                  outputJenisId: row.outputJenisId,
                                  namaJenis: row.outputJenisNama,
                                  idMesin: row.idMesin,
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
                            heroTag: 'fab_backdate_gilingan',
                            onPressed: () =>
                                _openBackdateDialog(_selectedMesinInfo!),
                            backgroundColor: const Color(0xFF0277BD),
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
