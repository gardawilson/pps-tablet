// lib/features/production/washing/view/washing_production_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:pps_tablet/core/view/app_shell.dart';
import 'package:pps_tablet/features/production/washing/view_model/washing_production_input_view_model.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/scan_label_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import '../../washing/widgets/washing_input_group_popover.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/widgets/partial_mode_not_supported_dialog.dart';
import '../../shared/widgets/weight_input_dialog.dart';
import '../model/washing_inputs_model.dart';
import '../repository/washing_production_input_repository.dart';
import '../widgets/washing_output_tile.dart';
import '../widgets/washing_production_output_form_dialog.dart';
import '../widgets/washing_workspace_toolbar.dart';
import '../../../washing_type/model/washing_type_model.dart';
import '../../../washing_type/widgets/washing_type_dropdown.dart';
import '../repository/washing_production_repository.dart';

import 'package:pps_tablet/features/production/shared/shared.dart';
import '../widgets/washing_lookup_label_dialog.dart';
import '../widgets/washing_lookup_label_partial_dialog.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../model/washing_production_model.dart';

// ── Washing colour palette ─────────────────────────────────────────────────────

const _kWashingPrimary = Color(0xFF0277BD); // biru washing
const _kWashingOutput = Color(0xFF00796B); // teal output
const _kWashingSurface = Color(0xFFF8F9FB);
const _kWashingBorder = Color(0xFFE2E6EA);

// ── Screen ────────────────────────────────────────────────────────────────────

class WashingProductionInputScreen extends StatefulWidget {
  final String noProduksi;

  const WashingProductionInputScreen({
    super.key,
    required this.noProduksi,
  });

  @override
  State<WashingProductionInputScreen> createState() =>
      _WashingProductionInputScreenState();
}

class _WashingProductionInputScreenState
    extends State<WashingProductionInputScreen> {
  final _repo = WashingProductionInputRepository();
  final _prodRepo = WashingProductionRepository();

  WashingProduction? _header;
  late String _cachedBreadcrumbLabel;

  String _selectedMode = 'full';
  String _selectedInputTab = 'bb';
  String _selectedOutputTab = 'washing';

  List<BreadcrumbSegment> _prevBreadcrumb = [];
  bool _isReplacing = false;

  String get _breadcrumbLabel {
    final mesin = (_header?.namaMesin ?? '').trim();
    if (mesin.isNotEmpty) return '$mesin (${widget.noProduksi})';
    return widget.noProduksi;
  }

  @override
  void initState() {
    super.initState();
    _cachedBreadcrumbLabel = widget.noProduksi;
    _loadHeader();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prevBreadcrumb = List<BreadcrumbSegment>.from(AppShell.breadcrumb.value);
      _updateBreadcrumb();

      final vm = context.read<WashingProductionInputViewModel>();
      if (vm.inputsOf(widget.noProduksi) == null &&
          !vm.isInputsLoading(widget.noProduksi)) {
        vm.loadInputs(widget.noProduksi);
      }
      if (vm.outputsOf(widget.noProduksi) == null &&
          !vm.isOutputsLoading(widget.noProduksi)) {
        vm.loadOutputs(widget.noProduksi);
      }
    });
  }

  Future<void> _loadHeader() async {
    try {
      final header = await _prodRepo.fetchOne(widget.noProduksi);
      if (!mounted) return;
      setState(() {
        _header = header;
        _cachedBreadcrumbLabel = _breadcrumbLabel;
      });
      _updateBreadcrumb();
    } catch (_) {}
  }

  void _updateBreadcrumb() {
    if (!mounted) return;
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
      BreadcrumbSegment(_breadcrumbLabel),
    ];
  }

  @override
  void dispose() {
    if (!_isReplacing) {
      final prev = _prevBreadcrumb;
      final label = _cachedBreadcrumbLabel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = AppShell.breadcrumb.value;
        if (current.isNotEmpty && current.last.label == label) {
          AppShell.breadcrumb.value = prev;
        }
      });
    }
    super.dispose();
  }

  // ── Title key helpers ──────────────────────────────────────────────────────

  String bbTitleKey(BbItem item) {
    final partial = (item.noBBPartial ?? '').trim();
    if (partial.isNotEmpty) return partial;
    final nb = (item.noBahanBaku ?? '').trim();
    final np = item.noPallet;
    final hasNb = nb.isNotEmpty;
    final hasNp = (np != null && np > 0);
    if (!hasNb && !hasNp) return '-';
    if (hasNb && hasNp) return '$nb-$np';
    if (hasNb) return nb;
    return 'Pallet $np';
  }

  String gilinganTitleKey(GilinganItem item) {
    final partial = (item.noGilinganPartial ?? '').trim();
    if (partial.isNotEmpty) return partial;
    return item.noGilingan ?? '-';
  }

  String bbPairLabel(BbItem item) {
    final nb = item.noBahanBaku ?? '-';
    final np = item.noPallet ?? 0;
    if (np > 0) return '$nb-$np';
    return nb;
  }

  // ── Back / WillPop ─────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    final vm = context.read<WashingProductionInputViewModel>();
    if (vm.totalTempCount == 0) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UnsavedTempWarningDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
        onSavePressed: () {
          Navigator.of(dialogContext).pop(false);
          _handleSave();
        },
      ),
    );

    if (shouldPop == true) {
      vm.clearAllTempItems();
      return true;
    }
    return false;
  }

  // ── Snack ──────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openSplitDialog() async {
    if (!mounted) return;
    await ProductionFlowHelpers.openSplitAndReplace<
      ({WashingProduction prod, String namaJenis})
    >(
      context: context,
      idMesin: _header?.idMesin,
      tanggal: _header?.tglProduksi,
      onMissingContext: () => _showSnack(
        'Data mesin/tanggal tidak tersedia',
        backgroundColor: Colors.orange,
      ),
      showSplitDialog: (idMesin, tgl) {
        return showDialog<({WashingProduction prod, String namaJenis})>(
          context: context,
          barrierDismissible: true,
          builder: (_) =>
              ProductionGantiProduksiDialog<
                ({WashingProduction prod, String namaJenis}),
                WashingType
              >(
                tanggal: tgl,
                shift: _header?.shift ?? 1,
                primaryColor: _kWashingPrimary,
                borderColor: _kWashingBorder,
                jenisRequiredMessage: 'Pilih jenis washing terlebih dahulu',
                submitLabel: 'Ganti Produksi',
                dropdownBuilder: (selected, onChanged) => WashingTypeDropdown(
                  preselectId: selected?.idWashing,
                  onChanged: onChanged,
                ),
                jenisNameOf: (j) => j.nama,
                onSubmit: (hourStart, jenis) async {
                  final prod = await WashingProductionRepository().addProduksi(
                    idMesin: idMesin,
                    tanggal: tgl,
                    hourStart: hourStart,
                    outputJenisId: jenis.idWashing,
                  );
                  return (prod: prod, namaJenis: jenis.nama);
                },
              ),
        );
      },
      beforeReplace: () {
        _isReplacing = true;
        AppShell.breadcrumb.value = _prevBreadcrumb;
      },
      replaceToResult: (splitResult) async {
        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WashingProductionInputScreen(
              noProduksi: splitResult.prod.noProduksi,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTimelineDialog() async {
    if (!mounted) return;
    await ProductionFlowHelpers.openTimeline(
      context: context,
      idMesin: _header?.idMesin,
      tanggal: _header?.tglProduksi,
      onMissingContext: () => _showSnack(
        'Data mesin/tanggal tidak tersedia',
        backgroundColor: Colors.orange,
      ),
      dialogBuilder: (idMesin, tgl) => buildProductionShiftTimelineDialog(
        namaMesin: _header?.namaMesin,
        tanggal: tgl,
        shift: _header?.shift ?? 1,
        currentNoProduksi: widget.noProduksi,
        primaryColor: _kWashingPrimary,
        borderColor: _kWashingBorder,
        emptyMessage: 'Belum ada riwayat produksi pada shift ini.',
        loadTimeline: () async {
          final list = await WashingProductionRepository()
              .fetchByMesinTanggalShift(
                idMesin: idMesin,
                tanggal: tgl,
                shift: _header?.shift ?? 1,
              );
          return list
              .map(
                (e) => ProductionShiftTimelineEntry(
                  noProduksi: e.noProduksi,
                  hourStart: e.hourStart,
                  hourEnd: e.hourEnd,
                  isLocked: e.isLocked,
                  subtitle: e.outputJenisNama,
                ),
              )
              .toList();
        },
      ),
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    final vm = context.read<WashingProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      _showSnack(
        'Tidak ada data untuk disimpan',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ConfirmSaveTempDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await vm.submitTempItems(widget.noProduksi);
    if (!mounted) return;

    if (success) {
      _showSnack('✅ Data berhasil disimpan', backgroundColor: Colors.green);
      vm.loadOutputs(widget.noProduksi, force: true);
    } else {
      final errMsg = vm.submitError ?? 'Kesalahan tidak diketahui';
      await showDialog(
        context: context,
        builder: (_) =>
            ErrorStatusDialog(title: 'Gagal Menyimpan', message: errMsg),
      );
    }
  }

  // ── Clear temp dialog ──────────────────────────────────────────────────────

  void _confirmClearTemp() {
    final vm = context.read<WashingProductionInputViewModel>();
    if (vm.totalTempCount == 0) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Semua Temp?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${vm.totalTempCount} item temp?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              vm.clearAllTempItems();
              Navigator.of(dialogContext).pop();
              _showSnack('Semua temp items dihapus');
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ── Scan / lookup ──────────────────────────────────────────────────────────

  String _modeLabel(String mode) {
    switch (mode) {
      case 'full':
        return 'FULL PALLET';
      case 'select':
        return 'SEBAGIAN PALLET';
      case 'partial':
        return 'PARTIAL';
      default:
        return mode.toUpperCase();
    }
  }

  Future<void> _openScanDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ScanLabelDialog(
        manualHint: 'X.XXXXXXXXXX',
        headerSubtitle: _modeLabel(_selectedMode),
        acceptedLabels: const [
          (prefix: 'A', label: 'Bahan Baku'),
          (prefix: 'B', label: 'Washing'),
          (prefix: 'V', label: 'Gilingan'),
        ],
        onLookup: (code) async => _onCodeReady(code),
      ),
    );
  }

  /// Mengembalikan pesan error (ditampilkan inline di ScanLabelDialog),
  /// atau null jika sukses.
  Future<String?> _onCodeReady(String code) async {
    final vm = context.read<WashingProductionInputViewModel>();

    // Validasi: mode partial tidak support label Washing (B.)
    if (_selectedMode == 'partial') {
      final normalized = code.trim().toUpperCase();
      final prefix = normalized.length >= 2 ? normalized.substring(0, 2) : '';
      if (prefix == 'B.') {
        await PartialModeNotSupportedDialog.show(
          context: context,
          labelType: 'Washing',
          onOk: () {},
        );
        return 'Washing tidak mendukung mode PARTIAL';
      }
    }

    final res = await vm.lookupLabel(code, force: true);
    if (!mounted) return 'Halaman sudah tidak aktif';

    if (vm.lookupError != null) {
      return 'Gagal ambil data: ${vm.lookupError}';
    }

    if (res == null || res.found == false || res.data.isEmpty) {
      return 'Label "$code" tidak memiliki data yang tersedia.';
    }

    // Auto-switch ke tab sesuai tipe label
    final tab = _tabForLookupResult(res);
    if (tab != null && tab != _selectedInputTab) {
      setState(() => _selectedInputTab = tab);
    }

    if (_selectedMode == 'full') {
      await _handleFullMode(vm, res);
    } else if (_selectedMode == 'partial') {
      await _handlePartialMode(vm, res);
    } else {
      await _handleSelectMode(vm, res);
    }

    return null;
  }

  String? _tabForLookupResult(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;
    if (item is BbItem) return 'bb';
    if (item is WashingItem) return 'washing';
    if (item is GilinganItem) return 'gilingan';
    return null;
  }

  Future<void> _handleFullMode(
    WashingProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);
    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp =
          labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp
          ? ' • ${vm.getTemporaryDataSummary(labelCode)}'
          : '';
      _showSnack(
        'Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix',
      );
      return;
    }
    vm.clearPicks();
    vm.pickAllNew(widget.noProduksi);
    final result = vm.commitPickedToTemp(noProduksi: widget.noProduksi);
    final msg = result.added > 0
        ? '✅ Auto-added ${result.added} item'
              '${result.skipped > 0 ? ' • Duplikat terlewati ${result.skipped}' : ''}'
        : 'Tidak ada item baru ditambahkan';
    _showSnack(
      msg,
      backgroundColor: result.added > 0 ? Colors.green : Colors.orange,
    );
  }

  Future<void> _handlePartialMode(
    WashingProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    // Gilingan (non-sak): tanya berat saja via WeightInputDialog
    final firstItem = res.typedItems.isNotEmpty ? res.typedItems.first : null;
    if (firstItem is GilinganItem && res.data.isNotEmpty) {
      final row = res.data.first;
      final beratRaw = row['berat'] ?? row['Berat'];
      final originalBerat = beratRaw != null
          ? (beratRaw as num).toDouble()
          : null;
      if (originalBerat == null || originalBerat <= 0) return;

      final newWeight = await WeightInputDialog.show(
        context,
        maxWeight: originalBerat,
        currentWeight: null,
      );
      if (!mounted || newWeight == null) return;

      final originalIsPartial = row['isPartial'];
      row['isPartial'] = true;
      row['IsPartial'] = true;
      row['berat'] = newWeight;
      row['Berat'] = newWeight;

      vm.clearPicks();
      vm.togglePick(row);
      final r = vm.commitPickedToTemp(noProduksi: widget.noProduksi);

      row['berat'] = originalBerat;
      row['Berat'] = originalBerat;
      row['isPartial'] = originalIsPartial;
      row['IsPartial'] = originalIsPartial;

      _showSnack(
        r.added > 0
            ? '✅ Ditambahkan ${r.added} item partial'
            : 'Item sudah ada atau gagal ditambahkan',
        backgroundColor: r.added > 0 ? Colors.green : Colors.orange,
      );
      return;
    }

    // Sak-based (BB): tampilkan partial dialog
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WashingLookupLabelPartialDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  Future<void> _handleSelectMode(
    WashingProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);
    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp =
          labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp
          ? ' • ${vm.getTemporaryDataSummary(labelCode)}'
          : '';
      _showSnack(
        'Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix',
      );
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WashingLookupLabelDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;
    if (item is BbItem) {
      final npart = (item.noBBPartial ?? '').trim();
      return npart.isNotEmpty ? npart : item.noBahanBaku;
    }
    if (item is WashingItem) return item.noWashing;
    if (item is GilinganItem) {
      return (item.noGilinganPartial ?? '').trim().isNotEmpty
          ? item.noGilinganPartial
          : item.noGilingan;
    }
    return null;
  }

  // ── Temp card options (long press) ────────────────────────────────────────

  Future<void> _showTempCardOptions(String labelTitle) async {
    final vm = context.read<WashingProductionInputViewModel>();

    final tempData = vm.getTemporaryDataForLabel(labelTitle);

    // Sebagian: sak-based (BB / Washing)
    final isSakBased =
        tempData != null &&
        (tempData.bbItems.isNotEmpty ||
            tempData.bbPartials.isNotEmpty ||
            tempData.washingItems.isNotEmpty);

    // Partial: BB & Gilingan (Washing B. tidak support partial)
    final supportsPartial =
        tempData != null &&
        (tempData.bbItems.isNotEmpty ||
            tempData.bbPartials.isNotEmpty ||
            tempData.gilinganItems.isNotEmpty ||
            tempData.gilinganPartials.isNotEmpty);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => ProductionTempCardOptionsDialog(
        labelTitle: labelTitle,
        showSebagian: isSakBased,
        showPartial: supportsPartial,
        primaryColor: _kWashingPrimary,
        surfaceColor: _kWashingSurface,
        borderColor: _kWashingBorder,
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'delete') {
      vm.deleteAllTempForLabel(labelTitle);
    } else if (result == 'select' || result == 'partial') {
      // Hapus temp lama, lalu re-lookup pakai cache
      vm.deleteAllTempForLabel(labelTitle);
      setState(() => _selectedMode = result);

      if (!mounted) return;

      final lookupResult = await vm.lookupLabel(labelTitle);
      if (!mounted) return;

      if (lookupResult == null) {
        _showSnack(
          'Gagal memuat data label: ${vm.lookupError ?? "error tidak diketahui"}',
          backgroundColor: Colors.red,
        );
        return;
      }

      if (result == 'partial') {
        await _handlePartialMode(vm, lookupResult);
      } else {
        await _handleSelectMode(vm, lookupResult);
      }
    }
  }

  Widget _buildToolbarSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(height: 56, color: Colors.white),
    );
  }

  // ── Input panel ────────────────────────────────────────────────────────────
  //
  // Header mengikuti broker _buildInputPanel:
  //   section header kiri | Spacer | mode chips | scan button | save badge | clear-temp

  Widget _buildInputPanel({
    required WashingProductionInputViewModel vm,
    required bool locked,
    required bool loading,
    required bool canDelete,
    required Map<String, List<BbItem>> bbGroups,
    required Map<String, List<WashingItem>> washingGroups,
    required Map<String, List<GilinganItem>> gilinganGroups,
  }) {
    int grandSak = 0;
    double grandBerat = 0.0;
    for (final items in bbGroups.values) {
      for (final i in items) {
        grandSak++;
        grandBerat += i.berat ?? 0.0;
      }
    }
    for (final items in washingGroups.values) {
      for (final i in items) {
        grandSak++;
        grandBerat += i.berat ?? 0.0;
      }
    }
    for (final items in gilinganGroups.values) {
      for (final i in items) {
        grandSak++;
        grandBerat += i.berat ?? 0.0;
      }
    }
    final totalLabel =
        bbGroups.length + washingGroups.length + gilinganGroups.length;
    final selectedSummary = _selectedInputSummary(
      bbGroups: bbGroups,
      washingGroups: washingGroups,
      gilinganGroups: gilinganGroups,
    );

    return Container(
      decoration: productionPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Panel header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 1, 1, 1),
            child: Row(
              children: [
                productionSectionHeader(
                  Icons.input_rounded,
                  'Label Input',
                  primaryColor: _kWashingPrimary,
                ),
                const Spacer(),

                // Save badge
                SaveButtonWithBadge(
                  count: vm.totalTempCount,
                  isLoading: vm.isSubmitting,
                  onPressed: _handleSave,
                ),
                const SizedBox(width: 4),

                // Clear temp
                IconButton(
                  tooltip: 'Hapus Semua Temp',
                  onPressed: vm.totalTempCount > 0 ? _confirmClearTemp : null,
                  icon: Icon(
                    Icons.delete_sweep,
                    size: 20,
                    color: vm.totalTempCount > 0
                        ? Colors.red.shade700
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kWashingBorder),

          // ── Panel body ──────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductionFolderTabBar(
                    selectedValue: _selectedInputTab,
                    accentColor: _kWashingPrimary,
                    tabs: [
                      ProductionTabItem(
                        value: 'bb',
                        label: 'Bahan Baku',
                        count: bbGroups.length,
                      ),
                      ProductionTabItem(
                        value: 'washing',
                        label: 'Washing',
                        count: washingGroups.length,
                      ),
                      ProductionTabItem(
                        value: 'gilingan',
                        label: 'Gilingan',
                        count: gilinganGroups.length,
                      ),
                    ],
                    onChanged: (value) {
                      if (_selectedInputTab == value) return;
                      setState(() => _selectedInputTab = value);
                    },
                  ),
                  Expanded(
                    child: ProductionInputCategoryBlock(
                      color: _kWashingPrimary,
                      isLoading: loading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) => SizedBox(
                                width: constraints.maxWidth,
                                child: _buildSelectedTabContent(
                                  vm: vm,
                                  canDelete: canDelete,
                                  bbGroups: bbGroups,
                                  washingGroups: washingGroups,
                                  gilinganGroups: gilinganGroups,
                                  showFooter: false,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProductionCategorySummaryTile(
                                      summary: selectedSummary,
                                      accentColor: _kWashingPrimary,
                                    ),
                                    const SizedBox(height: 10),
                                    ProductionInputGrandTotalBar(
                                      totalLabel: totalLabel,
                                      totalSak: grandSak,
                                      totalBerat: grandBerat,
                                      color: _kWashingPrimary,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              FloatingActionButton(
                                heroTag: 'fab_scan_washing_input',
                                mini: true,
                                backgroundColor: locked
                                    ? Colors.grey.shade300
                                    : _kWashingPrimary,
                                foregroundColor: Colors.white,
                                onPressed: locked || vm.isLookupLoading
                                    ? null
                                    : _openScanDialog,
                                child: vm.isLookupLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.qr_code_scanner),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Output panel ───────────────────────────────────────────────────────────

  Widget _buildOutputSection({
    required List<WashingOutput> outputs,
    required bool isLoading,
    required String? error,
    required double grandInputBerat,
  }) {
    int totalSak = 0;
    double totalBerat = 0.0;
    for (final o in outputs) {
      totalSak += o.totalSak;
      totalBerat += o.totalBerat;
    }
    Future<void> onAddWashing() async {
      if (grandInputBerat == 0) {
        showDialog<void>(
          context: context,
          builder: (_) => const ErrorStatusDialog(
            title: 'Belum Ada Input',
            message:
                'Masukkan label input terlebih dahulu sebelum membuat output.',
          ),
        );
        return;
      }
      if (totalBerat >= grandInputBerat) {
        showDialog<void>(
          context: context,
          builder: (_) => ErrorStatusDialog(
            title: 'Berat Output Melebihi Input',
            message:
                'Total berat output (${num2(totalBerat)} kg) sudah mencapai atau melebihi total berat input (${num2(grandInputBerat)} kg).\n\nTidak dapat menambah output baru.',
          ),
        );
        return;
      }
      if (_header?.outputJenisId == null) {
        _showSnack(
          'Jenis output belum dikonfigurasi pada produksi ini.',
          backgroundColor: Colors.orange,
        );
        return;
      }
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WashingProductionOutputFormDialog(
          noProduksi: widget.noProduksi,
          tglProduksi: _header?.tglProduksi,
          idJenis: _header!.outputJenisId!,
          namaJenis: _header?.outputJenisNama ?? '',
          namaMesin: _header?.namaMesin,
          repository: _repo,
        ),
      );
      if (result != null && mounted) {
        context.read<WashingProductionInputViewModel>().loadOutputs(
          widget.noProduksi,
          force: true,
        );
      }
    }

    return Container(
      decoration: productionPanelDecoration(
        borderColor: _kWashingOutput.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                productionSectionHeader(
                  Icons.output_rounded,
                  'Label Output',
                  iconColor: _kWashingOutput,
                  primaryColor: _kWashingPrimary,
                ),
                const Spacer(),
              ],
            ),
          ),
          const Divider(height: 1, color: _kWashingBorder),

          // ── Body ────────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null) ...[
                          ProductionOutputErrorBanner(message: error),
                          const SizedBox(height: 10),
                        ],
                        // ── Tab bar (1 tab: Washing) ────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: ProductionFolderTabBar(
                                selectedValue: _selectedOutputTab,
                                accentColor: _kWashingOutput,
                                tabs: [
                                  ProductionTabItem(
                                    value: 'washing',
                                    label: 'Washing',
                                    count: outputs.length,
                                  ),
                                ],
                                onChanged: (value) {
                                  if (_selectedOutputTab == value) return;
                                  setState(() => _selectedOutputTab = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ProductionInputCategoryBlock(
                            color: _kWashingOutput,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Output grid
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) => SizedBox(
                                      width: constraints.maxWidth,
                                      child: ProductionOutputCategoryContent(
                                        footer: const SizedBox.shrink(),
                                        child: outputs.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'Belum ada output washing',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                ),
                                              )
                                            : GridView(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount:
                                                          constraints.maxWidth <
                                                              380
                                                          ? 2
                                                          : 3,
                                                      crossAxisSpacing: 6,
                                                      mainAxisSpacing: 6,
                                                      mainAxisExtent: 78,
                                                    ),
                                                children: outputs
                                                    .map(
                                                      (o) => WashingOutputTile(
                                                        output: o,
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          WashingOutputSummaryTile(
                                            totalLabel: outputs.length,
                                            totalSak: totalSak,
                                            totalBerat: totalBerat,
                                          ),
                                          const SizedBox(height: 10),
                                          WashingOutputGrandTotalBar(
                                            totalLabel: outputs.length,
                                            totalSak: totalSak,
                                            totalBerat: totalBerat,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    FloatingActionButton(
                                      heroTag: 'fab_add_washing_output',
                                      mini: true,
                                      backgroundColor: _header == null
                                          ? Colors.grey.shade300
                                          : _kWashingOutput,
                                      foregroundColor: Colors.white,
                                      onPressed: _header == null ? null : onAddWashing,
                                      child: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Tab content ────────────────────────────────────────────────────────────

  Widget _buildSelectedTabContent({
    required WashingProductionInputViewModel vm,
    required bool canDelete,
    required Map<String, List<BbItem>> bbGroups,
    required Map<String, List<WashingItem>> washingGroups,
    required Map<String, List<GilinganItem>> gilinganGroups,
    bool showFooter = true,
  }) {
    switch (_selectedInputTab) {
      case 'bb':
        return _buildBbTab(
          vm: vm,
          canDelete: canDelete,
          bbGroups: bbGroups,
          showFooter: showFooter,
        );
      case 'washing':
        return _buildWashingTab(
          vm: vm,
          canDelete: canDelete,
          washingGroups: washingGroups,
          showFooter: showFooter,
        );
      default:
        return _buildGilinganTab(
          vm: vm,
          canDelete: canDelete,
          gilinganGroups: gilinganGroups,
          showFooter: showFooter,
        );
    }
  }

  // ── BB tab ─────────────────────────────────────────────────────────────────

  Widget _buildBbTab({
    required WashingProductionInputViewModel vm,
    required bool canDelete,
    required Map<String, List<BbItem>> bbGroups,
    bool showFooter = true,
  }) {
    int totalSak = 0;
    double totalBerat = 0.0;
    for (final entry in bbGroups.entries) {
      for (final item in entry.value) {
        totalSak += 1;
        totalBerat += item.berat ?? 0.0;
      }
    }

    final footer = ProductionCategorySummaryTile(
      summary: SectionSummary(
        totalData: bbGroups.length,
        totalSak: totalSak,
        totalBerat: totalBerat,
      ),
      accentColor: _kWashingPrimary,
    );

    final grid = bbGroups.isEmpty
        ? const Center(
            child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
          )
        : LayoutBuilder(
            builder: (_, c) => GridView(
              padding: const EdgeInsets.all(6),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                mainAxisExtent: 72,
              ),
              children: bbGroups.entries.map((entry) {
                final hasPartial = entry.value.any((x) => x.isPartialRow);
                return ProductionInputGroupTile(
                  title: entry.key,
                  headerSubtitle:
                      (entry.value.isNotEmpty
                          ? entry.value.first.namaJenis
                          : '-') ??
                      '-',
                  tileMetrics: [
                    (Icons.inventory_2_outlined, '${entry.value.length} sak'),
                    (
                      Icons.scale_outlined,
                      '${num2(entry.value.fold<double>(0.0, (s, i) => s + (i.berat ?? 0.0)))} kg',
                    ),
                  ],
                  color: _kWashingPrimary,
                  isTemp: vm.hasTemporaryDataForLabel(entry.key),
                  onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                      ? () => _showTempCardOptions(entry.key)
                      : null,
                  expandable: !hasPartial,
                  isPartialGroup: hasPartial,
                  partialReference: hasPartial
                      ? bbPairLabel(
                          entry.value.firstWhere((x) => x.isPartialRow),
                        )
                      : null,
                  detailsBuilder: () => [],
                  chipItemsBuilder: () {
                    final currentInputs = vm.inputsOf(widget.noProduksi);
                    final dbItems = currentInputs == null
                        ? <BbItem>[]
                        : currentInputs.bb.where(
                            (x) => bbTitleKey(x) == entry.key,
                          );
                    final tempFull = vm.tempBb.where(
                      (x) => bbTitleKey(x) == entry.key,
                    );
                    final tempPart = vm.tempBbPartial.where(
                      (x) => bbTitleKey(x) == entry.key,
                    );
                    final items = [...tempPart, ...dbItems, ...tempFull];
                    return items.map((item) {
                      final isTemp =
                          vm.tempBb.contains(item) ||
                          vm.tempBbPartial.contains(item);
                      return ProductionSakChip(
                        label: 'Sak ${item.noSak ?? '-'}',
                        berat: item.berat,
                        isTemp: isTemp,
                        isPartial: item.isPartialRow,
                        onDelete: isTemp
                            ? () => vm.deleteTempBbItem(item)
                            : null,
                      );
                    }).toList();
                  },
                );
              }).toList(),
            ),
          );

    return ProductionOutputCategoryContent(
      footer: showFooter ? footer : const SizedBox.shrink(),
      child: grid,
    );
  }

  // ── Washing tab ────────────────────────────────────────────────────────────

  Widget _buildWashingTab({
    required WashingProductionInputViewModel vm,
    required bool canDelete,
    required Map<String, List<WashingItem>> washingGroups,
    bool showFooter = true,
  }) {
    int totalSak = 0;
    double totalBerat = 0.0;
    for (final entry in washingGroups.entries) {
      for (final item in entry.value) {
        totalSak += 1;
        totalBerat += item.berat ?? 0.0;
      }
    }

    final footer = ProductionCategorySummaryTile(
      summary: SectionSummary(
        totalData: washingGroups.length,
        totalSak: totalSak,
        totalBerat: totalBerat,
      ),
      accentColor: _kWashingPrimary,
    );

    final grid = washingGroups.isEmpty
        ? const Center(
            child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
          )
        : LayoutBuilder(
            builder: (_, c) => GridView(
              padding: const EdgeInsets.all(6),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                mainAxisExtent: 72,
              ),
              children: washingGroups.entries.map((entry) {
                return ProductionInputGroupTile(
                  title: entry.key,
                  headerSubtitle:
                      (entry.value.isNotEmpty
                          ? entry.value.first.namaJenis
                          : '-') ??
                      '-',
                  tileMetrics: [
                    (Icons.inventory_2_outlined, '${entry.value.length} sak'),
                    (
                      Icons.scale_outlined,
                      '${num2(entry.value.fold<double>(0.0, (s, i) => s + (i.berat ?? 0.0)))} kg',
                    ),
                  ],
                  color: _kWashingPrimary,
                  isTemp: vm.hasTemporaryDataForLabel(entry.key),
                  onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                      ? () => _showTempCardOptions(entry.key)
                      : null,
                  detailsBuilder: () => [],
                  chipItemsBuilder: () {
                    final currentInputs = vm.inputsOf(widget.noProduksi);
                    final items = [
                      if (currentInputs != null)
                        ...currentInputs.washing.where(
                          (x) => (x.noWashing ?? '-') == entry.key,
                        ),
                      ...vm.tempWashing.where(
                        (x) => (x.noWashing ?? '-') == entry.key,
                      ),
                    ];
                    return items.map((item) {
                      final isTemp = vm.tempWashing.contains(item);
                      return ProductionSakChip(
                        label: 'Sak ${item.noSak ?? '-'}',
                        berat: item.berat,
                        isTemp: isTemp,
                        onDelete: isTemp
                            ? () => vm.deleteTempWashingItem(item)
                            : null,
                      );
                    }).toList();
                  },
                );
              }).toList(),
            ),
          );

    return ProductionOutputCategoryContent(
      footer: showFooter ? footer : const SizedBox.shrink(),
      child: grid,
    );
  }

  // ── Gilingan tab ───────────────────────────────────────────────────────────

  Widget _buildGilinganTab({
    required WashingProductionInputViewModel vm,
    required bool canDelete,
    required Map<String, List<GilinganItem>> gilinganGroups,
    bool showFooter = true,
  }) {
    double totalBerat = 0.0;
    for (final entry in gilinganGroups.entries) {
      for (final item in entry.value) {
        totalBerat += item.berat ?? 0.0;
      }
    }

    final footer = ProductionCategorySummaryTile(
      summary: SectionSummary(
        totalData: gilinganGroups.length,
        totalSak: 0,
        totalBerat: totalBerat,
      ),
      accentColor: _kWashingPrimary,
    );

    final grid = gilinganGroups.isEmpty
        ? const Center(
            child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
          )
        : LayoutBuilder(
            builder: (_, c) => GridView(
              padding: const EdgeInsets.all(6),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                mainAxisExtent: 72,
              ),
              children: gilinganGroups.entries.map((entry) {
                final hasPartial = entry.value.any((x) => x.isPartialRow);
                return ProductionInputGroupTile(
                  title: entry.key,
                  headerSubtitle:
                      (entry.value.isNotEmpty
                          ? entry.value.first.namaJenis
                          : '-') ??
                      '-',
                  tileMetrics: [
                    (
                      Icons.scale_outlined,
                      '${num2(entry.value.fold<double>(0.0, (s, i) => s + (i.berat ?? 0.0)))} kg',
                    ),
                  ],
                  color: _kWashingPrimary,
                  isTemp: vm.hasTemporaryDataForLabel(entry.key),
                  onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                      ? () => _showTempCardOptions(entry.key)
                      : null,
                  expandable: !hasPartial,
                  isPartialGroup: hasPartial,
                  partialReference: hasPartial
                      ? (entry.value
                                .firstWhere((x) => x.isPartialRow)
                                .noGilingan ??
                            '-')
                      : null,
                  detailsBuilder: () {
                    final currentInputs = vm.inputsOf(widget.noProduksi);
                    final dbItems = currentInputs == null
                        ? <GilinganItem>[]
                        : currentInputs.gilingan.where(
                            (x) => gilinganTitleKey(x) == entry.key,
                          );
                    final tempFull = vm.tempGilingan.where(
                      (x) => gilinganTitleKey(x) == entry.key,
                    );
                    final tempPart = vm.tempGilinganPartial.where(
                      (x) => gilinganTitleKey(x) == entry.key,
                    );
                    final items = [...tempPart, ...dbItems, ...tempFull];
                    return items.map((item) {
                      final isTemp =
                          vm.tempGilingan.contains(item) ||
                          vm.tempGilinganPartial.contains(item);
                      final columns = item.isPartialRow
                          ? <String>[
                              item.noGilingan ?? '-',
                              '${num2(item.berat)} kg',
                            ]
                          : <String>['${num2(item.berat)} kg'];
                      return TooltipTableRow(
                        columns: columns,
                        showDelete: isTemp,
                        onDelete: () {
                          if (isTemp) vm.deleteTempGilinganItem(item);
                        },
                        isTempRow: isTemp,
                        isHighlighted: isTemp,
                        isDisabled: !isTemp && !canDelete,
                        itemData: item,
                      );
                    }).toList();
                  },
                );
              }).toList(),
            ),
          );

    return ProductionOutputCategoryContent(
      footer: showFooter ? footer : const SizedBox.shrink(),
      child: grid,
    );
  }

  SectionSummary _selectedInputSummary({
    required Map<String, List<BbItem>> bbGroups,
    required Map<String, List<WashingItem>> washingGroups,
    required Map<String, List<GilinganItem>> gilinganGroups,
  }) {
    switch (_selectedInputTab) {
      case 'bb':
        int totalSak = 0;
        double totalBerat = 0.0;
        for (final entry in bbGroups.entries) {
          for (final item in entry.value) {
            totalSak += 1;
            totalBerat += item.berat ?? 0.0;
          }
        }
        return SectionSummary(
          totalData: bbGroups.length,
          totalSak: totalSak,
          totalBerat: totalBerat,
        );
      case 'washing':
        int totalSak = 0;
        double totalBerat = 0.0;
        for (final entry in washingGroups.entries) {
          for (final item in entry.value) {
            totalSak += 1;
            totalBerat += item.berat ?? 0.0;
          }
        }
        return SectionSummary(
          totalData: washingGroups.length,
          totalSak: totalSak,
          totalBerat: totalBerat,
        );
      default:
        double totalBerat = 0.0;
        for (final entry in gilinganGroups.entries) {
          for (final item in entry.value) {
            totalBerat += item.berat ?? 0.0;
          }
        }
        return SectionSummary(
          totalData: gilinganGroups.length,
          totalSak: 0,
          totalBerat: totalBerat,
        );
    }
  }

  // ── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<WashingProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);
        final perm = context.watch<PermissionViewModel>();
        final locked = _header?.isLocked == true;

        final canDelete = perm.can('label_washing:delete') && !locked;

        final outputs = vm.outputsOf(widget.noProduksi) ?? [];
        final outputLoading = vm.isOutputsLoading(widget.noProduksi);
        final outputErr = vm.outputsError(widget.noProduksi);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final nav = Navigator.of(
              this.context,
            ); // ignore: use_build_context_synchronously
            final canPop = await _onWillPop();
            if (canPop && mounted) nav.pop();
          },
          child: Scaffold(
            backgroundColor: _kWashingSurface,
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                // ── Workspace toolbar (status info) ────────────────────
                // Posisi & struktur identik dengan BrokerWorkspaceToolbar.
                if (_header == null)
                  _buildToolbarSkeleton()
                else
                  WashingWorkspaceToolbar(
                    isLocked: locked,
                    idMesin: _header!.idMesin,
                    namaJenis: _header!.outputJenisNama,
                    tglProduksi: _header!.tglProduksi,
                    shift: _header!.shift,
                    hourStart: _header!.hourStart,
                    hourEnd: _header!.hourEnd,
                    onRefresh: () {
                      vm.loadInputs(widget.noProduksi, force: true);
                      vm.loadOutputs(widget.noProduksi, force: true);
                      _showSnack('Data di-refresh');
                    },
                    onGanti: _openSplitDialog,
                    onRiwayat: _openTimelineDialog,
                  ),

                // ── Body ────────────────────────────────────────────────
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (err != null) {
                        return Center(
                          child: Text('Gagal memuat inputs:\n$err'),
                        );
                      }

                      final bbAll = loading
                          ? <BbItem>[]
                          : [
                              ...vm.tempBb.reversed,
                              ...vm.tempBbPartial.reversed,
                              ...?inputs?.bb,
                            ];
                      final washingAll = loading
                          ? <WashingItem>[]
                          : [...vm.tempWashing, ...?inputs?.washing];
                      final gilinganAll = loading
                          ? <GilinganItem>[]
                          : [
                              ...vm.tempGilingan.reversed,
                              ...vm.tempGilinganPartial.reversed,
                              ...?inputs?.gilingan,
                            ];

                      final bbGroups = groupBy(bbAll, bbTitleKey);
                      final washingGroups = groupBy(
                        washingAll,
                        (WashingItem e) => e.noWashing ?? '-',
                      );
                      final gilinganGroups = groupBy(
                        gilinganAll,
                        gilinganTitleKey,
                      );

                      double grandInputBerat = 0.0;
                      for (final i in bbAll) {
                        grandInputBerat += i.berat ?? 0.0;
                      }
                      for (final i in washingAll) {
                        grandInputBerat += i.berat ?? 0.0;
                      }
                      for (final i in gilinganAll) {
                        grandInputBerat += i.berat ?? 0.0;
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildInputPanel(
                                vm: vm,
                                locked: locked,
                                loading: loading,
                                canDelete: canDelete,
                                bbGroups: bbGroups,
                                washingGroups: washingGroups,
                                gilinganGroups: gilinganGroups,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildOutputSection(
                                outputs: outputs,
                                isLoading: outputLoading,
                                error: outputErr,
                                grandInputBerat: grandInputBerat,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card tile untuk label input — format identik dengan broker _InputGroupExpansionTile
// ─────────────────────────────────────────────────────────────────────────────
