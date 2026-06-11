import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/view/app_shell.dart';
import 'package:pps_tablet/features/production/shared/shared.dart';

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

// ── Colour palette ─────────────────────────────────────────────────────────────
const _kInjectPrimary = Color(0xFF00897B); // teal — input
const _kInjectOutput = Color(0xFF00695C); // darker teal — output
const _kInjectSurface = Color(0xFFF8F9FB);
const _kInjectBorder = Color(0xFFE2E6EA);

class InjectProductionInputScreen extends StatefulWidget {
  final String noProduksi;
  final bool? isLocked;
  final DateTime? lastClosedDate;

  final int? idMesin;
  final String? namaJenis;
  final DateTime? tglProduksi;
  final int? shift;
  final String? hourStart;
  final String? hourEnd;

  const InjectProductionInputScreen({
    super.key,
    required this.noProduksi,
    this.isLocked,
    this.lastClosedDate,
    this.idMesin,
    this.namaJenis,
    this.tglProduksi,
    this.shift,
    this.hourStart,
    this.hourEnd,
  });

  @override
  State<InjectProductionInputScreen> createState() =>
      _InjectProductionInputScreenState();
}

class _InjectProductionInputScreenState
    extends State<InjectProductionInputScreen> {
  String _selectedInputTab = 'fwip';

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

      final vm = context.read<InjectProductionInputViewModel>();
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
    int fwipPcs = 0;
    for (final e in fwipGroups.values) {
      for (final i in e) {
        fwipPcs += i.pcs ?? 0;
      }
    }
    int brokerSak = brokerGroups.values.fold(0, (s, e) => s + e.length);
    int mixerSak = mixerGroups.values.fold(0, (s, e) => s + e.length);
    int gilinganCount = gilinganGroups.length;
    final materialCount = materialAll.length;
    final totalInputLabel =
        fwipGroups.length +
        brokerGroups.length +
        mixerGroups.length +
        gilinganGroups.length +
        materialCount;

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
                  ProductionFolderTabBar(
                    selectedValue: _selectedInputTab,
                    accentColor: _kInjectPrimary,
                    tabs: [
                      ProductionTabItem(
                        value: 'fwip',
                        label: 'Furniture WIP',
                        count: tabCounts['fwip']!,
                      ),
                      ProductionTabItem(
                        value: 'broker',
                        label: 'Broker',
                        count: tabCounts['broker']!,
                      ),
                      ProductionTabItem(
                        value: 'mixer',
                        label: 'Mixer',
                        count: tabCounts['mixer']!,
                      ),
                      ProductionTabItem(
                        value: 'gilingan',
                        label: 'Gilingan',
                        count: tabCounts['gilingan']!,
                      ),
                      ProductionTabItem(
                        value: 'material',
                        label: 'Material',
                        count: tabCounts['material']!,
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
                          const SizedBox(height: 10),
                          // Footer: summary + FAB
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _InjectInputSummaryBar(
                                  totalLabel: totalInputLabel,
                                  totalFwipPcs: fwipPcs,
                                  totalBrokerSak: brokerSak,
                                  totalMixerSak: mixerSak,
                                  totalGilingan: gilinganCount,
                                  totalMaterial: materialCount,
                                  color: _kInjectPrimary,
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

  // ── Output panel ───────────────────────────────────────────────────────────

  Widget _buildOutputPanel({
    required List<InjectOutputItem> outputs,
    required bool isLoading,
    required String? error,
    required VoidCallback onRefresh,
  }) {
    final totalPcs = outputs.fold<int>(0, (s, o) => s + o.pcs);
    final totalBerat = outputs.fold<double>(0, (s, o) => s + o.berat);

    return Container(
      decoration: productionPanelDecoration(
        borderColor: _kInjectOutput.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                productionSectionHeader(
                  Icons.output_rounded,
                  'Label Output',
                  iconColor: _kInjectOutput,
                  primaryColor: _kInjectPrimary,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh output',
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kInjectBorder),
          // Body
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
                        Expanded(
                          child: ProductionInputCategoryBlock(
                            color: _kInjectOutput,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (ctx, c) =>
                                        ProductionOutputCategoryContent(
                                          footer: const SizedBox.shrink(),
                                          child: outputs.isEmpty
                                              ? const Center(
                                                  child: Text(
                                                    'Belum ada label output furniture WIP',
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
                                                            c.maxWidth < 380
                                                            ? 2
                                                            : 3,
                                                        crossAxisSpacing: 6,
                                                        mainAxisSpacing: 6,
                                                        mainAxisExtent: 78,
                                                      ),
                                                  children: outputs
                                                      .map(
                                                        (o) =>
                                                            _InjectOutputTile(
                                                              output: o,
                                                            ),
                                                      )
                                                      .toList(),
                                                ),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _InjectOutputSummaryBar(
                                  totalLabel: outputs.length,
                                  totalPcs: totalPcs,
                                  totalBerat: totalBerat,
                                  color: _kInjectOutput,
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
                  tglProduksi: widget.tglProduksi,
                  shift: widget.shift,
                  hourStart: widget.hourStart,
                  hourEnd: widget.hourEnd,
                  primaryColor: _kInjectPrimary,
                  onRefresh: () {
                    vm.loadInputs(widget.noProduksi, force: true);
                    vm.loadOutputs(widget.noProduksi, force: true);
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
                                brokerGroups: brokerGroups,
                                mixerGroups: mixerGroups,
                                gilinganGroups: gilinganGroups,
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

// ── Summary bar ────────────────────────────────────────────────────────────────

class _InjectInputSummaryBar extends StatelessWidget {
  const _InjectInputSummaryBar({
    required this.totalLabel,
    required this.totalFwipPcs,
    required this.totalBrokerSak,
    required this.totalMixerSak,
    required this.totalGilingan,
    required this.totalMaterial,
    required this.color,
  });

  final int totalLabel;
  final int totalFwipPcs;
  final int totalBrokerSak;
  final int totalMixerSak;
  final int totalGilingan;
  final int totalMaterial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _SummaryChip(label: 'Total Label', value: '$totalLabel'),
          _SummaryChip(label: 'FWIP', value: '$totalFwipPcs pcs'),
          _SummaryChip(label: 'Broker', value: '$totalBrokerSak sak'),
          _SummaryChip(label: 'Mixer', value: '$totalMixerSak sak'),
          _SummaryChip(label: 'Gilingan', value: '$totalGilingan'),
          _SummaryChip(label: 'Material', value: '$totalMaterial'),
        ],
      ),
    );
  }
}

class _InjectOutputSummaryBar extends StatelessWidget {
  const _InjectOutputSummaryBar({
    required this.totalLabel,
    required this.totalPcs,
    required this.totalBerat,
    required this.color,
  });

  final int totalLabel;
  final int totalPcs;
  final double totalBerat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _SummaryChip(label: 'Total Label', value: '$totalLabel'),
          const SizedBox(width: 16),
          _SummaryChip(label: 'Total Pcs', value: '$totalPcs pcs'),
          const SizedBox(width: 16),
          _SummaryChip(
            label: 'Total Berat',
            value: '${totalBerat.toStringAsFixed(2)} kg',
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

// ── Output tile ────────────────────────────────────────────────────────────────

class _InjectOutputTile extends StatelessWidget {
  const _InjectOutputTile({required this.output});
  final InjectOutputItem output;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  output.noFurnitureWip,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (output.hasBeenPrinted)
                const Icon(
                  Icons.print_outlined,
                  size: 12,
                  color: Color(0xFF6B7280),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            output.namaJenis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                '${output.pcs} pcs',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00695C),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${output.berat.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
