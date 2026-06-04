// lib/features/production/hot_stamping/view/hot_stamping_production_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/view/app_shell.dart';
import 'package:pps_tablet/features/production/hot_stamp/view_model/hot_stamp_production_input_view_model.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/scan_label_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../../furniture_wip_type/model/furniture_wip_type_model.dart';
import '../../../furniture_wip_type/repository/furniture_wip_type_repository.dart';
import '../../../furniture_wip_type/view_model/furniture_wip_type_view_model.dart';
import '../../../furniture_wip_type/widgets/furniture_wip_type_dropdown.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/widgets/add_cabinet_material_dialog.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../model/hot_stamp_output_model.dart';
import '../model/hot_stamp_production_model.dart';
import '../model/hot_stamping_inputs_model.dart';
import '../widgets/hot_stamp_lookup_label_dialog.dart';
import '../widgets/hot_stamp_output_tile.dart';
import '../widgets/hot_stamp_production_output_form_dialog.dart';
import '../widgets/hot_stamp_reject_output_form_dialog.dart';
import '../widgets/hot_stamp_lookup_label_partial_dialog.dart';
import 'package:pps_tablet/features/production/shared/shared.dart';

// ── Colour palette ─────────────────────────────────────────────────────────────
const _kStampingPrimary = Color(0xFF1565C0); // blue — input
const _kStampingOutput = Color(0xFF00796B); // teal — output  (seperti crusher)
const _kStampingSurface = Color(0xFFF8F9FB);
const _kStampingBorder = Color(0xFFE2E6EA);

class HotStampingProductionInputScreen extends StatefulWidget {
  final String noProduksi;
  final bool? isLocked;
  final DateTime? lastClosedDate;

  // Header info (dari mesin screen)
  final int? idMesin;
  final String? namaJenis;
  final int? outputJenisId;
  final DateTime? tglProduksi;
  final int? shift;
  final String? hourStart;
  final String? hourEnd;

  const HotStampingProductionInputScreen({
    super.key,
    required this.noProduksi,
    this.isLocked,
    this.lastClosedDate,
    this.idMesin,
    this.namaJenis,
    this.outputJenisId,
    this.tglProduksi,
    this.shift,
    this.hourStart,
    this.hourEnd,
  });

  @override
  State<HotStampingProductionInputScreen> createState() =>
      _HotStampingProductionInputScreenState();
}

class _HotStampingProductionInputScreenState
    extends State<HotStampingProductionInputScreen> {
  String _selectedMode = 'full';
  String _selectedInputTab = 'fwip';
  String _selectedOutputTab = 'fwip';

  List<BreadcrumbSegment> _prevBreadcrumb = [];

  String get _breadcrumbLabel => widget.noProduksi;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _prevBreadcrumb = List<BreadcrumbSegment>.from(AppShell.breadcrumb.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      final vm = context.read<HotStampingProductionInputViewModel>();
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

  @override
  void dispose() {
    final current = AppShell.breadcrumb.value;
    if (current.isNotEmpty && current.last.label == _breadcrumbLabel) {
      AppShell.breadcrumb.value = _prevBreadcrumb;
    }
    super.dispose();
  }

  // ── Back ───────────────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    final vm = context.read<HotStampingProductionInputViewModel>();
    if (vm.totalTempCount == 0) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UnsavedTempWarningDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
        onSavePressed: () {
          Navigator.of(ctx).pop(false);
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

  // ── Split / Ganti produksi ─────────────────────────────────────────────────

  Future<void> _openSplitDialog() async {
    if (!mounted) return;
    final vm = context.read<HotStampingProductionInputViewModel>();
    await ProductionFlowHelpers.openSplitAndReplace<
      ({HotStampProduction prod, String namaJenis})
    >(
      context: context,
      idMesin: widget.idMesin,
      tanggal: widget.tglProduksi,
      onMissingContext: () =>
          _showSnack('Data mesin atau tanggal tidak tersedia'),
      showSplitDialog: (idMesin, tanggal) =>
          showDialog<({HotStampProduction prod, String namaJenis})>(
            context: context,
            barrierDismissible: false,
            builder: (_) => ChangeNotifierProvider(
              create: (_) => FurnitureWipTypeViewModel(
                repository: FurnitureWipTypeRepository(api: ApiClient()),
              ),
              child:
                  ProductionGantiProduksiDialog<
                    ({HotStampProduction prod, String namaJenis}),
                    FurnitureWipType
                  >(
                    tanggal: tanggal,
                    shift: widget.shift ?? 1,
                    primaryColor: _kStampingPrimary,
                    borderColor: _kStampingBorder,
                    jenisRequiredMessage:
                        'Pilih jenis Furniture WIP terlebih dahulu',
                    submitLabel: 'Ganti Produksi',
                    dropdownBuilder: (selected, onChanged) =>
                        FurnitureWipTypeDropdown(
                          preselectId: selected?.idCabinetWip,
                          onChanged: onChanged,
                        ),
                    jenisNameOf: (j) => j.nama,
                    onSubmit: (hourStart, jenis) async {
                      final body = await vm.repository.splitTime(
                        idMesin: idMesin,
                        tanggal: tanggal,
                        hourStart: hourStart,
                        outputJenisId: jenis.idCabinetWip,
                      );
                      final header =
                          body['data']['header'] as Map<String, dynamic>;
                      return (
                        prod: HotStampProduction.fromJson(header),
                        namaJenis: jenis.nama,
                      );
                    },
                  ),
            ),
          ),
      beforeReplace: () {
        AppShell.breadcrumb.value = _prevBreadcrumb;
      },
      replaceToResult: (splitResult) async {
        if (!mounted) return;
        final newProd = splitResult.prod;
        final namaJenis = splitResult.namaJenis.isNotEmpty
            ? splitResult.namaJenis
            : (newProd.outputJenisNama ?? '');
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HotStampingProductionInputScreen(
              noProduksi: newProd.noProduksi,
              idMesin: newProd.idMesin,
              isLocked: false,
              namaJenis: namaJenis,
              outputJenisId: newProd.outputJenisId,
              tglProduksi: newProd.tglProduksi,
              shift: newProd.shift,
              hourStart: newProd.hourStart,
              hourEnd: newProd.hourEnd,
            ),
          ),
        );
      },
    );
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

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    final vm = context.read<HotStampingProductionInputViewModel>();
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
      builder: (ctx) => ConfirmSaveTempDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
      ),
    );
    if (confirm != true || !mounted) return;

    final success = await vm.submitTempItems(widget.noProduksi);
    if (!mounted) return;

    if (success) {
      _showSnack('✅ Data berhasil disimpan', backgroundColor: Colors.green);
    } else {
      final errMsg = vm.submitError ?? 'Kesalahan tidak diketahui';
      await showDialog(
        context: context,
        builder: (_) =>
            ErrorStatusDialog(title: 'Gagal Menyimpan', message: errMsg),
      );
    }
  }

  void _confirmClearTemp() {
    final vm = context.read<HotStampingProductionInputViewModel>();
    if (vm.totalTempCount == 0) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Temp?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${vm.totalTempCount} item temp?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              vm.clearAllTempItems();
              Navigator.of(ctx).pop();
              _showSnack('Semua temp items dihapus');
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ── Scan / lookup ──────────────────────────────────────────────────────────

  Future<void> _openScanDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ScanLabelDialog(
        manualHint: 'F.XXXXXXXXXX',
        headerSubtitle: _selectedMode.toUpperCase(),
        acceptedLabels: const [(prefix: 'F', label: 'Furniture WIP')],
        onLookup: _onCodeReady,
      ),
    );
  }

  Future<String?> _onCodeReady(String code) async {
    final vm = context.read<HotStampingProductionInputViewModel>();

    final res = await vm.lookupFwipLabel(code, force: true);
    if (!mounted) return 'Halaman sudah tidak aktif';
    if (vm.lookupError != null) return 'Gagal ambil data: ${vm.lookupError}';
    if (res == null || res.found == false || res.data.isEmpty) {
      return 'Label "$code" tidak memiliki data yang tersedia.';
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

  Future<void> _handleFullMode(
    HotStampingProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);
    if (freshCount == 0) {
      final code = _labelCodeOfFirst(res);
      final hasTemp = code != null && vm.hasTemporaryDataForLabel(code);
      final suffix = hasTemp ? ' • ${vm.getTemporaryDataSummary(code)}' : '';
      _showSnack('Semua item untuk ${code ?? "label ini"} sudah ada.$suffix');
      return;
    }
    vm.clearPicks();
    vm.pickAllNew(widget.noProduksi);
    final result = vm.commitPickedToTemp(noProduksi: widget.noProduksi);
    final msg = result.added > 0
        ? '✅ Auto-added ${result.added} item${result.skipped > 0 ? ' • Duplikat terlewati ${result.skipped}' : ''}'
        : 'Tidak ada item baru ditambahkan';
    _showSnack(
      msg,
      backgroundColor: result.added > 0 ? Colors.green : Colors.orange,
    );
  }

  Future<void> _handlePartialMode(
    HotStampingProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => HotStampingLookupLabelPartialDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  Future<void> _handleSelectMode(
    HotStampingProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);
    if (freshCount == 0) {
      final code = _labelCodeOfFirst(res);
      final hasTemp = code != null && vm.hasTemporaryDataForLabel(code);
      final suffix = hasTemp ? ' • ${vm.getTemporaryDataSummary(code)}' : '';
      _showSnack('Semua item untuk ${code ?? "label ini"} sudah ada.$suffix');
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => HotStampingLookupLabelDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;
    if (item is FurnitureWipItem) {
      return (item.noFurnitureWIPPartial ?? '').trim().isNotEmpty
          ? item.noFurnitureWIPPartial
          : item.noFurnitureWIP;
    }
    return null;
  }

  // ── Cabinet Material helpers ───────────────────────────────────────────────

  Future<void> _openAddMaterialDialog(
    HotStampingProductionInputViewModel vm,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AddCabinetMaterialDialog(
        idWarehouse: 5,
        loadMaterials: ({required idWarehouse, bool force = false}) => vm
            .loadMasterCabinetMaterials(idWarehouse: idWarehouse, force: force),
        isAlreadyInTemp: (id) => vm.hasCabinetMaterialInTemp(id),
        onAddTemp: ({required masterItem, required jumlah}) =>
            vm.addTempCabinetMaterialFromMaster(
              masterItem: masterItem,
              Jumlah: jumlah,
            ),
      ),
    );
  }

  Future<void> _deleteExistingMaterial(
    HotStampingProductionInputViewModel vm,
    CabinetMaterialItem item,
  ) async {
    final name = item.Nama ?? 'Material';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Material?'),
        content: Text('Yakin ingin menghapus $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await vm.deleteItems(widget.noProduksi, [item]);
    if (!mounted) return;
    _showSnack(
      success ? '✅ Material berhasil dihapus' : (vm.deleteError ?? 'Gagal'),
      backgroundColor: success ? Colors.green : Colors.red,
    );
  }

  // ── Title key ──────────────────────────────────────────────────────────────

  String _fwipTitleKey(FurnitureWipItem e) {
    final part = (e.noFurnitureWIPPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noFurnitureWIP ?? '-');
  }

  // ── Input panel ────────────────────────────────────────────────────────────

  Widget _buildInputPanel({
    required HotStampingProductionInputViewModel vm,
    required bool locked,
    required bool loading,
    required bool canDelete,
    required Map<String, List<FurnitureWipItem>> fwipGroups,
    required List<CabinetMaterialItem> materialAll,
    required Set<int> tempMaterialIds,
  }) {
    int fwipPcs = 0;
    for (final e in fwipGroups.values) {
      for (final i in e) {
        fwipPcs += i.pcs ?? 0;
      }
    }
    final fwipLabelCount = fwipGroups.length;
    final materialLabelCount = materialAll.length;
    final materialPcs = materialAll.fold<int>(
      0,
      (sum, item) => sum + (item.Jumlah ?? 0).toInt(),
    );
    final totalInputLabel = fwipLabelCount + materialLabelCount;
    final totalInputPcs = fwipPcs + materialPcs;

    return Container(
      decoration: productionPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 1, 1, 1),
            child: Row(
              children: [
                productionSectionHeader(
                  Icons.input_rounded,
                  'Label Input',
                  primaryColor: _kStampingPrimary,
                ),
                const Spacer(),
                SaveButtonWithBadge(
                  count: vm.totalTempCount,
                  isLoading: vm.isSubmitting,
                  onPressed: _handleSave,
                ),
                const SizedBox(width: 4),
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
          const Divider(height: 1, color: _kStampingBorder),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductionFolderTabBar(
                    selectedValue: _selectedInputTab,
                    accentColor: _kStampingPrimary,
                    tabs: [
                      ProductionTabItem(
                        value: 'fwip',
                        label: 'Furniture WIP',
                        count: fwipGroups.length,
                      ),
                      ProductionTabItem(
                        value: 'material',
                        label: 'Material Kabinet',
                        count: materialAll.length,
                      ),
                    ],
                    onChanged: (v) {
                      if (_selectedInputTab != v) {
                        setState(() => _selectedInputTab = v);
                      }
                    },
                  ),
                  Expanded(
                    child: ProductionInputCategoryBlock(
                      color: _kStampingPrimary,
                      isLoading: loading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (ctx, c) => SizedBox(
                                width: c.maxWidth,
                                child: _selectedInputTab == 'fwip'
                                    ? _buildFwipTab(
                                        vm: vm,
                                        fwipGroups: fwipGroups,
                                      )
                                    : _buildMaterialTab(
                                        vm: vm,
                                        locked: locked,
                                        canDelete: canDelete,
                                        materialAll: materialAll,
                                        tempMaterialIds: tempMaterialIds,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Footer row: summary + FAB
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (_selectedInputTab == 'fwip') ...[
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _HotStampInputSummaryBar(
                                        totalLabel: fwipLabelCount,
                                        totalPcs: fwipPcs,
                                        color: _kStampingPrimary,
                                      ),
                                      const SizedBox(height: 10),
                                      _HotStampInputGrandTotalBar(
                                        totalItem: totalInputLabel,
                                        totalPcs: totalInputPcs,
                                        color: _kStampingPrimary,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FloatingActionButton(
                                  heroTag: 'fab_scan_stamp_input',
                                  mini: true,
                                  backgroundColor: locked
                                      ? Colors.grey.shade300
                                      : _kStampingPrimary,
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
                              ] else ...[
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _HotStampMaterialSummaryBar(
                                        items: materialAll,
                                        color: _kStampingPrimary,
                                      ),
                                      const SizedBox(height: 10),
                                      _HotStampInputGrandTotalBar(
                                        totalItem: totalInputLabel,
                                        totalPcs: totalInputPcs,
                                        color: _kStampingPrimary,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FloatingActionButton(
                                  heroTag: 'fab_add_material_stamp',
                                  mini: true,
                                  backgroundColor: locked
                                      ? Colors.grey.shade300
                                      : _kStampingPrimary,
                                  foregroundColor: Colors.white,
                                  onPressed: locked
                                      ? null
                                      : () => _openAddMaterialDialog(vm),
                                  child: const Icon(Icons.add),
                                ),
                              ],
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

  // ── FurnitureWIP tab (grid, sama dengan mixer BB) ──────────────────────────

  Widget _buildFwipTab({
    required HotStampingProductionInputViewModel vm,
    required Map<String, List<FurnitureWipItem>> fwipGroups,
  }) {
    return ProductionOutputCategoryContent(
      footer: const SizedBox.shrink(),
      child: fwipGroups.isEmpty
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
                children: fwipGroups.entries.map((entry) {
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
                        Icons.inventory_2_outlined,
                        '${entry.value.length} item',
                      ),
                      (
                        Icons.scale_outlined,
                        '${num2(entry.value.fold<double>(0, (s, i) => s + (i.berat ?? 0)))} kg',
                      ),
                    ],
                    color: _kStampingPrimary,
                    isTemp: vm.hasTemporaryDataForLabel(entry.key),
                    expandable: !hasPartial,
                    isPartialGroup: hasPartial,
                    partialReference: hasPartial
                        ? (entry.value
                                  .firstWhere((x) => x.isPartialRow)
                                  .noFurnitureWIP ??
                              '-')
                        : null,
                    detailsBuilder: () => [],
                    chipItemsBuilder: () {
                      final dbItems =
                          vm
                              .inputsOf(widget.noProduksi)
                              ?.furnitureWip
                              .where((x) => _fwipTitleKey(x) == entry.key) ??
                          const [];
                      final items = [
                        ...vm.tempFurnitureWipPartial.where(
                          (x) => _fwipTitleKey(x) == entry.key,
                        ),
                        ...dbItems,
                        ...vm.tempFurnitureWip.where(
                          (x) => _fwipTitleKey(x) == entry.key,
                        ),
                      ];
                      return items.map((item) {
                        final isTemp =
                            vm.tempFurnitureWip.contains(item) ||
                            vm.tempFurnitureWipPartial.contains(item);
                        return ProductionSakChip(
                          label: item.noFurnitureWIP ?? '-',
                          berat: item.berat,
                          isTemp: isTemp,
                          isPartial: item.isPartialRow,
                          onDelete: isTemp
                              ? () => vm.deleteTempFurnitureWipItem(item)
                              : null,
                        );
                      }).toList();
                    },
                  );
                }).toList(),
              ),
            ),
    );
  }

  // ── Cabinet Material tab (list + delete) ───────────────────────────────────

  Widget _buildMaterialTab({
    required HotStampingProductionInputViewModel vm,
    required bool locked,
    required bool canDelete,
    required List<CabinetMaterialItem> materialAll,
    required Set<int> tempMaterialIds,
  }) {
    if (materialAll.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada material kabinet.\nTambah dengan tombol + di bawah.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: materialAll.length,
      itemBuilder: (context, index) {
        final item = materialAll[index];
        final id = item.IdCabinetMaterial ?? 0;
        final isTemp = id == 0 || tempMaterialIds.contains(id);
        return _MaterialListTile(
          item: item,
          isTemp: isTemp,
          onDeleteTemp: isTemp
              ? () {
                  vm.deleteTempCabinetMaterialItem(item);
                  _showSnack(
                    '✅ Material TEMP dihapus',
                    backgroundColor: Colors.green,
                  );
                }
              : null,
          onDeleteExisting: (!isTemp && canDelete)
              ? () => _deleteExistingMaterial(vm, item)
              : null,
        );
      },
    );
  }

  // ── Add output dialog ──────────────────────────────────────────────────────

  Future<void> _openAddOutputDialog({required VoidCallback onSuccess}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HotStampProductionOutputFormDialog(
        noProduksi: widget.noProduksi,
        tglProduksi: widget.tglProduksi,
        outputJenisId: widget.outputJenisId,
        namaJenis: widget.namaJenis,
      ),
    );
    if (saved == true && mounted) onSuccess();
  }

  Future<void> _openAddRejectOutputDialog({
    required VoidCallback onSuccess,
  }) async {
    final createdNos = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HotStampRejectOutputFormDialog(
        noProduksi: widget.noProduksi,
        tglProduksi: widget.tglProduksi,
      ),
    );

    if (!mounted || createdNos == null || createdNos.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (_) => SuccessStatusDialog(
        title: 'Berhasil Menambah Reject',
        message: createdNos.length > 1
            ? '${createdNos.length} label reject berhasil dibuat.'
            : 'Label reject berhasil dibuat.',
        extraContent: Column(
          mainAxisSize: MainAxisSize.min,
          children: createdNos
              .map(
                (no) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    no,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (mounted) onSuccess();
  }

  // ── Right: output panel ────────────────────────────────────────────────────

  Widget _buildOutputPanel({
    required List<HotStampOutput> outputs,
    required bool isLoading,
    required String? error,
    required bool locked,
    required VoidCallback onRefresh,
  }) {
    final isRejectTab = _selectedOutputTab == 'reject';
    final fwipOutputs = outputs.where((o) => !o.isReject).toList();
    final rejectOutputs = outputs.where((o) => o.isReject).toList();
    final selectedOutputs = isRejectTab ? rejectOutputs : fwipOutputs;
    final totalOutputLabel = outputs.length;
    final totalFwipPcs = fwipOutputs.fold<int>(
      0,
      (sum, output) => sum + output.pcs,
    );
    final totalPcs = selectedOutputs.fold<int>(0, (s, o) => s + o.pcs);
    final totalRejectBerat = selectedOutputs.fold<double>(
      0,
      (sum, output) => sum + output.berat,
    );
    final grandRejectBerat = rejectOutputs.fold<double>(
      0,
      (sum, output) => sum + output.berat,
    );
    final emptyMessage = isRejectTab
        ? 'Belum ada label output reject'
        : 'Belum ada label output furniture WIP';

    return Container(
      decoration: productionPanelDecoration(
        borderColor: _kStampingOutput.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                productionSectionHeader(
                  Icons.output_rounded,
                  'Label Output',
                  iconColor: _kStampingOutput,
                  primaryColor: _kStampingPrimary,
                ),
                const Spacer(),
              ],
            ),
          ),
          const Divider(height: 1, color: _kStampingBorder),

          // ── Body ──────────────────────────────────────────────────
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
                        // Tab bar
                        Row(
                          children: [
                            Expanded(
                              child: ProductionFolderTabBar(
                                selectedValue: _selectedOutputTab,
                                accentColor: _kStampingOutput,
                                tabs: [
                                  ProductionTabItem(
                                    value: 'fwip',
                                    label: 'Furniture WIP',
                                    count: fwipOutputs.length,
                                  ),
                                  ProductionTabItem(
                                    value: 'reject',
                                    label: 'Reject',
                                    count: rejectOutputs.length,
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
                            color: _kStampingOutput,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Output grid
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (ctx, constraints) => SizedBox(
                                      width: constraints.maxWidth,
                                      child: ProductionOutputCategoryContent(
                                        footer: const SizedBox.shrink(),
                                        child: selectedOutputs.isEmpty
                                            ? const Center(
                                                child: SizedBox.shrink(),
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
                                                children: selectedOutputs
                                                    .map(
                                                      (o) => HotStampOutputTile(
                                                        output: o,
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (selectedOutputs.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Center(
                                      child: Text(
                                        emptyMessage,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
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
                                          if (isRejectTab)
                                            _RejectOutputSummaryBar(
                                              totalLabel:
                                                  selectedOutputs.length,
                                              totalBerat: totalRejectBerat,
                                            )
                                          else
                                            HotStampOutputSummaryTile(
                                              totalLabel:
                                                  selectedOutputs.length,
                                              totalPcs: totalPcs,
                                            ),
                                          const SizedBox(height: 10),
                                          HotStampOutputOverallSummaryBar(
                                            totalLabel: totalOutputLabel,
                                            totalFwipPcs: totalFwipPcs,
                                            totalRejectBerat: grandRejectBerat,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    FloatingActionButton(
                                      heroTag: isRejectTab
                                          ? 'fab_add_stamp_reject_output'
                                          : 'fab_add_stamp_output',
                                      mini: true,
                                      backgroundColor: locked
                                          ? Colors.grey.shade300
                                          : _kStampingOutput,
                                      foregroundColor: Colors.white,
                                      onPressed: locked
                                          ? null
                                          : () {
                                              if (isRejectTab) {
                                                _openAddRejectOutputDialog(
                                                  onSuccess: onRefresh,
                                                );
                                                return;
                                              }
                                              _openAddOutputDialog(
                                                onSuccess: onRefresh,
                                              );
                                            },
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

  // ── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<HotStampingProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);
        final perm = context.watch<PermissionViewModel>();
        final locked = widget.isLocked == true;
        final canDelete = perm.can('label_crusher:delete') && !locked;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            // ignore: use_build_context_synchronously
            final nav = Navigator.of(this.context);
            final canPop = await _onWillPop();
            if (canPop && mounted) nav.pop();
          },
          child: Scaffold(
            backgroundColor: _kStampingSurface,
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                ProductionWorkspaceToolbar(
                  noProduksi: widget.noProduksi,
                  isLocked: locked,
                  idMesin: widget.idMesin,
                  namaJenis: widget.namaJenis,
                  tglProduksi: widget.tglProduksi,
                  shift: widget.shift,
                  hourStart: widget.hourStart,
                  hourEnd: widget.hourEnd,
                  primaryColor: _kStampingPrimary,
                  onGanti: locked ? null : _openSplitDialog,
                  onRefresh: () {
                    vm.loadInputs(widget.noProduksi, force: true);
                    _showSnack('Data di-refresh');
                  },
                ),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (err != null) {
                        return Center(
                          child: Text('Gagal memuat inputs:\n$err'),
                        );
                      }

                      final fwipAll = loading
                          ? <FurnitureWipItem>[]
                          : [
                              ...vm.tempFurnitureWip.reversed,
                              ...vm.tempFurnitureWipPartial.reversed,
                              ...?inputs?.furnitureWip,
                            ];

                      final tempMat = vm.tempCabinetMaterial;
                      final dbMat =
                          inputs?.cabinetMaterial ??
                          const <CabinetMaterialItem>[];
                      final materialAll = <CabinetMaterialItem>[
                        ...tempMat,
                        ...dbMat,
                      ];
                      final tempMaterialIds = tempMat
                          .map((x) => x.IdCabinetMaterial ?? 0)
                          .where((id) => id > 0)
                          .toSet();

                      final fwipGroups = _groupBy(fwipAll, _fwipTitleKey);

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
                                fwipGroups: fwipGroups,
                                materialAll: materialAll,
                                tempMaterialIds: tempMaterialIds,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildOutputPanel(
                                outputs: vm.outputsOf(widget.noProduksi) ?? [],
                                isLoading: vm.isOutputsLoading(
                                  widget.noProduksi,
                                ),
                                error: vm.outputsError(widget.noProduksi),
                                locked: locked,
                                onRefresh: () => vm.loadOutputs(
                                  widget.noProduksi,
                                  force: true,
                                ),
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

// ── Helpers ────────────────────────────────────────────────────────────────────

Map<K, List<T>> _groupBy<K, T>(Iterable<T> items, K Function(T) keyFn) {
  final map = <K, List<T>>{};
  for (final item in items) {
    (map[keyFn(item)] ??= []).add(item);
  }
  return map;
}

// ── Material list tile ─────────────────────────────────────────────────────────

class _RejectOutputSummaryBar extends StatelessWidget {
  const _RejectOutputSummaryBar({
    required this.totalLabel,
    required this.totalBerat,
  });

  final int totalLabel;
  final double totalBerat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kStampingOutput.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kStampingOutput.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ProductionInlineStat(
            label: 'Label',
            value: '$totalLabel',
            color: _kStampingOutput,
          ),
          const SizedBox(width: 10),
          ProductionInlineStat(
            label: 'Berat',
            value: '${num2(totalBerat)} kg',
            color: _kStampingOutput,
          ),
        ],
      ),
    );
  }
}

class _HotStampInputSummaryBar extends StatelessWidget {
  const _HotStampInputSummaryBar({
    required this.totalLabel,
    required this.totalPcs,
    required this.color,
  });

  final int totalLabel;
  final int totalPcs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ProductionInlineStat(
            label: 'Label',
            value: '$totalLabel',
            color: color,
          ),
          const SizedBox(width: 10),
          ProductionInlineStat(label: 'PCS', value: '$totalPcs', color: color),
        ],
      ),
    );
  }
}

class _HotStampInputGrandTotalBar extends StatelessWidget {
  const _HotStampInputGrandTotalBar({
    required this.totalItem,
    required this.totalPcs,
    required this.color,
  });

  final int totalItem;
  final int totalPcs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(Icons.summarize_outlined, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              ProductionInlineStat(
                label: 'Item',
                value: '$totalItem',
                color: color,
              ),
              const SizedBox(width: 10),
              ProductionInlineStat(
                label: 'PCS',
                value: '$totalPcs',
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotStampMaterialSummaryBar extends StatelessWidget {
  const _HotStampMaterialSummaryBar({required this.items, required this.color});

  final List<CabinetMaterialItem> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final totalPcs = items.fold<num>(
      0,
      (sum, item) => sum + (item.Jumlah ?? 0),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ProductionInlineStat(
            label: 'Material',
            value: '${items.length}',
            color: color,
          ),
          const SizedBox(width: 10),
          ProductionInlineStat(label: 'PCS', value: '$totalPcs', color: color),
        ],
      ),
    );
  }
}

class _MaterialListTile extends StatelessWidget {
  const _MaterialListTile({
    required this.item,
    required this.isTemp,
    this.onDeleteTemp,
    this.onDeleteExisting,
  });

  final CabinetMaterialItem item;
  final bool isTemp;
  final VoidCallback? onDeleteTemp;
  final VoidCallback? onDeleteExisting;

  @override
  Widget build(BuildContext context) {
    final borderColor = isTemp
        ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
        : const Color(0xFFE2E6EA);
    final bgColor = isTemp ? const Color(0xFFFFFBEB) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.category_outlined,
              size: 16,
              color: Colors.deepPurple.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.Nama ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.Jumlah ?? 0} ${item.namaUom ?? 'unit'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (onDeleteTemp != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
              tooltip: 'Hapus temp',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onDeleteTemp,
            )
          else if (onDeleteExisting != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.grey.shade400,
              ),
              tooltip: 'Hapus material',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onDeleteExisting,
            ),
        ],
      ),
    );
  }
}

// ── Material summary bar ───────────────────────────────────────────────────────

class _MaterialSummaryBar extends StatelessWidget {
  const _MaterialSummaryBar({required this.items, required this.color});

  final List<CabinetMaterialItem> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<num>(0, (s, i) => s + (i.Jumlah ?? 0));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '${items.length} jenis  •  $total unit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
