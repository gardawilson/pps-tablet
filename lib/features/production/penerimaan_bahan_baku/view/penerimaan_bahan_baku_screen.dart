// lib/features/production/penerimaan_bahan_baku/view/penerimaan_bahan_baku_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../../shared/models/bahan_baku_proses_label.dart';
import '../../shared/models/stok_bahan_baku_item.dart';
import '../../shared/repository/stok_bahan_baku_pakai_repository.dart';
import '../../shared/repository/stok_bahan_baku_repository.dart';
import '../../shared/widgets/mesin_section_header.dart';
import '../../shared/widgets/production_mesin_card.dart';
import '../../shared/widgets/production_overlay_drawer.dart';
import '../../shared/widgets/production_produksi_list.dart';
import '../../shared/widgets/production_riwayat_header.dart';
import '../../shared/widgets/sidebar_tab_switcher.dart';
import '../../shared/widgets/stok_item_section.dart';
import '../model/penerimaan_bahan_baku_model.dart';
import '../model/tim_penerimaan_bahan_baku_model.dart';
import '../repository/penerimaan_bahan_baku_repository.dart';
import '../widgets/penerimaan_bahan_baku_delete_dialog.dart';
import '../widgets/penerimaan_bahan_baku_header_form_dialog.dart';
import 'penerimaan_bahan_baku_input_screen.dart';
import 'penerimaan_bahan_baku_label_list_screen.dart';

/// Layar utama modul Penerimaan Bahan Baku — 1:1 mengikuti pola
/// `WashingProductionMesinScreen`: grid status tim (analog mesin) + panel
/// riwayat/stok yang bisa di-slide dari kanan. Tim dianggap "aktif" kalau
/// sudah punya `NoPenerimaan` untuk HARI INI (lihat
/// `TimPenerimaanInfo.isActive`, sumbernya endpoint
/// `GET /api/penerimaan-bahan-baku/tim-status`, analog
/// `GET /api/mst-mesin/washing`). Tap tim nonaktif → dialog header ringkas
/// (Tanggal, Shift, Jam, Regu/Operator — atribut yang melekat pada tim) →
/// screen input penuh (create label) untuk pallet/sak + Supplier/No Plat per
/// section — HANYA dipakai sekali saat header baru pertama dibuat. Tap tim
/// AKTIF / baris riwayat → `PenerimaanBahanBakuLabelListScreen`, list label
/// (NoBahanBaku + NoPallet) yang sudah dibuat untuk NoPenerimaan itu — tidak
/// lagi masuk ke screen generate label.
///
/// Menu "PBB Pakai" & "PBB Proses" sudah digabung menjadi satu screen ini;
/// kategori (Bahan Baku Pakai / Bahan Baku Proses) kini dipilih di level
/// section pada form create (lihat `PenerimaanBahanBakuCreateDialog`) dan di
/// level chip pada tab Stok Item, bukan lagi di level screen/menu.
class PenerimaanBahanBakuScreen extends StatefulWidget {
  const PenerimaanBahanBakuScreen({super.key});

  @override
  State<PenerimaanBahanBakuScreen> createState() =>
      _PenerimaanBahanBakuScreenState();
}

class _PenerimaanBahanBakuScreenState extends State<PenerimaanBahanBakuScreen> {
  late final PenerimaanBahanBakuRepository _repo;
  final _stokProsesRepo = StokBahanBakuRepository();
  final _stokPakaiRepo = StokBahanBakuPakaiRepository();
  final _stokSectionController = StokItemSectionController();

  Future<List<TimPenerimaanInfo>> _timFuture = Future.value(
    <TimPenerimaanInfo>[],
  );

  final List<PenerimaanBahanBaku> _items = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const _pageSize = 30;
  final _scrollCtl = ScrollController();
  int? _filterIdTim;
  bool _isSidebarExpanded = false;
  int _sidebarTab = 0; // 0 = Riwayat Penerimaan, 1 = Stok Item

  @override
  void initState() {
    super.initState();
    _repo = PenerimaanBahanBakuRepository(api: context.read<ApiClient>());
    _loadTim();
    _loadPage();
    _scrollCtl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────

  Future<void> _loadTim() async {
    final future = _repo.fetchTimStatus();
    if (mounted) setState(() => _timFuture = future);
  }

  void _onScroll() {
    if (_scrollCtl.position.pixels >=
            _scrollCtl.position.maxScrollExtent - 100 &&
        !_isFetchingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadPage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _items.clear();
      _page = 1;
      _hasMore = true;
    });
    try {
      final res = await _repo.fetchAll(page: 1, pageSize: _pageSize);
      if (!mounted) return;
      var newItems = res['items'] as List<PenerimaanBahanBaku>;
      if (_filterIdTim != null) {
        newItems = newItems.where((e) => e.idTim == _filterIdTim).toList();
      }
      final totalPages = (res['totalPages'] as int?) ?? 1;
      setState(() {
        _items.addAll(newItems);
        _hasMore = 1 < totalPages;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _isFetchingMore || !_hasMore) return;
    setState(() => _isFetchingMore = true);
    try {
      final nextPage = _page + 1;
      final res = await _repo.fetchAll(page: nextPage, pageSize: _pageSize);
      if (!mounted) return;
      var newItems = res['items'] as List<PenerimaanBahanBaku>;
      if (_filterIdTim != null) {
        newItems = newItems.where((e) => e.idTim == _filterIdTim).toList();
      }
      final totalPages = (res['totalPages'] as int?) ?? 1;
      setState(() {
        _items.addAll(newItems);
        _page = nextPage;
        _hasMore = nextPage < totalPages;
        _isFetchingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  void _refreshAll() {
    _loadTim();
    _loadPage();
    _stokSectionController.refreshAll();
  }

  // ── Card / row data converters ───────────────────────────────────────

  static MesinCardData _toCardData(TimPenerimaanInfo tim) {
    String? shiftTimeText;
    if (tim.isActive) {
      final parts = <String>[];
      if (tim.shift != null) parts.add('Shift ${tim.shift}');
      parts.add('${tim.hourStart ?? '--:--'} – ${tim.hourEnd ?? '--:--'}');
      shiftTimeText = parts.join('  |  ');
    }
    return MesinCardData(
      namaMesin: tim.namaTim,
      isActive: tim.isActive,
      shiftTimeText: shiftTimeText,
      namaOperators: tim.namaOperators,
    );
  }

  static ProduksiRowData _toRowData(PenerimaanBahanBaku row) {
    return ProduksiRowData(
      tglProduksi: row.tglPenerimaan,
      hourStart: row.hourStart,
      hourEnd: row.hourEnd,
      shift: row.shift,
      isLocked: false,
      namaMesin: row.namaTim,
      noProduksi: row.noPenerimaan,
    );
  }

  // ── Navigation helpers ───────────────────────────────────────────────

  Future<void> _onTimTap(TimPenerimaanInfo tim) async {
    if (!mounted) return;

    if (!tim.isActive) {
      if (!tim.aktif) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tim ${tim.namaTim} sedang tidak aktif')),
        );
        return;
      }
      final headerResult = await showDialog<PenerimaanBahanBakuHeaderResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PenerimaanBahanBakuCreateDialog(tim: tim),
      );
      if (!mounted) return;
      if (headerResult == null) return;

      // Header sudah dibuat di database begitu dialog di atas sukses
      // (fase 1) — refresh grid tim supaya kartu ini langsung berubah
      // status "aktif" walau user belum sempat menambah pallet apapun.
      _refreshAll();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PenerimaanBahanBakuInputScreen(tim: tim, header: headerResult),
        ),
      );
      if (!mounted) return;
      _refreshAll();
      return;
    }

    // Tim aktif (sudah punya header hari ini) → buka list label yang
    // sudah dibuat untuk NoPenerimaan itu (bukan screen generate label
    // lagi). Layar input (create label) hanya dipakai sekali di atas,
    // begitu header baru pertama kali dibuat.
    await _openLabelList(tim.noPenerimaan!);
  }

  Future<void> _openLabelList(String noPenerimaan) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PenerimaanBahanBakuLabelListScreen(noPenerimaan: noPenerimaan),
      ),
    );
    if (!mounted) return;
    _refreshAll();
  }

  Future<void> _onRowTap(PenerimaanBahanBaku row) async {
    await _openLabelList(row.noPenerimaan);
  }

  Future<void> _onRowDelete(PenerimaanBahanBaku row) async {
    final screenCtx = context;
    await showDialog<void>(
      context: screenCtx,
      barrierDismissible: false,
      builder: (ctx) => PenerimaanBahanBakuDeleteDialog(
        header: row,
        onConfirm: () async {
          bool success = false;
          String? errMsg;
          try {
            await _repo.delete(row.noPenerimaan);
            success = true;
          } catch (e) {
            errMsg = e.toString();
          }
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (!screenCtx.mounted) return;
          if (success) {
            showDialog(
              context: screenCtx,
              builder: (_) => SuccessStatusDialog(
                title: 'Berhasil Menghapus',
                message: 'Penerimaan ${row.noPenerimaan} berhasil dihapus.',
              ),
            );
          } else {
            showDialog(
              context: screenCtx,
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
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (_, c) => Stack(
          children: [
            // ── Grid tim (selalu full width) ──────────────────────────
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<List<TimPenerimaanInfo>>(
                    future: _timFuture,
                    builder: (context, snapshot) {
                      final allTim = snapshot.data ?? [];
                      final activeCount = allTim
                          .where((m) => m.isActive)
                          .length;
                      final inactiveCount = allTim.length - activeCount;
                      return MesinSectionHeader(
                        title: 'Penerimaan Bahan Baku',
                        activeCount: activeCount,
                        inactiveCount: inactiveCount,
                        isLoading:
                            snapshot.connectionState == ConnectionState.waiting,
                      );
                    },
                  ),
                  Expanded(
                    child: FutureBuilder<List<TimPenerimaanInfo>>(
                      future: _timFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Gagal memuat tim\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        }
                        final allTim = snapshot.data ?? [];
                        if (allTim.isEmpty) {
                          return Center(
                            child: Text(
                              'Belum ada tim penerimaan bahan baku',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = (constraints.maxWidth / 150)
                                .floor()
                                .clamp(2, 6);
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    mainAxisExtent: 110,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: allTim.length,
                              itemBuilder: (context, index) {
                                final tim = allTim[index];
                                return ProductionMesinCard(
                                  data: _toCardData(tim),
                                  onTap: () => _onTimTap(tim),
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

            // ── Overlay drawer: Riwayat Penerimaan / Stok Item ─────────
            Positioned.fill(
              child: ProductionOverlayDrawer(
                isOpen: _isSidebarExpanded,
                onClose: () => setState(() => _isSidebarExpanded = false),
                onOpen: () => setState(() => _isSidebarExpanded = true),
                width: c.maxWidth * 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SidebarTabSwitcher(
                      tabs: const [
                        SidebarTabItem(
                          label: 'Riwayat Penerimaan',
                          icon: Icons.history_rounded,
                        ),
                        SidebarTabItem(
                          label: 'Stok Item',
                          icon: Icons.inventory_2_rounded,
                        ),
                      ],
                      selectedIndex: _sidebarTab,
                      onSelected: (i) => setState(() => _sidebarTab = i),
                    ),
                    Expanded(
                      child: _sidebarTab == 0
                          ? _buildRiwayatContent()
                          : _buildStokItemContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStokItemContent() {
    return StokItemSection(
      controller: _stokSectionController,
      sources: [
        TypedStokItemSource<StokBahanBakuItem, BahanBakuProsesLabel>(
          label: 'Bahan Baku Pakai',
          fetchStok: _stokPakaiRepo.fetchStok,
          fetchLabel: (item) => _stokPakaiRepo.fetchLabel(item.idBB),
          showSakColumn: false,
          oldestDateOf: (item) => item.dateCreateTertua,
        ),
        TypedStokItemSource<StokBahanBakuItem, BahanBakuProsesLabel>(
          label: 'Bahan Baku Proses',
          fetchStok: _stokProsesRepo.fetchStok,
          fetchLabel: (item) => _stokProsesRepo.fetchLabel(item.idBB),
          showSakColumn: false,
          oldestDateOf: (item) => item.dateCreateTertua,
        ),
      ],
    );
  }

  Widget _buildRiwayatContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<TimPenerimaanInfo>>(
          future: _timFuture,
          builder: (context, snapshot) {
            return ProductionRiwayatHeader(
              showTitle: false,
              mesinList: (snapshot.data ?? [])
                  .map(
                    (t) =>
                        MesinFilterItem(idMesin: t.idTim, namaMesin: t.namaTim),
                  )
                  .toList(),
              selectedIdMesin: _filterIdTim,
              onFilterChanged: (id) {
                setState(() => _filterIdTim = id);
                _loadPage();
              },
            );
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPage,
            child: ProductionProduksiList<PenerimaanBahanBaku>(
              items: _items,
              dataOf: _toRowData,
              isLoading: _isLoading,
              isFetchingMore: _isFetchingMore,
              scrollController: _scrollCtl,
              showMesin: _filterIdTim == null,
              onTap: _onRowTap,
              onEdit: (row) async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit belum didukung untuk data penerimaan'),
                  ),
                );
              },
              onDelete: _onRowDelete,
            ),
          ),
        ),
      ],
    );
  }
}
