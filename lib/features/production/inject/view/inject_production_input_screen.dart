import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/view/app_shell.dart';
import 'package:pps_tablet/features/production/shared/shared.dart';

import '../model/inject_production_model.dart' show InjectOutputJenis;

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/scan_label_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/widgets/add_cabinet_material_dialog.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../model/inject_output_model.dart';
import '../model/inject_production_inputs_model.dart';
import '../view_model/inject_production_input_view_model.dart';
import '../model/inject_formula_model.dart';
import '../model/inject_validate_label_model.dart';
import '../repository/inject_validate_label_repository.dart';
import '../view_model/inject_formula_view_model.dart';
import '../widgets/inject_formula_dialog.dart';
import '../widgets/inject_split_time_dialog.dart';

// ── Colour palette ─────────────────────────────────────────────────────────────
const _kInjectPrimary = Color(0xFF0277BD); // biru — input
const _kInjectOutput = Color(0xFF00695C); // darker teal — output
const _kInjectSurface = Color(0xFFF8F9FB);
const _kInjectBorder = Color(0xFFE2E6EA);

class InjectProductionInputScreen extends StatefulWidget {
  final String noProduksi;
  final bool? isLocked;
  final DateTime? lastClosedDate;

  final int? idMesin;
  final String? namaJenis;
  final String? namaCetakan;
  final String? namaWarna;
  final String? namaFurnitureMaterial;
  final DateTime? tglProduksi;
  final int? shift;
  final String? hourStart;
  final String? hourEnd;

  /// 'furnitureWip' | 'barangjadi' | null (null = bebas)
  final String? outputCategory;
  final List<InjectOutputJenis> lockedOutputs;

  const InjectProductionInputScreen({
    super.key,
    required this.noProduksi,
    this.isLocked,
    this.lastClosedDate,
    this.idMesin,
    this.namaJenis,
    this.namaCetakan,
    this.namaWarna,
    this.namaFurnitureMaterial,
    this.tglProduksi,
    this.shift,
    this.hourStart,
    this.hourEnd,
    this.outputCategory,
    this.lockedOutputs = const [],
  });

  @override
  State<InjectProductionInputScreen> createState() =>
      _InjectProductionInputScreenState();
}

class _InjectProductionInputScreenState
    extends State<InjectProductionInputScreen> {
  String _selectedInputTab = 'fwip';
  late String _selectedOutputTab;
  bool _outputOnLeft = false;

  // ── Formula-driven tab filtering ──────────────────────────────────────────

  /// Kode kategori formula → tab value pada input panel
  static const _kKodeToTab = {
    'furniturewip': 'fwip',
    'mixer': 'mixer',
    'broker': 'broker',
    'gilingan': 'gilingan',
  };

  /// Hitung tab yang boleh tampil berdasarkan formula.
  /// - null (belum load)  → semua tab tampil
  /// - ada tapi kode kosong → tidak ada tab yang tampil
  /// - ada dengan kode     → hanya tab sesuai kode + material
  Set<String> _visibleInputTabs(InjectFormulaData? formula) {
    if (formula == null) return _kKodeToTab.values.toSet()..add('material');

    final kodes = <String>{};
    for (final out in formula.outputs) {
      for (final f in out.formulas) {
        kodes.add(f.inputKategoriKode.toLowerCase());
      }
    }

    if (kodes.isEmpty) return const {};

    final allowed = <String>{};
    for (final entry in _kKodeToTab.entries) {
      if (kodes.contains(entry.key)) allowed.add(entry.value);
    }
    allowed.add('material');
    return allowed;
  }

  List<BreadcrumbSegment> _prevBreadcrumb = [];
  String get _breadcrumbLabel => widget.noProduksi;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedOutputTab = widget.outputCategory == 'barangjadi' ? 'bj' : 'fwip';
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

      final vm = context.read<InjectProductionInputViewModel>();
      if (vm.inputsOf(widget.noProduksi) == null &&
          !vm.isInputsLoading(widget.noProduksi)) {
        vm.loadInputs(widget.noProduksi);
      }
      if (vm.outputsOf(widget.noProduksi) == null &&
          !vm.isOutputsLoading(widget.noProduksi)) {
        vm.loadOutputs(widget.noProduksi);
      }
      if (vm.bjOutputsOf(widget.noProduksi) == null &&
          !vm.isBjOutputsLoading(widget.noProduksi)) {
        vm.loadBjOutputs(widget.noProduksi);
      }
      if (vm.rejectOutputsOf(widget.noProduksi) == null &&
          !vm.isRejectOutputsLoading(widget.noProduksi)) {
        vm.loadRejectOutputs(widget.noProduksi);
      }
      if (vm.bonggolanOutputsOf(widget.noProduksi) == null &&
          !vm.isBonggolanOutputsLoading(widget.noProduksi)) {
        vm.loadBonggolanOutputs(widget.noProduksi);
      }

      context.read<InjectFormulaViewModel>().load(widget.noProduksi);
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
    final vm = context.read<InjectProductionInputViewModel>();
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
    final vm = context.read<InjectProductionInputViewModel>();
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
    final vm = context.read<InjectProductionInputViewModel>();
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

  // ── Split Time (Ganti) ────────────────────────────────────────────────────

  Future<void> _openSplitTimeDialog() async {
    if (widget.idMesin == null || widget.tglProduksi == null) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InjectSplitTimeDialog(
        idMesin: widget.idMesin!,
        tglProduksi: widget.tglProduksi!,
        currentHourEnd: widget.hourEnd,
        currentCetakan: widget.namaCetakan,
        currentWarna: widget.namaWarna,
        currentMaterial: widget.namaFurnitureMaterial,
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _showSnack('✅ Produksi berhasil diganti', backgroundColor: Colors.green);
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ── Scan / Lookup ──────────────────────────────────────────────────────────

  Future<void> _openScanDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ScanLabelDialog(
        manualHint: 'BB. / D. / H. / V.',
        acceptedLabels: const [
          (prefix: 'BB', label: 'Furniture WIP'),
          (prefix: 'D', label: 'Broker'),
          (prefix: 'H', label: 'Mixer'),
          (prefix: 'V', label: 'Gilingan'),
        ],
        onLookup: _onCodeReady,
      ),
    );
  }

  Future<String?> _onCodeReady(String code) async {
    // ── Validasi formula terlebih dahulu ──────────────────────────────────────
    try {
      final validateResult =
          await InjectValidateLabelRepository().validate(widget.noProduksi, code);
      if (!mounted) return 'Halaman sudah tidak aktif';
      if (!validateResult.valid) {
        await showDialog<void>(
          context: context,
          builder: (_) => ErrorStatusDialog(
            title: 'Label Tidak Valid',
            message: validateResult.reason ?? 'Label tidak valid untuk produksi ini',
          ),
        );
        return null;
      }
    } catch (_) {
      // Jika endpoint tidak tersedia / error jaringan, lanjut ke alur normal
    }

    // ── Lookup & tambah ke temp ───────────────────────────────────────────────
    final vm = context.read<InjectProductionInputViewModel>();
    final res = await vm.lookupLabel(code, force: true);
    if (!mounted) return 'Halaman sudah tidak aktif';
    if (vm.lookupError != null) return 'Gagal ambil data: ${vm.lookupError}';
    if (res == null || res.found == false || res.data.isEmpty) {
      return 'Label "$code" tidak memiliki data yang tersedia.';
    }

    await _handleFullMode(vm, res);
    return null;
  }

  Future<void> _handleFullMode(
    InjectProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      _showSnack('Semua item untuk ${labelCode ?? "label ini"} sudah ada.');
      return;
    }

    vm.clearPicks();
    vm.pickAllNew(widget.noProduksi);

    final result = vm.commitPickedToTemp(noProduksi: widget.noProduksi);

    _showSnack(
      result.added > 0
          ? '✅ Auto-added ${result.added} item${result.skipped > 0 ? ' • Duplikat terlewati ${result.skipped}' : ''}'
          : 'Tidak ada item baru ditambahkan',
      backgroundColor: result.added > 0 ? Colors.green : Colors.orange,
    );
  }

  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;
    if (item is BrokerItem) return item.noBroker;
    if (item is MixerItem) return item.noMixer;
    if (item is GilinganItem) return item.noGilingan;
    if (item is FurnitureWipItem) {
      return (item.noFurnitureWIPPartial ?? '').trim().isNotEmpty
          ? item.noFurnitureWIPPartial
          : item.noFurnitureWIP;
    }
    return null;
  }

  // ── Cabinet Material ───────────────────────────────────────────────────────

  Future<void> _openAddMaterialDialog(InjectProductionInputViewModel vm) async {
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
    InjectProductionInputViewModel vm,
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

  // ── Title keys ─────────────────────────────────────────────────────────────

  String _fwipTitleKey(FurnitureWipItem e) {
    final part = (e.noFurnitureWIPPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noFurnitureWIP ?? '-');
  }

  String _brokerTitleKey(BrokerItem e) {
    final part = (e.noBrokerPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noBroker ?? '-');
  }

  String _mixerTitleKey(MixerItem e) {
    final part = (e.noMixerPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noMixer ?? '-');
  }

  String _gilinganTitleKey(GilinganItem e) {
    final part = (e.noGilinganPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noGilingan ?? '-');
  }

  // ── Input panel ────────────────────────────────────────────────────────────

  Widget _buildInputPanel({
    required InjectProductionInputViewModel vm,
    required bool locked,
    required bool loading,
    required bool canDelete,
    required Map<String, List<FurnitureWipItem>> fwipGroups,
    required Map<String, List<BrokerItem>> brokerGroups,
    required Map<String, List<MixerItem>> mixerGroups,
    required Map<String, List<GilinganItem>> gilinganGroups,
    required List<CabinetMaterialItem> materialAll,
    required Set<int> tempMaterialIds,
  }) {
    // ── per-tab metrics ────────────────────────────────────────────
    double fwipBerat = 0;
    int fwipPcs = 0;
    for (final items in fwipGroups.values) {
      for (final i in items) {
        fwipPcs += i.pcs ?? 0;
        fwipBerat += i.berat ?? 0;
      }
    }
    int brokerSak = 0;
    double brokerBerat = 0;
    for (final items in brokerGroups.values) {
      for (final i in items) {
        brokerSak += 1;
        brokerBerat += i.berat ?? 0;
      }
    }
    int mixerSak = 0;
    double mixerBerat = 0;
    for (final items in mixerGroups.values) {
      for (final i in items) {
        mixerSak += 1;
        mixerBerat += i.berat ?? 0;
      }
    }
    double gilinganBerat = 0;
    for (final items in gilinganGroups.values) {
      for (final i in items) {
        gilinganBerat += i.berat ?? 0;
      }
    }
    final materialCount = materialAll.length;

    // ── grand total ────────────────────────────────────────────────
    final grandLabel =
        fwipGroups.length +
        brokerGroups.length +
        mixerGroups.length +
        gilinganGroups.length +
        materialCount;
    final grandSak = brokerSak + mixerSak;
    final grandBerat = fwipBerat + brokerBerat + mixerBerat + gilinganBerat;

    // ── active-tab summary ─────────────────────────────────────────
    SectionSummary activeTabSummary() {
      switch (_selectedInputTab) {
        case 'fwip':
          return SectionSummary(
            totalData: fwipGroups.length,
            totalSak: fwipPcs,
            totalBerat: 0,
          );
        case 'broker':
          return SectionSummary(
            totalData: brokerGroups.length,
            totalSak: brokerSak,
            totalBerat: brokerBerat,
          );
        case 'mixer':
          return SectionSummary(
            totalData: mixerGroups.length,
            totalSak: mixerSak,
            totalBerat: mixerBerat,
          );
        case 'gilingan':
          return SectionSummary(
            totalData: gilinganGroups.length,
            totalSak: 0,
            totalBerat: gilinganBerat,
          );
        case 'material':
          return SectionSummary(
            totalData: materialCount,
            totalSak: materialCount,
            totalBerat: 0,
          );
        default:
          return SectionSummary(totalData: 0, totalSak: 0, totalBerat: 0);
      }
    }

    final tabCounts = {
      'fwip': fwipGroups.length,
      'broker': brokerGroups.length,
      'mixer': mixerGroups.length,
      'gilingan': gilinganGroups.length,
      'material': materialCount,
    };

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
                  primaryColor: _kInjectPrimary,
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
          const Divider(height: 1, color: _kInjectBorder),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Builder(
                    builder: (ctx) {
                      final formulaVm = ctx.watch<InjectFormulaViewModel>();
                      final visible = _visibleInputTabs(formulaVm.data);

                      // Formula sudah load & tidak ada kategori → tampilkan notice
                      if (formulaVm.data != null && visible.isEmpty) {
                        return Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _kInjectPrimary.withValues(
                                      alpha: 0.06,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.science_outlined,
                                    size: 28,
                                    color: _kInjectPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Silahkan isi formula terlebih dahulu',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gunakan tombol Formula di toolbar\nuntuk mengatur kategori input',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Jika tab aktif tidak lagi visible, pindah ke tab pertama
                      if (visible.isNotEmpty &&
                          !visible.contains(_selectedInputTab)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _selectedInputTab = visible.first;
                            });
                          }
                        });
                      }

                      const allTabs = [
                        (value: 'fwip', label: 'Furniture WIP'),
                        (value: 'broker', label: 'Broker'),
                        (value: 'mixer', label: 'Mixer'),
                        (value: 'gilingan', label: 'Gilingan'),
                        (value: 'material', label: 'Material'),
                      ];

                      return ProductionFolderTabBar(
                        selectedValue: _selectedInputTab,
                        accentColor: _kInjectPrimary,
                        tabs: [
                          for (final t in allTabs)
                            if (visible.contains(t.value))
                              ProductionTabItem(
                                value: t.value,
                                label: t.label,
                                count: tabCounts[t.value] ?? 0,
                              ),
                        ],
                        onChanged: (v) {
                          if (_selectedInputTab != v) {
                            setState(() => _selectedInputTab = v);
                          }
                        },
                      );
                    },
                  ),
                  Expanded(
                    child: ProductionInputCategoryBlock(
                      color: _kInjectPrimary,
                      isLoading: loading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (ctx, c) => SizedBox(
                                width: c.maxWidth,
                                child: _buildActiveInputTab(
                                  vm: vm,
                                  locked: locked,
                                  canDelete: canDelete,
                                  fwipGroups: fwipGroups,
                                  brokerGroups: brokerGroups,
                                  mixerGroups: mixerGroups,
                                  gilinganGroups: gilinganGroups,
                                  materialAll: materialAll,
                                  tempMaterialIds: tempMaterialIds,
                                  constraints: c,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProductionCategorySummaryTile(
                                      summary: activeTabSummary(),
                                      accentColor: _kInjectPrimary,
                                      sakLabel:
                                          (_selectedInputTab == 'fwip' ||
                                              _selectedInputTab == 'material')
                                          ? 'Qty'
                                          : 'Sak',
                                      showBerat:
                                          _selectedInputTab != 'fwip' &&
                                          _selectedInputTab != 'material',
                                      showLabel:
                                          _selectedInputTab != 'material',
                                    ),
                                    const SizedBox(height: 6),
                                    ProductionInputGrandTotalBar(
                                      totalLabel: grandLabel,
                                      totalSak: grandSak,
                                      totalBerat: grandBerat,
                                      color: _kInjectPrimary,
                                      sakLabel: 'Qty',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (_selectedInputTab == 'material')
                                FloatingActionButton(
                                  heroTag: 'fab_add_inject_material',
                                  mini: true,
                                  backgroundColor: locked
                                      ? Colors.grey.shade300
                                      : _kInjectPrimary,
                                  foregroundColor: Colors.white,
                                  onPressed: locked
                                      ? null
                                      : () => _openAddMaterialDialog(vm),
                                  child: const Icon(Icons.add),
                                )
                              else
                                FloatingActionButton(
                                  heroTag: 'fab_scan_inject_input',
                                  mini: true,
                                  backgroundColor: locked
                                      ? Colors.grey.shade300
                                      : _kInjectPrimary,
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

  Widget _buildActiveInputTab({
    required InjectProductionInputViewModel vm,
    required bool locked,
    required bool canDelete,
    required Map<String, List<FurnitureWipItem>> fwipGroups,
    required Map<String, List<BrokerItem>> brokerGroups,
    required Map<String, List<MixerItem>> mixerGroups,
    required Map<String, List<GilinganItem>> gilinganGroups,
    required List<CabinetMaterialItem> materialAll,
    required Set<int> tempMaterialIds,
    required BoxConstraints constraints,
  }) {
    switch (_selectedInputTab) {
      case 'fwip':
        return _buildFwipTab(
          vm: vm,
          fwipGroups: fwipGroups,
          constraints: constraints,
        );
      case 'broker':
        return _buildLabelGroupTab<BrokerItem>(
          groups: brokerGroups,
          emptyMessage: 'Belum ada label Broker',
          constraints: constraints,
          tileBuilder: (key, items) => ProductionInputGroupTile(
            title: key,
            headerSubtitle:
                (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
            tileMetrics: [
              (
                Icons.scale_outlined,
                '${items.fold<double>(0, (s, i) => s + (i.berat ?? 0)).toStringAsFixed(1)} kg',
              ),
            ],
            color: _kInjectPrimary,
            isTemp: vm.hasTemporaryDataForLabel(key),
            expandable: true,
            isPartialGroup: items.any((x) => x.isPartialRow),
            detailsBuilder: () => [],
            chipItemsBuilder: () => items.map((item) {
              final isTemp =
                  vm.tempBroker.contains(item) ||
                  vm.tempBrokerPartial.contains(item);
              return ProductionSakChip(
                label: item.noBroker ?? '-',
                berat: item.berat,
                isTemp: isTemp,
                isPartial: item.isPartialRow,
                onDelete: isTemp ? () => vm.deleteTempBrokerItem(item) : null,
              );
            }).toList(),
          ),
        );
      case 'mixer':
        return _buildLabelGroupTab<MixerItem>(
          groups: mixerGroups,
          emptyMessage: 'Belum ada label Mixer',
          constraints: constraints,
          tileBuilder: (key, items) => ProductionInputGroupTile(
            title: key,
            headerSubtitle:
                (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
            tileMetrics: [
              (
                Icons.scale_outlined,
                '${items.fold<double>(0, (s, i) => s + (i.berat ?? 0)).toStringAsFixed(1)} kg',
              ),
            ],
            color: _kInjectPrimary,
            isTemp: vm.hasTemporaryDataForLabel(key),
            expandable: true,
            isPartialGroup: items.any((x) => x.isPartialRow),
            detailsBuilder: () => [],
            chipItemsBuilder: () => items.map((item) {
              final isTemp =
                  vm.tempMixer.contains(item) ||
                  vm.tempMixerPartial.contains(item);
              return ProductionSakChip(
                label: item.noMixer ?? '-',
                berat: item.berat,
                isTemp: isTemp,
                isPartial: item.isPartialRow,
                onDelete: isTemp ? () => vm.deleteTempMixerItem(item) : null,
              );
            }).toList(),
          ),
        );
      case 'gilingan':
        return _buildLabelGroupTab<GilinganItem>(
          groups: gilinganGroups,
          emptyMessage: 'Belum ada label Gilingan',
          constraints: constraints,
          tileBuilder: (key, items) => ProductionInputGroupTile(
            title: key,
            headerSubtitle:
                (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
            tileMetrics: [
              (
                Icons.scale_outlined,
                '${items.fold<double>(0, (s, i) => s + (i.berat ?? 0)).toStringAsFixed(1)} kg',
              ),
            ],
            color: _kInjectPrimary,
            isTemp: vm.hasTemporaryDataForLabel(key),
            expandable: true,
            isPartialGroup: items.any((x) => x.isPartialRow),
            detailsBuilder: () => [],
            chipItemsBuilder: () => items.map((item) {
              final isTemp =
                  vm.tempGilingan.contains(item) ||
                  vm.tempGilinganPartial.contains(item);
              return ProductionSakChip(
                label: item.noGilingan ?? '-',
                berat: item.berat,
                isTemp: isTemp,
                isPartial: item.isPartialRow,
                onDelete: isTemp ? () => vm.deleteTempGilinganItem(item) : null,
              );
            }).toList(),
          ),
        );
      case 'material':
        return _buildMaterialTab(
          vm: vm,
          locked: locked,
          canDelete: canDelete,
          materialAll: materialAll,
          tempMaterialIds: tempMaterialIds,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFwipTab({
    required InjectProductionInputViewModel vm,
    required Map<String, List<FurnitureWipItem>> fwipGroups,
    required BoxConstraints constraints,
  }) {
    return ProductionOutputCategoryContent(
      footer: const SizedBox.shrink(),
      child: fwipGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : GridView(
              padding: const EdgeInsets.all(6),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 380 ? 2 : 3,
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
                      '${entry.value.fold<int>(0, (s, i) => s + (i.pcs ?? 0))} pcs',
                    ),
                  ],
                  color: _kInjectPrimary,
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
    );
  }

  Widget _buildLabelGroupTab<T>({
    required Map<String, List<T>> groups,
    required String emptyMessage,
    required BoxConstraints constraints,
    required Widget Function(String key, List<T> items) tileBuilder,
  }) {
    if (groups.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return GridView(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: constraints.maxWidth < 380 ? 2 : 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 72,
      ),
      children: groups.entries.map((e) => tileBuilder(e.key, e.value)).toList(),
    );
  }

  Widget _buildMaterialTab({
    required InjectProductionInputViewModel vm,
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

  // ── Output FAB visibility ────────────────────────────────────────────────

  bool _isFabVisible({
    required bool isBj,
    required bool isReject,
    required bool isBonggolan,
  }) {
    // Reject dan Bonggolan selalu tampil
    if (isReject || isBonggolan) return true;
    final cat = widget.outputCategory;
    if (cat == null) return true; // tidak ada kunci, semua tampil
    if (isBj) return cat == 'barangjadi';
    return cat == 'furnitureWip'; // tab fwip
  }

  // ── Output FAB actions ────────────────────────────────────────────────────

  Future<InjectOutputJenis?> _pickOutputJenis(
    List<InjectOutputJenis> options,
  ) async {
    if (options.length == 1) return options.first;
    return showDialog<InjectOutputJenis>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _kInjectOutput.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.list_alt_outlined,
                        color: _kInjectOutput,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Pilih Jenis Output',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _kInjectBorder),
              // Options list
              ...options.asMap().entries.map((entry) {
                final i = entry.key;
                final o = entry.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(o),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _kInjectOutput.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kInjectOutput,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                o.namaJenis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < options.length - 1)
                      const Divider(
                        height: 1,
                        color: _kInjectBorder,
                        indent: 18,
                        endIndent: 18,
                      ),
                  ],
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddFwipOutputDialog(VoidCallback onRefresh) async {
    int? lockedId;
    String? lockedNama;
    if (widget.lockedOutputs.isNotEmpty) {
      final picked = await _pickOutputJenis(widget.lockedOutputs);
      if (picked == null || !mounted) return;
      lockedId = picked.idJenis;
      lockedNama = picked.namaJenis;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductionFwipOutputFormDialog(
        noProduksi: widget.noProduksi,
        tglProduksi: widget.tglProduksi,
        accentColor: _kInjectOutput,
        lockedIdJenis: lockedId,
        lockedNamaJenis: lockedNama,
      ),
    );
    if (result == true) onRefresh();
  }

  Future<void> _openAddBjOutputDialog(VoidCallback onRefresh) async {
    int? lockedId;
    String? lockedNama;
    if (widget.lockedOutputs.isNotEmpty) {
      final picked = await _pickOutputJenis(widget.lockedOutputs);
      if (picked == null || !mounted) return;
      lockedId = picked.idJenis;
      lockedNama = picked.namaJenis;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductionBjOutputFormDialog(
        noProduksi: widget.noProduksi,
        tglProduksi: widget.tglProduksi,
        accentColor: _kInjectOutput,
        lockedIdJenis: lockedId,
        lockedNamaJenis: lockedNama,
      ),
    );
    if (result == true) onRefresh();
  }

  Future<void> _openAddRejectOutputDialog(VoidCallback onRefresh) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductionRejectOutputFormDialog(
        noProduksi: widget.noProduksi,
        tglProduksi: widget.tglProduksi,
        accentColor: _kInjectOutput,
      ),
    );
    if (result != null && result != false) onRefresh();
  }

  Future<void> _openAddBonggolanOutputDialog(VoidCallback onRefresh) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductionBonggolanOutputFormDialog(
        noProduksi: widget.noProduksi,
        tglProduksi: widget.tglProduksi,
        accentColor: _kInjectOutput,
      ),
    );
    if (result == true) onRefresh();
  }

  // ── Output panel ───────────────────────────────────────────────────────────

  Widget _buildOutputPanel({
    required List<InjectOutputItem> fwipOutputs,
    required bool fwipLoading,
    required String? fwipError,
    required List<InjectBjOutputItem> bjOutputs,
    required bool bjLoading,
    required String? bjError,
    required List<InjectRejectOutputItem> rejectOutputs,
    required bool rejectLoading,
    required String? rejectError,
    required List<InjectBonggolanOutputItem> bonggolanOutputs,
    required bool bonggolanLoading,
    required String? bonggolanError,
    required VoidCallback onRefresh,
  }) {
    final isReject = _selectedOutputTab == 'reject';
    final isBj = _selectedOutputTab == 'bj';
    final isBonggolan = _selectedOutputTab == 'bonggolan';
    final isLoading = isBonggolan
        ? bonggolanLoading
        : isReject
        ? rejectLoading
        : isBj
        ? bjLoading
        : fwipLoading;
    final error = isBonggolan
        ? bonggolanError
        : isReject
        ? rejectError
        : isBj
        ? bjError
        : fwipError;
    final fwipPcs = fwipOutputs.fold<int>(0, (s, o) => s + o.pcs);
    final fwipBerat = fwipOutputs.fold<double>(0, (s, o) => s + o.berat);
    final bjPcs = bjOutputs.fold<int>(0, (s, o) => s + o.pcs);
    final rejectBerat = rejectOutputs.fold<double>(0, (s, o) => s + o.berat);
    final bonggolanBerat = bonggolanOutputs.fold<double>(
      0,
      (s, o) => s + o.berat,
    );

    return Container(
      decoration: productionPanelDecoration(
        borderColor: _kInjectOutput.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 1, 1, 1),
            child: Row(
              children: [
                productionSectionHeader(
                  Icons.output_rounded,
                  'Label Output',
                  iconColor: _kInjectOutput,
                  primaryColor: _kInjectPrimary,
                ),
                const Spacer(),
                Opacity(
                  opacity: 0,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kInjectBorder),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[
                    ProductionOutputErrorBanner(message: error),
                    const SizedBox(height: 10),
                  ],
                  ProductionFolderTabBar(
                    selectedValue: _selectedOutputTab,
                    accentColor: _kInjectOutput,
                    tabs: [
                      if (widget.outputCategory != 'barangjadi')
                        ProductionTabItem(
                          value: 'fwip',
                          label: 'Furniture WIP',
                          count: fwipOutputs.length,
                        ),
                      if (widget.outputCategory != 'furnitureWip')
                        ProductionTabItem(
                          value: 'bj',
                          label: 'Barang Jadi',
                          count: bjOutputs.length,
                        ),
                      ProductionTabItem(
                        value: 'reject',
                        label: 'Reject',
                        count: rejectOutputs.length,
                      ),
                      ProductionTabItem(
                        value: 'bonggolan',
                        label: 'Bonggolan',
                        count: bonggolanOutputs.length,
                      ),
                    ],
                    onChanged: (v) {
                      if (_selectedOutputTab == v) return;
                      setState(() => _selectedOutputTab = v);
                    },
                  ),
                  Expanded(
                    child: ProductionInputCategoryBlock(
                      color: _kInjectOutput,
                      isLoading: isLoading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (ctx, c) =>
                                  ProductionOutputCategoryContent(
                                    footer: const SizedBox.shrink(),
                                    child: isBonggolan
                                        ? _buildBonggolanOutputGrid(
                                            bonggolanOutputs,
                                            c,
                                          )
                                        : isReject
                                        ? _buildRejectOutputGrid(
                                            rejectOutputs,
                                            c,
                                          )
                                        : isBj
                                        ? _buildBjOutputGrid(bjOutputs, c)
                                        : _buildFwipOutputGrid(fwipOutputs, c),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProductionCategorySummaryTile(
                                      summary: SectionSummary(
                                        totalData: isBonggolan
                                            ? bonggolanOutputs.length
                                            : isReject
                                            ? rejectOutputs.length
                                            : isBj
                                            ? bjOutputs.length
                                            : fwipOutputs.length,
                                        totalSak: isBj
                                            ? bjPcs
                                            : (!isBonggolan && !isReject)
                                            ? fwipPcs
                                            : 0,
                                        totalBerat: isBonggolan
                                            ? bonggolanBerat
                                            : isReject
                                            ? rejectBerat
                                            : fwipBerat,
                                      ),
                                      accentColor: _kInjectOutput,
                                      sakLabel: 'Qty',
                                    ),
                                    const SizedBox(height: 6),
                                    ProductionInputGrandTotalBar(
                                      totalLabel:
                                          fwipOutputs.length +
                                          bjOutputs.length +
                                          rejectOutputs.length +
                                          bonggolanOutputs.length,
                                      totalSak: fwipPcs + bjPcs,
                                      totalBerat:
                                          fwipBerat +
                                          rejectBerat +
                                          bonggolanBerat,
                                      color: _kInjectOutput,
                                      sakLabel: 'Qty',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (_isFabVisible(
                                isBj: isBj,
                                isReject: isReject,
                                isBonggolan: isBonggolan,
                              ))
                                FloatingActionButton(
                                  heroTag:
                                      'fab_add_inject_output_$_selectedOutputTab',
                                  mini: true,
                                  backgroundColor: widget.isLocked == true
                                      ? Colors.grey.shade300
                                      : _kInjectOutput,
                                  foregroundColor: Colors.white,
                                  onPressed: widget.isLocked == true
                                      ? null
                                      : () {
                                          if (isBonggolan) {
                                            _openAddBonggolanOutputDialog(
                                              onRefresh,
                                            );
                                          } else if (isReject) {
                                            _openAddRejectOutputDialog(
                                              onRefresh,
                                            );
                                          } else if (isBj) {
                                            _openAddBjOutputDialog(onRefresh);
                                          } else {
                                            _openAddFwipOutputDialog(onRefresh);
                                          }
                                        },
                                  child: const Icon(Icons.add),
                                )
                              else
                                const SizedBox(width: 40),
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

  Widget _buildFwipOutputGrid(
    List<InjectOutputItem> outputs,
    BoxConstraints c,
  ) {
    if (outputs.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada label output furniture WIP',
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return GridView(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: c.maxWidth < 380 ? 2 : 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 78,
      ),
      children: outputs
          .map(
            (o) => ProductionFwipOutputTile(
              labelCode: o.noFurnitureWip,
              namaJenis: o.namaJenis,
              pcs: o.pcs,
              berat: o.berat,
              isPrinted: o.hasBeenPrinted,
              accentColor: _kInjectOutput,
            ),
          )
          .toList(),
    );
  }

  Widget _buildBonggolanOutputGrid(
    List<InjectBonggolanOutputItem> outputs,
    BoxConstraints c,
  ) {
    if (outputs.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada label output bonggolan',
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return GridView(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: c.maxWidth < 380 ? 2 : 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 78,
      ),
      children: outputs
          .map(
            (o) => ProductionBonggolanOutputTile(
              labelCode: o.noBonggolan,
              namaJenis: o.namaBonggolan,
              berat: o.berat,
              isPrinted: o.isPrinted,
              accentColor: _kInjectOutput,
            ),
          )
          .toList(),
    );
  }

  Widget _buildRejectOutputGrid(
    List<InjectRejectOutputItem> outputs,
    BoxConstraints c,
  ) {
    if (outputs.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada label output reject',
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return GridView(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: c.maxWidth < 380 ? 2 : 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 78,
      ),
      children: outputs
          .map(
            (o) => ProductionRejectOutputTile(
              labelCode: o.noReject,
              namaJenis: o.namaJenis,
              berat: o.berat,
              isPrinted: o.isPrinted,
              pcs: o.pcs,
              accentColor: _kInjectOutput,
            ),
          )
          .toList(),
    );
  }

  Widget _buildBjOutputGrid(
    List<InjectBjOutputItem> outputs,
    BoxConstraints c,
  ) {
    if (outputs.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada label output barang jadi',
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return GridView(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: c.maxWidth < 380 ? 2 : 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 78,
      ),
      children: outputs
          .map(
            (o) => ProductionBjOutputTile(
              labelCode: o.noBj,
              namaJenis: o.namaJenis,
              pcs: o.pcs,
              isPrinted: o.isPrinted,
              accentColor: _kInjectOutput,
            ),
          )
          .toList(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<InjectProductionInputViewModel>(
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
            backgroundColor: _kInjectSurface,
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                ProductionWorkspaceToolbar(
                  noProduksi: widget.noProduksi,
                  isLocked: locked,
                  idMesin: widget.idMesin,
                  namaJenis: widget.namaJenis,
                  namaCetakan: widget.namaCetakan,
                  namaWarna: widget.namaWarna,
                  namaFurnitureMaterial: widget.namaFurnitureMaterial,
                  tglProduksi: widget.tglProduksi,
                  shift: widget.shift,
                  hourStart: widget.hourStart,
                  hourEnd: widget.hourEnd,
                  showTimeInfo: false,
                  primaryColor: _kInjectPrimary,
                  onGanti: _openSplitTimeDialog,
                  onRefresh: () {
                    vm.loadInputs(widget.noProduksi, force: true);
                    vm.loadOutputs(widget.noProduksi, force: true);
                    vm.loadBjOutputs(widget.noProduksi, force: true);
                    vm.loadRejectOutputs(widget.noProduksi, force: true);
                    vm.loadBonggolanOutputs(widget.noProduksi, force: true);
                    _showSnack('Data di-refresh');
                  },
                  trailingActions: [
                    const SizedBox(width: 4),
                    Consumer<InjectFormulaViewModel>(
                      builder: (_, fvm, __) => SizedBox(
                        height: 26,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            foregroundColor: _kInjectPrimary,
                            backgroundColor: _kInjectPrimary.withValues(
                              alpha: 0.07,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: fvm.isLoading
                              ? null
                              : () {
                                  final data = fvm.data;
                                  if (data == null) return;
                                  showDialog<void>(
                                    context: context,
                                    builder: (_) =>
                                        InjectFormulaDialog(data: data),
                                  );
                                },
                          icon: fvm.isLoading
                              ? const SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                  ),
                                )
                              : const Icon(Icons.science_outlined, size: 13),
                          label: const Text(
                            'Formula',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: IconButton(
                        tooltip: 'Tukar posisi panel',
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            setState(() => _outputOnLeft = !_outputOnLeft),
                        icon: Icon(
                          Icons.swap_horiz,
                          size: 15,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
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
                      final brokerAll = loading
                          ? <BrokerItem>[]
                          : [
                              ...vm.tempBroker.reversed,
                              ...vm.tempBrokerPartial.reversed,
                              ...?inputs?.broker,
                            ];
                      final mixerAll = loading
                          ? <MixerItem>[]
                          : [
                              ...vm.tempMixer.reversed,
                              ...vm.tempMixerPartial.reversed,
                              ...?inputs?.mixer,
                            ];
                      final gilinganAll = loading
                          ? <GilinganItem>[]
                          : [
                              ...vm.tempGilingan.reversed,
                              ...vm.tempGilinganPartial.reversed,
                              ...?inputs?.gilingan,
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
                      final brokerGroups = _groupBy(brokerAll, _brokerTitleKey);
                      final mixerGroups = _groupBy(mixerAll, _mixerTitleKey);
                      final gilinganGroups = _groupBy(
                        gilinganAll,
                        _gilinganTitleKey,
                      );

                      final outputPanel = Expanded(
                        child: _buildOutputPanel(
                          fwipOutputs: vm.outputsOf(widget.noProduksi) ?? [],
                          fwipLoading: vm.isOutputsLoading(widget.noProduksi),
                          fwipError: vm.outputsError(widget.noProduksi),
                          bjOutputs: vm.bjOutputsOf(widget.noProduksi) ?? [],
                          bjLoading: vm.isBjOutputsLoading(widget.noProduksi),
                          bjError: vm.bjOutputsError(widget.noProduksi),
                          rejectOutputs:
                              vm.rejectOutputsOf(widget.noProduksi) ?? [],
                          rejectLoading: vm.isRejectOutputsLoading(
                            widget.noProduksi,
                          ),
                          rejectError: vm.rejectOutputsError(widget.noProduksi),
                          bonggolanOutputs:
                              vm.bonggolanOutputsOf(widget.noProduksi) ?? [],
                          bonggolanLoading: vm.isBonggolanOutputsLoading(
                            widget.noProduksi,
                          ),
                          bonggolanError: vm.bonggolanOutputsError(
                            widget.noProduksi,
                          ),
                          onRefresh: () {
                            vm.loadOutputs(widget.noProduksi, force: true);
                            vm.loadBjOutputs(widget.noProduksi, force: true);
                            vm.loadRejectOutputs(
                              widget.noProduksi,
                              force: true,
                            );
                            vm.loadBonggolanOutputs(
                              widget.noProduksi,
                              force: true,
                            );
                          },
                        ),
                      );
                      final inputPanel = Expanded(
                        child: _buildInputPanel(
                          vm: vm,
                          locked: locked,
                          loading: loading,
                          canDelete: canDelete,
                          fwipGroups: fwipGroups,
                          brokerGroups: brokerGroups,
                          mixerGroups: mixerGroups,
                          gilinganGroups: gilinganGroups,
                          materialAll: materialAll,
                          tempMaterialIds: tempMaterialIds,
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _outputOnLeft
                              ? [
                                  outputPanel,
                                  const SizedBox(width: 16),
                                  inputPanel,
                                ]
                              : [
                                  inputPanel,
                                  const SizedBox(width: 16),
                                  outputPanel,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTemp ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTemp ? const Color(0xFFFFD54F) : const Color(0xFFE2E6EA),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.Nama ?? 'Material',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jumlah: ${item.Jumlah ?? 0} ${item.NamaUOM ?? ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (isTemp && onDeleteTemp != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
              onPressed: onDeleteTemp,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            )
          else if (!isTemp && onDeleteExisting != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              onPressed: onDeleteExisting,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}
