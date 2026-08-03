import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/confirm_dialog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/view/app_shell.dart';
import '../../../core/view_model/permission_view_model.dart';
import '../model/so_v2_access_user.dart';
import '../model/so_v2_complete_summary.dart';
import '../model/so_v2_label_group.dart';
import '../model/so_v2_lokasi.dart';
import '../repository/so_v2_repository.dart';
import '../repository/so_v2_user_lokasi_access_repository.dart';
import '../view_model/so_v2_blok_list_view_model.dart';
import '../view_model/so_v2_label_list_view_model.dart';
import '../view_model/so_v2_lokasi_list_view_model.dart';
import '../view_model/so_v2_socket_manager.dart';
import '../utils/so_v2_number_format.dart';
import '../widgets/so_v2_complete_summary_dialog.dart';
import '../widgets/so_v2_label_group_tile.dart';
import '../widgets/so_v2_scan_summary_dialog.dart';
import '../widgets/so_v2_worker_picker_dialog.dart';

const _kAccessManagePermission = 'stockopname:create';

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);
const _kWarning = Color(0xFFB45309);
const _kWarningBg = Color(0xFFFFF7ED);
const _kSuccessBg = Color(0xFFE9F6EF);

/// Screen gabungan: panel blok, panel lokasi (dalam blok terpilih), panel
/// label (dalam lokasi terpilih). Tidak memakai AppBar sendiri karena sudah
/// ada compact app bar global dari AppShell.
class SoV2DetailScreen extends StatefulWidget {
  final String stockOpnameNo;
  final String categoryCode;
  final String categoryName;

  const SoV2DetailScreen({
    super.key,
    required this.stockOpnameNo,
    required this.categoryCode,
    required this.categoryName,
  });

  @override
  State<SoV2DetailScreen> createState() => _SoV2DetailScreenState();
}

class _SoV2DetailScreenState extends State<SoV2DetailScreen> {
  final _repo = SoV2Repository();
  final _accessRepo = SoV2UserLokasiAccessRepository();
  late final SoV2BlokListViewModel _blokVm;
  String? _selectedBlok;
  SoV2LokasiListViewModel? _lokasiVm;
  SoV2Lokasi? _selectedLokasi;
  SoV2LabelListViewModel? _labelVm;
  final _searchCtl = TextEditingController();
  bool _completing = false;
  bool _loadingScanSummary = false;
  bool _searchOpen = false;
  final Set<int> _busyLocationIds = {};
  List<BreadcrumbSegment> _prevBreadcrumb = [];
  VoidCallback? _unsubscribeHasilInserted;

  /// Furniturewip memakai UOM pcs, bukan kg seperti kategori lain.
  String get _uom => widget.categoryCode == 'furniturewip' ? 'pcs' : 'kg';

  @override
  void initState() {
    super.initState();
    _blokVm = SoV2BlokListViewModel(stockOpnameNo: widget.stockOpnameNo);
    _blokVm.load();
    final socketVm = context.read<SoV2SocketManager>();
    socketVm.joinStockOpname(widget.stockOpnameNo);
    _unsubscribeHasilInserted = socketVm.addHasilInsertedListener(
      _onHasilInserted,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prevBreadcrumb = List<BreadcrumbSegment>.from(AppShell.breadcrumb.value);
      AppShell.breadcrumb.value = [
        ..._prevBreadcrumb.map(
          (s) => BreadcrumbSegment(
            s.label,
            onTap: () {
              AppShell.breadcrumb.value = _prevBreadcrumb;
              AppShell.shellNavigatorKey.currentState?.pop();
            },
          ),
        ),
        BreadcrumbSegment(widget.categoryName),
      ];
    });
  }

  @override
  void dispose() {
    final prev = _prevBreadcrumb;
    final categoryName = widget.categoryName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = AppShell.breadcrumb.value;
      if (current.isNotEmpty && current.last.label == categoryName) {
        AppShell.breadcrumb.value = prev;
      }
    });
    _unsubscribeHasilInserted?.call();
    context.read<SoV2SocketManager>().leaveStockOpname(widget.stockOpnameNo);
    _blokVm.dispose();
    _lokasiVm?.dispose();
    _labelVm?.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  /// Realtime handler: setiap ada scan hasil baru masuk untuk SO ini (dari
  /// device manapun), patch panel blok/lokasi/label secara optimistik
  /// (tanpa refetch ke API) supaya terasa realtime — bukan seperti polling
  /// dengan loading indicator berkedip tiap event masuk. Fallback ke reload
  /// penuh hanya kalau blok/lokasinya belum pernah termuat sama sekali.
  ///
  /// Panel blok/lokasi/label selalu difilter berdasarkan lokasi ACUAN milik
  /// label (referenceBlok/referenceLocationId) — bukan lokasi hasil scan
  /// (scannedBlok/scannedLocationId), yang bisa berbeda kalau ada
  /// isLocationMismatch. Cocokkan ke field acuan supaya centang label tetap
  /// update walau scan dilakukan di lokasi lain.
  void _onHasilInserted(SoV2HasilInsertedEvent event) {
    if (!mounted) return;
    if (event.stockOpnameNo != widget.stockOpnameNo) return;
    final referenceBlok = event.referenceBlok;
    if (referenceBlok == null) return;

    // furniturewip pakai UOM pcs (pieceCount), kategori lain pakai kg (weight).
    final weightDelta = widget.categoryCode == 'furniturewip'
        ? (event.pieceCount?.toDouble() ?? 0)
        : (event.weight ?? 0);

    final blokPatched = _blokVm.applyScan(
      blok: referenceBlok,
      weightDelta: weightDelta,
    );
    if (!blokPatched) _blokVm.load();

    final lokasiVm = _lokasiVm;
    final referenceLocationId = event.referenceLocationId;
    if (lokasiVm != null &&
        lokasiVm.blok == referenceBlok &&
        referenceLocationId != null) {
      final lokasiPatched = lokasiVm.applyScan(
        locationId: referenceLocationId,
        weightDelta: weightDelta,
      );
      if (!lokasiPatched) lokasiVm.load();
    }

    final labelVm = _labelVm;
    final selectedLokasi = _selectedLokasi;
    if (labelVm != null &&
        selectedLokasi != null &&
        labelVm.blok == referenceBlok &&
        selectedLokasi.locationId == referenceLocationId) {
      labelVm.applyScan(labelNo: event.labelNo, weightDelta: weightDelta);
    }
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
      _searchOpen = false;
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
      _searchOpen = false;
      _labelVm = SoV2LabelListViewModel(
        stockOpnameNo: widget.stockOpnameNo,
        blok: _selectedBlok!,
        locationId: lokasi.locationId,
        categoryCode: widget.categoryCode,
      );
    });
  }

  Future<void> _markComplete() async {
    setState(() => _completing = true);

    final summary = await _fetchSummaryForComplete();
    if (!mounted) return;

    final bool? confirmed;
    if (summary != null) {
      confirmed = await showSoV2CompleteSummaryDialog(
        context,
        summary: summary,
        weightUnit: _uom,
      );
    } else {
      // Gagal ambil ringkasan (mis. server error) — tetap kasih jalur
      // konfirmasi fallback biar supervisor tidak buntu, cuma tanpa detail.
      confirmed = await showDialog<bool>(
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
    }

    if (confirmed != true) {
      if (mounted) setState(() => _completing = false);
      return;
    }

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

  Future<SoV2CompleteSummary?> _fetchSummaryForComplete() async {
    try {
      return await _repo.fetchCompleteSummary(widget.stockOpnameNo);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openScanSummary() async {
    if (_loadingScanSummary) return;
    setState(() => _loadingScanSummary = true);
    try {
      final summary = await _repo.fetchScanSummary(widget.stockOpnameNo);
      if (!mounted) return;
      final totalLabelCount = _blokVm.items.fold<int>(
        0,
        (sum, b) => sum + b.labelCount,
      );
      await showSoV2ScanSummaryDialog(
        context,
        summary: summary,
        totalLabelCount: totalLabelCount,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat ringkasan scan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingScanSummary = false);
    }
  }

  void _toggleSearch(SoV2LabelListViewModel vm) {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchCtl.clear();
        vm.clearSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 200, child: _buildBlokPanel()),
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
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.stockOpnameNo,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (vm.isComplete)
                        Tooltip(
                          message: vm.completedAt != null
                              ? 'Selesai ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(vm.completedAt!.toLocal())}'
                              : 'Sudah ditandai selesai',
                          // Sengaja TANPA background pill/InkWell — kalau
                          // dibikin mirip tombol, user sulit bedain ini
                          // status (non-interaktif) vs tombol "Tandai
                          // Selesai" (interaktif) di state sebaliknya.
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade700,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
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
                      if (vm.isComplete) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: _kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: _loadingScanSummary
                                  ? null
                                  : _openScanSummary,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_loadingScanSummary)
                                      const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _kPrimary,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.leaderboard_rounded,
                                        size: 15,
                                        color: _kPrimary,
                                      ),
                                    const SizedBox(width: 6),
                                    const Flexible(
                                      child: Text(
                                        'Ringkasan Scan',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _kPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: const Color(
                              0xFF0A7349,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: _completing ? null : _markComplete,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_completing)
                                      const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF0A7349),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 15,
                                        color: Color(0xFF0A7349),
                                      ),
                                    const SizedBox(width: 6),
                                    const Flexible(
                                      child: Text(
                                        'Tandai Selesai',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0A7349),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
    final sortedItems = [...vm.items]
      ..sort((a, b) {
        final aUnknown = a.blok == kSoV2UnknownBlok;
        final bUnknown = b.blok == kSoV2UnknownBlok;
        if (aUnknown != bUnknown) return aUnknown ? 1 : -1;
        return a.blok.compareTo(b.blok);
      });
    return ListView.separated(
      itemCount: sortedItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
      itemBuilder: (context, index) {
        final blokItem = sortedItems[index];
        final isUnknown = blokItem.blok == kSoV2UnknownBlok;
        final selected = _selectedBlok == blokItem.blok;
        final baseColor = isUnknown ? _kWarning : _kPrimary;
        return InkWell(
          onTap: () => _selectBlok(blokItem.blok),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? baseColor.withValues(alpha: 0.05)
                  : (isUnknown ? _kWarningBg : null),
              border: Border(
                left: BorderSide(
                  color: selected ? baseColor : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(9, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    isUnknown
                        ? 'Tanpa Blok (${blokItem.locationCount})'
                        : 'Blok ${blokItem.blok} (${blokItem.locationCount})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? baseColor
                          : (isUnknown ? _kWarning : const Color(0xFF1A1D23)),
                    ),
                  ),
                ),
                if (blokItem.workingLocationCount > 0) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message:
                        '${blokItem.workingLocationCount} lokasi sedang dikerjakan',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A7349).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 11,
                            color: Color(0xFF0A7349),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${blokItem.workingLocationCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A7349),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
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
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBlok == kSoV2UnknownBlok
                            ? 'Tanpa Blok'
                            : 'Blok $_selectedBlok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _selectedBlok == kSoV2UnknownBlok
                              ? _kWarning
                              : const Color(0xFF1A1D23),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderStat(
                              label: 'LOKASI',
                              value: '${vm.items.length}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: _kBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          Expanded(
                            child: _HeaderStat(
                              label: 'LABEL',
                              value: '${vm.totalLabelCount}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: _kBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          Expanded(
                            child: _HeaderStat(
                              label: _uom == 'pcs' ? 'PCS' : 'BERAT',
                              value: soV2FormatQty(vm.totalWeight),
                            ),
                          ),
                        ],
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
    final sortedItems = [...vm.items]
      ..sort((a, b) {
        if (a.isUnknown != b.isUnknown) return a.isUnknown ? 1 : -1;
        return 0;
      });
    return ListView.separated(
      itemCount: sortedItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
      itemBuilder: (context, index) {
        final lokasi = sortedItems[index];
        final selected = _selectedLokasi?.locationId == lokasi.locationId;
        final baseColor = lokasi.isUnknown ? _kWarning : _kPrimary;
        final complete =
            lokasi.labelCount > 0 && lokasi.scannedCount >= lokasi.labelCount;
        final progressColor = complete ? const Color(0xFF0A7349) : baseColor;
        final showAssignControl =
            !lokasi.isUnknown &&
            context.watch<PermissionViewModel>().can(_kAccessManagePermission);

        return Container(
          decoration: BoxDecoration(
            color: selected
                ? baseColor.withValues(alpha: 0.05)
                : (complete
                      ? _kSuccessBg
                      : (lokasi.isUnknown ? _kWarningBg : null)),
            border: Border(
              left: BorderSide(
                color: selected
                    ? baseColor
                    : (complete ? const Color(0xFF0A7349) : Colors.transparent),
                width: 3,
              ),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Zona 1: buka panel label — selalu aktif, terlepas dari
                // status penugasan.
                Expanded(
                  child: InkWell(
                    onTap: () => _selectLokasi(lokasi),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(9, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (lokasi.isUnknown) ...[
                            Icon(
                              Icons.location_off_rounded,
                              color: baseColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                          ] else if (complete) ...[
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0A7349),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: lokasi.isUnknown
                                ? Text(
                                    'Lokasi Tidak Diketahui',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? baseColor : _kWarning,
                                    ),
                                  )
                                : Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '$_selectedBlok${lokasi.locationId} ',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: selected
                                                ? baseColor
                                                : (complete
                                                      ? const Color(0xFF0A7349)
                                                      : const Color(
                                                          0xFF1A1D23,
                                                        )),
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '(${lokasi.scannedCount}/${lokasi.labelCount})',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: progressColor,
                                          ),
                                        ),
                                        if (!complete)
                                          TextSpan(
                                            text: lokasi.allowedUsers.isNotEmpty
                                                ? '  ·  ${lokasi.allowedUsers.map((u) => u.displayName).join(', ')}'
                                                : '  ·  Belum ditugaskan',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight:
                                                  lokasi.allowedUsers.isEmpty
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                              color: lokasi.allowedUsers.isEmpty
                                                  ? Colors.grey.shade400
                                                  : const Color(0xFF1A1D23),
                                            ),
                                          ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          if (complete) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A7349),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Zona 2: kontrol penugasan (play/pause) — dipisah dengan
                // divider supaya jelas bukan bagian dari tap buka lokasi.
                if (showAssignControl) ...[
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: _kBorder,
                    indent: 8,
                    endIndent: 8,
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _busyLocationIds.contains(lokasi.locationId)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              // SO yang sudah ditandai selesai mengunci
                              // semua penugasan — tidak boleh ada
                              // play/pause lagi, scan pun sudah tidak bisa.
                              onPressed: _blokVm.isComplete
                                  ? null
                                  : (lokasi.allowedUsers.isEmpty
                                        ? () => _playLokasi(lokasi)
                                        : () => _pauseLokasi(lokasi)),
                              icon: Icon(
                                lokasi.allowedUsers.isEmpty
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.pause_circle_filled_rounded,
                                size: 20,
                                color: _blokVm.isComplete
                                    ? Colors.grey.shade400
                                    : (lokasi.allowedUsers.isEmpty
                                          ? const Color(0xFF0A7349)
                                          : const Color(0xFFB45309)),
                              ),
                              tooltip: _blokVm.isComplete
                                  ? 'Stock opname sudah selesai'
                                  : (lokasi.allowedUsers.isEmpty
                                        ? 'Tugaskan User'
                                        : 'Lepas User'),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _playLokasi(SoV2Lokasi lokasi) async {
    final picked = await showDialog<SoV2AccessUser>(
      context: context,
      builder: (_) => SoV2WorkerPickerDialog(repo: _accessRepo),
    );
    if (picked == null) return;

    setState(() => _busyLocationIds.add(lokasi.locationId));
    try {
      await _accessRepo.assignAccess(
        blok: _selectedBlok!,
        idLokasi: lokasi.locationId,
        idUsername: picked.idUsername,
        stockOpnameNo: widget.stockOpnameNo,
      );
      if (!mounted) return;
      await _lokasiVm?.load();
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.friendlyMessage
          : 'Gagal menugaskan user';
      await DialogService.instance.showError(
        title: 'Gagal Menugaskan User',
        message: message,
      );
    } finally {
      if (mounted) setState(() => _busyLocationIds.remove(lokasi.locationId));
    }
  }

  Future<void> _pauseLokasi(SoV2Lokasi lokasi) async {
    final activeUser = lokasi.allowedUsers.isEmpty
        ? null
        : lokasi.allowedUsers.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Lepas User',
        message:
            'Yakin ingin melepas ${activeUser?.displayName ?? 'user'} dari lokasi ini?',
        confirmLabel: 'Lepas',
        confirmIcon: Icons.pause_circle_outline_rounded,
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyLocationIds.add(lokasi.locationId));
    try {
      for (final user in lokasi.allowedUsers) {
        await _accessRepo.revokeAccess(
          blok: _selectedBlok!,
          idLokasi: lokasi.locationId,
          idUsername: user.idUsername,
          stockOpnameNo: widget.stockOpnameNo,
        );
      }
      if (!mounted) return;
      // Lokasi yang baru dilepas jadi terkunci lagi — tutup panel label
      // kalau lokasi ini sedang dibuka.
      if (_selectedLokasi?.locationId == lokasi.locationId) {
        _labelVm?.dispose();
        setState(() {
          _labelVm = null;
          _selectedLokasi = null;
        });
      }
      await _lokasiVm?.load();
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.friendlyMessage
          : 'Gagal melepas user';
      await DialogService.instance.showError(
        title: 'Gagal Melepas User',
        message: message,
      );
    } finally {
      if (mounted) setState(() => _busyLocationIds.remove(lokasi.locationId));
    }
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: _kBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _searchOpen
                              ? TextField(
                                  controller: _searchCtl,
                                  autofocus: true,
                                  onChanged: vm.setSearchDebounced,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Cari nomor label...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                )
                              : Row(
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
                                            : '$_selectedBlok${_selectedLokasi!.locationId}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                        ),
                        IconButton(
                          onPressed: () => _toggleSearch(vm),
                          icon: Icon(
                            _searchOpen
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            size: 20,
                            color: _searchOpen
                                ? Colors.grey.shade600
                                : _kPrimary,
                          ),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                    if (!_searchOpen) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderStat(
                              label: 'LABEL',
                              value: '${vm.totalScanned}/${vm.totalRecords}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: _kBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          Expanded(
                            child: _HeaderStat(
                              label: _uom == 'pcs' ? 'PCS' : 'BERAT',
                              value: soV2FormatQty(vm.totalWeight),
                            ),
                          ),
                        ],
                      ),
                    ],
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
              Expanded(
                child: PagingListener<int, SoV2LabelGroup>(
                  controller: vm.pagingController,
                  builder: (context, state, fetchNextPage) {
                    return RefreshIndicator(
                      onRefresh: () async => vm.pagingController.refresh(),
                      child: PagedListView<int, SoV2LabelGroup>(
                        state: state,
                        fetchNextPage: fetchNextPage,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        builderDelegate:
                            PagedChildBuilderDelegate<SoV2LabelGroup>(
                              itemBuilder: (context, group, index) =>
                                  SoV2LabelGroupTile(
                                    group: group,
                                    weightUnit: _uom,
                                  ),
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

/// Statistik header panel: caption kecil di atas, nilai tebal di bawah.
class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D23),
          ),
        ),
      ],
    );
  }
}
