// lib/features/production/penerimaan_bahan_baku/view/penerimaan_bahan_baku_label_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../core/services/label_print_sync_queue.dart';
import '../../../label/bahan_baku/model/bahan_baku_header.dart';
import '../../../label/bahan_baku/model/bahan_baku_pallet.dart';
import '../../../label/bahan_baku/repository/bahan_baku_repository.dart';
import '../../../label/bahan_baku/view_model/bahan_baku_view_model.dart';
import '../../../label/bahan_baku/widgets/bahan_baku_action_bar.dart';
import '../../../label/bahan_baku/widgets/bahan_baku_qc_dialog.dart';
import '../model/penerimaan_kategori.dart';
import '../widgets/pbb_header_list.dart';
import '../widgets/pbb_pallet_list.dart';
import '../widgets/pbb_sak_list.dart';

/// Layar label bahan baku khusus modul Penerimaan Bahan Baku — data & aksi
/// (search, print, QC) identik dengan `BahanBakuScreen` (dipakai
/// `BahanBakuViewModel` yang sama, difilter prefix sesuai [kategori]:
/// "A." untuk Proses, "AB." untuk Pakai), tapi tampilan dibuat kartu besar
/// yang lebih ramah sentuh untuk tablet dibanding tabel padat aslinya.
class PenerimaanBahanBakuLabelScreen extends StatelessWidget {
  final PenerimaanKategori kategori;

  const PenerimaanBahanBakuLabelScreen({super.key, required this.kategori});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BahanBakuViewModel>(
      create: (ctx) => BahanBakuViewModel(
        repository: BahanBakuRepository(api: ctx.read<ApiClient>()),
        prefix: kategori.prefixLabel,
      ),
      child: const _PenerimaanBahanBakuLabelBody(),
    );
  }
}

class _PenerimaanBahanBakuLabelBody extends StatefulWidget {
  const _PenerimaanBahanBakuLabelBody();

  @override
  State<_PenerimaanBahanBakuLabelBody> createState() =>
      _PenerimaanBahanBakuLabelBodyState();
}

class _PenerimaanBahanBakuLabelBodyState
    extends State<_PenerimaanBahanBakuLabelBody> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _palletScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();

  bool _isLoadingMore = false;
  Timer? _debounce;
  LabelPrintSyncQueue? _syncQueue;
  int _lastPendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BahanBakuViewModel>().fetchBahanBakuHeaders();
      context.read<BahanBakuViewModel>().resetForScreen();
      _syncQueue = context.read<LabelPrintSyncQueue>();
      _lastPendingCount = _syncQueue!.pendingCountFor('bahan_baku');
      _syncQueue!.addListener(_onSyncQueueChanged);
    });
    _headerScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _syncQueue?.removeListener(_onSyncQueueChanged);
    _headerScrollController.dispose();
    _palletScrollController.dispose();
    _detailScrollController.dispose();
    searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSyncQueueChanged() {
    if (!mounted || _syncQueue == null) return;
    final now = _syncQueue!.pendingCountFor('bahan_baku');

    if (_lastPendingCount == 0 && now > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sinkronisasi print bahan baku tertunda ($now)')),
      );
    } else if (_lastPendingCount > 0 && now == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sinkronisasi print bahan baku selesai')),
      );
    }

    _lastPendingCount = now;
  }

  void _onScroll() {
    final vm = context.read<BahanBakuViewModel>();
    if (_headerScrollController.position.pixels >=
        _headerScrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingMore && vm.hasMore) {
        _isLoadingMore = true;
        vm.loadMore().then((_) {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<BahanBakuViewModel>().fetchBahanBakuHeaders(search: query);
      if (_headerScrollController.hasClients) _headerScrollController.jumpTo(0);
    });
  }

  void _onHeaderTap(BahanBakuHeader header) {
    final vm = context.read<BahanBakuViewModel>();
    vm.fetchPallets(header.noBahanBaku);
    if (_palletScrollController.hasClients) _palletScrollController.jumpTo(0);
  }

  void _onPalletTap(BahanBakuPallet pallet) {
    final vm = context.read<BahanBakuViewModel>();
    final noBahanBaku = vm.currentNoBahanBaku;
    if (noBahanBaku == null) return;

    vm.fetchPalletDetails(noBahanBaku: noBahanBaku, noPallet: pallet.noPallet);
    if (_detailScrollController.hasClients) _detailScrollController.jumpTo(0);
  }

  Future<void> _onInputQcTap(BahanBakuPallet pallet) async {
    final vm = context.read<BahanBakuViewModel>();
    final noBahanBaku = vm.currentNoBahanBaku;
    if (noBahanBaku == null || noBahanBaku.isEmpty) return;

    final qc = await showDialog<BahanBakuQcResult>(
      context: context,
      builder: (_) => BahanBakuQcDialog(pallet: pallet),
    );

    if (!mounted || qc == null) return;

    DialogService.instance.showLoading(message: 'Menyimpan QC ${pallet.noPallet}...');

    final res = await vm.updatePalletQc(
      noBahanBaku: noBahanBaku,
      pallet: pallet,
      tenggelam: qc.tenggelam,
      density1: qc.density1,
      density2: qc.density2,
      density3: qc.density3,
    );

    DialogService.instance.hideLoading();
    if (!mounted) return;

    if (res != null) {
      await DialogService.instance.showSuccess(
        title: 'QC Tersimpan',
        message: 'Nilai QC untuk pallet ${pallet.noPallet} berhasil diperbarui.',
      );
    } else {
      await DialogService.instance.showError(
        title: 'Gagal',
        message: vm.errorMessage.isNotEmpty
            ? vm.errorMessage
            : 'Tidak dapat memperbarui data QC pallet.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: _Pane(
                child: Column(
                  children: [
                    Consumer<LabelPrintSyncQueue>(
                      builder: (_, syncQueue, __) {
                        final pending = syncQueue.pendingCountFor('bahan_baku');
                        if (pending <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Tooltip(
                              message: 'Sinkronisasi print bahan baku tertunda ($pending)',
                              child: const Icon(Icons.sync, color: Color(0xFFFFE082)),
                            ),
                          ),
                        );
                      },
                    ),
                    Consumer<BahanBakuViewModel>(
                      builder: (_, vm, __) => BahanBakuActionBar(
                        controller: searchCtrl,
                        onSearchChanged: _onSearchChanged,
                        onClear: () {
                          searchCtrl.clear();
                          vm.fetchBahanBakuHeaders(search: '');
                        },
                        includeUsed: vm.includeUsed,
                        onIncludeUsedChanged: vm.setIncludeUsed,
                      ),
                    ),
                    Expanded(
                      child: PbbHeaderList(
                        scrollController: _headerScrollController,
                        onItemTap: _onHeaderTap,
                        onRefresh: () => context
                            .read<BahanBakuViewModel>()
                            .fetchBahanBakuHeaders(search: searchCtrl.text.trim()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: _Pane(
                child: PbbPalletList(
                  scrollController: _palletScrollController,
                  onPalletTap: _onPalletTap,
                  onInputQcTap: _onInputQcTap,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _Pane(
                child: PbbSakList(scrollController: _detailScrollController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  final Widget child;
  const _Pane({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14091E42), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
