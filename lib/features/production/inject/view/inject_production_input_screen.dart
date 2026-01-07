// lib/features/production/inject_production/view/inject_production_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';

import '../../shared/widgets/add_cabinet_material_dialog.dart';
import '../../shared/widgets/cabinet_material_card.dart';
import '../widgets/inject_input_group_popover.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../view_model/inject_production_input_view_model.dart';
import '../widgets/inject_lookup_label_dialog.dart';
import '../widgets/inject_lookup_label_partial_dialog.dart';
import '../model/inject_production_inputs_model.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import 'package:pps_tablet/features/production/shared/shared.dart';

class InjectProductionInputScreen extends StatefulWidget {
  final String noProduksi;
  final bool? isLocked;
  final DateTime? lastClosedDate;

  const InjectProductionInputScreen({
    super.key,
    required this.noProduksi,
    this.isLocked,
    this.lastClosedDate,
  });

  @override
  State<InjectProductionInputScreen> createState() =>
      _InjectProductionInputScreenState();
}

class _InjectProductionInputScreenState
    extends State<InjectProductionInputScreen> {
  String _selectedMode = 'full';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<InjectProductionInputViewModel>();
      final already = vm.inputsOf(widget.noProduksi) != null;
      final loading = vm.isInputsLoading(widget.noProduksi);
      if (!already && !loading) {
        vm.loadInputs(widget.noProduksi);
      }
    });
  }

  // ✅ Handle back button
  Future<bool> _onWillPop() async {
    final vm = context.read<InjectProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          UnsavedTempWarningDialog(
            totalTempCount: vm.totalTempCount,
            submitSummary: vm.getSubmitSummary(),
            onSavePressed: () {
              Navigator.of(dialogContext).pop(false);
              _handleSave(context);
            },
          ),
    );

    if (shouldPop == true) {
      vm.clearAllTempItems();
      return true;
    }

    return false;
  }

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

  /// ✅ Handler untuk bulk delete
  Future<bool> _handleBulkDelete(List<dynamic> items) async {
    final vm = context.read<InjectProductionInputViewModel>();

    final success = await vm.deleteItems(widget.noProduksi, items);

    if (!success && mounted) {
      final errMsg = vm.deleteError ?? 'Gagal menghapus item';
      await showDialog(
        context: context,
        builder: (_) =>
            ErrorStatusDialog(
              title: 'Gagal Menghapus',
              message: errMsg,
            ),
      );
    }
    return success;
  }

  Future<void> _handleSave(BuildContext context) async {
    final vm = context.read<InjectProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      _showSnack('Tidak ada data untuk disimpan',
          backgroundColor: Colors.orange);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          ConfirmSaveTempDialog(
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
            ErrorStatusDialog(
              title: 'Gagal Menyimpan',
              message: errMsg,
            ),
      );
    }
  }

  Future<void> _onCodeReady(BuildContext context, String code) async {
    final vm = context.read<InjectProductionInputViewModel>();

    final res = await vm.lookupLabel(code, force: true);
    if (!mounted) return;

    if (vm.lookupError != null) {
      _showSnack('Gagal ambil data: ${vm.lookupError}',
          backgroundColor: Colors.red);
      return;
    }

    if (res == null || res.found == false || res.data.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              title: const Text('Data Tidak Ditemukan'),
              content: Text('Label "$code" tidak memiliki data yang tersedia.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup')),
              ],
            ),
      );
      return;
    }

    // ===== ROUTING BERDASARKAN MODE =====
    if (_selectedMode == 'full') {
      await _handleFullMode(context, vm, res);
    } else if (_selectedMode == 'partial') {
      await _handlePartialMode(context, vm, res);
    } else {
      await _handleSelectMode(context, vm, res);
    }
  }

  /// MODE FULL: Langsung commit semua data tanpa dialog
  Future<void> _handleFullMode(BuildContext context,
      InjectProductionInputViewModel vm,
      ProductionLabelLookupResult res,) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp =
          labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix =
      hasTemp ? ' • ${vm.getTemporaryDataSummary(labelCode!)}' : '';
      _showSnack(
          'Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix');
      return;
    }

    vm.clearPicks();
    vm.pickAllNew(widget.noProduksi);

    final result = vm.commitPickedToTemp(noProduksi: widget.noProduksi);

    final msg = result.added > 0
        ? '✅ Auto-added ${result.added} item${result.skipped > 0
        ? ' • Duplikat terlewati ${result.skipped}'
        : ''}'
        : 'Tidak ada item baru ditambahkan';

    _showSnack(
      msg,
      backgroundColor: result.added > 0 ? Colors.green : Colors.orange,
    );
  }

  /// MODE PARTIAL: Dialog khusus untuk partial
  Future<void> _handlePartialMode(BuildContext context,
      InjectProductionInputViewModel vm,
      ProductionLabelLookupResult res,) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          InjectLookupLabelPartialDialog(
            noProduksi: widget.noProduksi,
            selectedMode: _selectedMode,
          ),
    );
  }

  /// MODE SELECT: Dialog dengan checkbox
  Future<void> _handleSelectMode(BuildContext context,
      InjectProductionInputViewModel vm,
      ProductionLabelLookupResult res,) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp =
          labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix =
      hasTemp ? ' • ${vm.getTemporaryDataSummary(labelCode!)}' : '';
      _showSnack(
          'Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix');
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          InjectLookupLabelDialog(
            noProduksi: widget.noProduksi,
            selectedMode: _selectedMode,
          ),
    );
  }

  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;

    if (item is BrokerItem) return item.noBroker;
    if (item is MixerItem) return item.noMixer;
    if (item is GilinganItem) return item.noGilingan;
    if (item is FurnitureWipItem) {
      return (item.noFurnitureWIPPartial ?? '')
          .trim()
          .isNotEmpty
          ? item.noFurnitureWIPPartial
          : item.noFurnitureWIP;
    }
    return null;
  }


// lib/features/production/inject_production/view/inject_production_input_screen.dart

// ... (bagian imports dan initState sama)

  @override
  Widget build(BuildContext context) {
    return Consumer<InjectProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);
        final perm = context.watch<PermissionViewModel>();
        final locked = widget.isLocked == true;

        final canDeleteByPerm = perm.can('label_crusher:delete');
        final canDelete = canDeleteByPerm && !locked;

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Inputs • ${widget.noProduksi}'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  final canPop = await _onWillPop();
                  if (canPop && mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              actions: [
                SaveButtonWithBadge(
                  count: vm.totalTempCount,
                  isLoading: vm.isSubmitting,
                  onPressed: () => _handleSave(context),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'refresh') {
                      vm.loadInputs(widget.noProduksi, force: true);
                      _showSnack('Data di-refresh');
                    } else if (value == 'clear_temp') {
                      if (vm.totalTempCount > 0) {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              AlertDialog(
                                title: const Text('Hapus Semua Temp?'),
                                content: Text(
                                  'Apakah Anda yakin ingin menghapus ${vm
                                      .totalTempCount} item temp?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      vm.clearAllTempItems();
                                      Navigator.pop(context);
                                      _showSnack('Semua temp items dihapus');
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) =>
                  [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text('Refresh Data'),
                        ],
                      ),
                    ),
                    if (vm.totalTempCount > 0)
                      PopupMenuItem(
                        value: 'clear_temp',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep,
                                size: 20, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Hapus Semua Temp',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            body: Builder(
              builder: (_) {
                if (err != null) {
                  return Center(child: Text('Gagal memuat inputs:\n$err'));
                }

                // ===== MERGE DB + TEMP FOR ALL 5 CATEGORIES =====

                // Broker
                final brokerAll = loading
                    ? <BrokerItem>[]
                    : [
                  ...vm.tempBroker.reversed,
                  ...vm.tempBrokerPartial.reversed,
                  ...?inputs?.broker
                ];
                final brokerGroups = groupBy(brokerAll, brokerTitleKey);

                // Mixer
                final mixerAll = loading
                    ? <MixerItem>[]
                    : [
                  ...vm.tempMixer.reversed,
                  ...vm.tempMixerPartial.reversed,
                  ...?inputs?.mixer
                ];
                final mixerGroups = groupBy(mixerAll, mixerTitleKey);

                // Gilingan
                final gilinganAll = loading
                    ? <GilinganItem>[]
                    : [
                  ...vm.tempGilingan.reversed,
                  ...vm.tempGilinganPartial.reversed,
                  ...?inputs?.gilingan
                ];
                final gilinganGroups = groupBy(gilinganAll, gilinganTitleKey);

                // FurnitureWIP
                final fwipAll = loading
                    ? <FurnitureWipItem>[]
                    : [
                  ...vm.tempFurnitureWip.reversed,
                  ...vm.tempFurnitureWipPartial.reversed,
                  ...?inputs?.furnitureWip
                ];
                final fwipGroups = groupBy(fwipAll, fwipTitleKey);

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === SECTION KIRI: Scan / Manual ===
                      SizedBox(
                        width: 380,
                        child: SectionInputCard(
                          title: 'Input via Scan / Manual',
                          modeLabel: 'Pilih Mode',
                          modeItems: const [
                            DropdownMenuItem(value: 'full', child: Text('FULL')),
                            DropdownMenuItem(value: 'select', child: Text('SEBAGIAN')),
                            DropdownMenuItem(value: 'partial', child: Text('PARTIAL')),
                          ],
                          selectedMode: _selectedMode,
                          manualHint: 'BB. / D. / H. / V.',
                          isProcessing: vm.isLookupLoading,
                          isLocked: locked,
                          onModeChanged: (mode) => setState(() => _selectedMode = mode),
                          onCodeScanned: (code) => _onCodeReady(context, code),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // === SECTION TENGAH: 4 Kategori dalam Grid 2x2 ===
                      Expanded(
                        flex: 2, // ✅ Lebih lebar dari Cabinet Material
                        child: Column(
                          children: [
                            // ===== ROW ATAS: Broker + Mixer =====
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // BROKER
                                  Expanded(
                                    child: _buildBrokerSection(
                                      vm: vm,
                                      loading: loading,
                                      groups: brokerGroups,
                                      canDelete: canDelete,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // MIXER
                                  Expanded(
                                    child: _buildMixerSection(
                                      vm: vm,
                                      loading: loading,
                                      groups: mixerGroups,
                                      canDelete: canDelete,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ===== ROW BAWAH: Gilingan + FurnitureWIP =====
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // GILINGAN
                                  Expanded(
                                    child: _buildGilinganSection(
                                      vm: vm,
                                      loading: loading,
                                      groups: gilinganGroups,
                                      canDelete: canDelete,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // FURNITURE WIP
                                  Expanded(
                                    child: _buildFurnitureWipSection(
                                      vm: vm,
                                      loading: loading,
                                      groups: fwipGroups,
                                      canDelete: canDelete,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // === SECTION KANAN: Cabinet Material (Full Height) ===
                      SizedBox(
                        width: 300,
                        child: Builder(
                          builder: (context) {
                            final currentInputs = vm.inputsOf(widget.noProduksi);

                            // ✅ TEMP + DB (screen yg merge)
                            final tempList = vm.tempCabinetMaterial;
                            final dbList =
                                currentInputs?.cabinetMaterial ?? const <CabinetMaterialItem>[];

                            final materialAll = <CabinetMaterialItem>[
                              ...tempList,
                              ...dbList,
                            ];

                            // ✅ tempIds untuk tandai row TEMP (asumsi IdCabinetMaterial ada di item temp)
                            final tempIds = tempList
                                .map((x) => x.IdCabinetMaterial ?? 0)
                                .where((id) => id > 0)
                                .toSet();

                            return CabinetMaterialCard(
                              title: 'Cabinet Material',
                              items: materialAll,
                              tempIds: tempIds,
                              locked: locked,
                              canDelete: canDelete,

                              // ✅ ADD -> dialog
                              onAdd: locked
                                  ? null
                                  : () {
                                final vm = context.read<InjectProductionInputViewModel>();

                                showDialog(
                                  context: context,
                                  builder: (_) => AddCabinetMaterialDialog(
                                    idWarehouse: 5,
                                    loadMaterials: ({required idWarehouse, bool force = false}) {
                                      return vm.loadMasterCabinetMaterials(idWarehouse: idWarehouse, force: force);
                                    },
                                    isAlreadyInTemp: (id) => vm.hasCabinetMaterialInTemp(id),
                                    onAddTemp: ({required masterItem, required jumlah}) {
                                      vm.addTempCabinetMaterialFromMaster(masterItem: masterItem, Jumlah: jumlah);
                                    },
                                  ),
                                );
                              },

                              // ✅ delete TEMP (langsung)
                              onDeleteTemp: (item) {
                                vm.deleteTempCabinetMaterialItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Cabinet Material TEMP dihapus'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },

                              // ✅ delete EXISTING (confirm + API)
                              onDeleteExisting: (item) async {
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

                                if (confirmed != true) return;

                                final success = await vm.deleteItems(widget.noProduksi, [item]);

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? '✅ Material berhasil dihapus'
                                          : (vm.deleteError ?? 'Gagal menghapus material'),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

// ===== BUILDER METHODS (sama seperti sebelumnya) =====

  Widget _buildBrokerSection({
    required InjectProductionInputViewModel vm,
    required bool loading,
    required Map<String, List<BrokerItem>> groups,
    required bool canDelete,
  }) {
    return SectionCard(
      title: 'Broker',
      count: groups.length,
      color: Colors.blue,
      isLoading: loading,
      summaryBuilder: () {
        int totalSak = 0;
        double totalBerat = 0.0;

        for (final entry in groups.entries) {
          for (final item in entry.value) {
            totalSak += 1;
            totalBerat += (item.berat ?? 0.0);
          }
        }

        return SectionSummary(
          totalData: groups.length,
          totalSak: totalSak,
          totalBerat: totalBerat,
        );
      },
      child: groups.isEmpty
          ? const Center(
          child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
          : ListView(
        padding: const EdgeInsets.all(8),
        children: groups.entries.map((entry) {
          return _buildBrokerGroup(
            vm: vm,
            labelCode: entry.key,
            items: entry.value,
            canDelete: canDelete,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBrokerGroup({
    required InjectProductionInputViewModel vm,
    required String labelCode,
    required List<BrokerItem> items,
    required bool canDelete,
  }) {
    final hasPartial = items.any((x) => x.isPartialRow);

    late final List<String> headers;
    late final List<int> columnFlexes;

    if (hasPartial) {
      headers = const ['Label', 'Sak', 'Berat', 'Action'];
      columnFlexes = const [3, 1, 2];
    } else {
      headers = const ['Sak', 'Berat', 'Action'];
      columnFlexes = const [1, 2];
    }

    return GroupTooltipAnchorTile(
      title: labelCode,
      headerSubtitle: (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
      color: Colors.blue,
      tableHeaders: headers,
      columnFlexes: columnFlexes,
      canDelete: canDelete,
      onBulkDelete: _handleBulkDelete,
      summaryBuilder: () {
        double totalBerat = 0.0;
        for (final item in items) {
          totalBerat += (item.berat ?? 0.0);
        }
        return TooltipSummary(totalBerat: totalBerat, totalPcs: 0);
      },
      detailsBuilder: () {
        return items.map((item) {
          final isTemp = vm.tempBroker.contains(item) ||
              vm.tempBrokerPartial.contains(item);

          late final List<String> columns;

          if (hasPartial) {
            columns = [
              item.isPartialRow ? (item.noBroker ?? '-') : '-',
              '${item.noSak ?? 0}',
              '${num2(item.berat)} kg',
            ];
          } else {
            columns = [
              '${item.noSak ?? 0}',
              '${num2(item.berat)} kg',
            ];
          }

          return TooltipTableRow(
            columns: columns,
            columnFlexes: columnFlexes,
            showDelete: isTemp,
            onDelete: isTemp ? () => vm.deleteTempBrokerItem(item) : null,
            isTempRow: isTemp,
            isHighlighted: isTemp,
            isDisabled: !isTemp && !canDelete,
            itemData: item,
          );
        }).toList();
      },
    );
  }

  Widget _buildMixerSection({
    required InjectProductionInputViewModel vm,
    required bool loading,
    required Map<String, List<MixerItem>> groups,
    required bool canDelete,
  }) {
    return SectionCard(
      title: 'Mixer',
      count: groups.length,
      color: Colors.blue,
      isLoading: loading,
      summaryBuilder: () {
        int totalSak = 0;
        double totalBerat = 0.0;

        for (final entry in groups.entries) {
          for (final item in entry.value) {
            totalSak += 1;
            totalBerat += (item.berat ?? 0.0);
          }
        }

        return SectionSummary(
          totalData: groups.length,
          totalSak: totalSak,
          totalBerat: totalBerat,
        );
      },
      child: groups.isEmpty
          ? const Center(
          child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
          : ListView(
        padding: const EdgeInsets.all(8),
        children: groups.entries.map((entry) {
          return _buildMixerGroup(
            vm: vm,
            labelCode: entry.key,
            items: entry.value,
            canDelete: canDelete,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMixerGroup({
    required InjectProductionInputViewModel vm,
    required String labelCode,
    required List<MixerItem> items,
    required bool canDelete,
  }) {
    final hasPartial = items.any((x) => x.isPartialRow);

    late final List<String> headers;
    late final List<int> columnFlexes;

    if (hasPartial) {
      headers = const ['Label', 'Sak', 'Berat', 'Action'];
      columnFlexes = const [3, 1, 2];
    } else {
      headers = const ['Sak', 'Berat', 'Action'];
      columnFlexes = const [1, 2];
    }

    return GroupTooltipAnchorTile(
      title: labelCode,
      headerSubtitle: (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
      color: Colors.blue,
      tableHeaders: headers,
      columnFlexes: columnFlexes,
      canDelete: canDelete,
      onBulkDelete: _handleBulkDelete,
      summaryBuilder: () {
        double totalBerat = 0.0;
        for (final item in items) {
          totalBerat += (item.berat ?? 0.0);
        }
        return TooltipSummary(totalBerat: totalBerat, totalPcs: 0);
      },
      detailsBuilder: () {
        return items.map((item) {
          final isTemp =
              vm.tempMixer.contains(item) || vm.tempMixerPartial.contains(item);

          late final List<String> columns;

          if (hasPartial) {
            columns = [
              item.isPartialRow ? (item.noMixer ?? '-') : '-',
              '${item.noSak ?? 0}',
              '${num2(item.berat)} kg',
            ];
          } else {
            columns = [
              '${item.noSak ?? 0}',
              '${num2(item.berat)} kg',
            ];
          }

          return TooltipTableRow(
            columns: columns,
            columnFlexes: columnFlexes,
            showDelete: isTemp,
            onDelete: isTemp ? () => vm.deleteTempMixerItem(item) : null,
            isTempRow: isTemp,
            isHighlighted: isTemp,
            isDisabled: !isTemp && !canDelete,
            itemData: item,
          );
        }).toList();
      },
    );
  }

  Widget _buildGilinganSection({
    required InjectProductionInputViewModel vm,
    required bool loading,
    required Map<String, List<GilinganItem>> groups,
    required bool canDelete,
  }) {
    return SectionCard(
      title: 'Gilingan',
      count: groups.length,
      color: Colors.blue,
      isLoading: loading,
      summaryBuilder: () {
        double totalBerat = 0.0;

        for (final entry in groups.entries) {
          for (final item in entry.value) {
            totalBerat += (item.berat ?? 0.0);
          }
        }

        return SectionSummary(
          totalData: groups.length,
          totalSak: 0,
          totalBerat: totalBerat,
        );
      },
      child: groups.isEmpty
          ? const Center(
          child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
          : ListView(
        padding: const EdgeInsets.all(8),
        children: groups.entries.map((entry) {
          return _buildGilinganGroup(
            vm: vm,
            labelCode: entry.key,
            items: entry.value,
            canDelete: canDelete,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGilinganGroup({
    required InjectProductionInputViewModel vm,
    required String labelCode,
    required List<GilinganItem> items,
    required bool canDelete,
  }) {
    final hasPartial = items.any((x) => x.isPartialRow);

    late final List<String> headers;
    late final List<int> columnFlexes;

    if (hasPartial) {
      headers = const ['Label', 'Berat', 'Action'];
      columnFlexes = const [3, 2];
    } else {
      headers = const ['Berat', 'Action'];
      columnFlexes = const [2];
    }

    return GroupTooltipAnchorTile(
      title: labelCode,
      headerSubtitle: (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
      color: Colors.blue,
      tableHeaders: headers,
      columnFlexes: columnFlexes,
      canDelete: canDelete,
      onBulkDelete: _handleBulkDelete,
      summaryBuilder: () {
        double totalBerat = 0.0;
        for (final item in items) {
          totalBerat += (item.berat ?? 0.0);
        }
        return TooltipSummary(totalBerat: totalBerat, totalPcs: 0);
      },
      detailsBuilder: () {
        return items.map((item) {
          final isTemp = vm.tempGilingan.contains(item) ||
              vm.tempGilinganPartial.contains(item);

          late final List<String> columns;

          if (hasPartial) {
            columns = [
              item.isPartialRow ? (item.noGilingan ?? '-') : '-',
              '${num2(item.berat)} kg',
            ];
          } else {
            columns = [
              '${num2(item.berat)} kg',
            ];
          }

          return TooltipTableRow(
            columns: columns,
            columnFlexes: columnFlexes,
            showDelete: isTemp,
            onDelete: isTemp ? () => vm.deleteTempGilinganItem(item) : null,
            isTempRow: isTemp,
            isHighlighted: isTemp,
            isDisabled: !isTemp && !canDelete,
            itemData: item,
          );
        }).toList();
      },
    );
  }

  Widget _buildFurnitureWipSection({
    required InjectProductionInputViewModel vm,
    required bool loading,
    required Map<String, List<FurnitureWipItem>> groups,
    required bool canDelete,
  }) {
    return SectionCard(
      title: 'Furniture WIP',
      count: groups.length,
      color: Colors.blue,
      isLoading: loading,
      summaryBuilder: () {
        int totalPcs = 0;
        double totalBerat = 0.0;

        for (final entry in groups.entries) {
          for (final item in entry.value) {
            totalPcs += (item.pcs ?? 0);
            totalBerat += (item.berat ?? 0.0);
          }
        }

        return SectionSummary(
          totalData: groups.length,
          totalSak: totalPcs,
          totalBerat: totalBerat,
        );
      },
      child: groups.isEmpty
          ? const Center(
          child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
          : ListView(
        padding: const EdgeInsets.all(8),
        children: groups.entries.map((entry) {
          return _buildFurnitureWipGroup(
            vm: vm,
            labelCode: entry.key,
            items: entry.value,
            canDelete: canDelete,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFurnitureWipGroup({
    required InjectProductionInputViewModel vm,
    required String labelCode,
    required List<FurnitureWipItem> items,
    required bool canDelete,
  }) {
    final hasPartial = items.any((x) => x.isPartialRow);

    late final List<String> headers;
    late final List<int> columnFlexes;

    if (hasPartial) {
      headers = const ['Label', 'Pcs', 'Berat', 'Action'];
      columnFlexes = const [3, 1, 2];
    } else {
      headers = const ['Pcs', 'Berat', 'Action'];
      columnFlexes = const [1, 2];
    }

    return GroupTooltipAnchorTile(
      title: labelCode,
      headerSubtitle: (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
      color: Colors.blue,
      tableHeaders: headers,
      columnFlexes: columnFlexes,
      canDelete: canDelete,
      onBulkDelete: _handleBulkDelete,
      summaryBuilder: () {
        int totalPcs = 0;
        double totalBerat = 0.0;
        for (final item in items) {
          totalPcs += (item.pcs ?? 0);
          totalBerat += (item.berat ?? 0.0);
        }
        return TooltipSummary(totalBerat: totalBerat, totalPcs: totalPcs);
      },
      detailsBuilder: () {
        return items.map((item) {
          final isTemp = vm.tempFurnitureWip.contains(item) ||
              vm.tempFurnitureWipPartial.contains(item);

          late final List<String> columns;

          if (hasPartial) {
            columns = [
              item.isPartialRow ? (item.noFurnitureWIP ?? '-') : '-',
              '${item.pcs ?? 0} pcs',
              '${num2(item.berat)} kg',
            ];
          } else {
            columns = [
              '${item.pcs ?? 0} pcs',
              '${num2(item.berat)} kg',
            ];
          }

          return TooltipTableRow(
            columns: columns,
            columnFlexes: columnFlexes,
            showDelete: isTemp,
            onDelete:
            isTemp ? () => vm.deleteTempFurnitureWipItem(item) : null,
            isTempRow: isTemp,
            isHighlighted: isTemp,
            isDisabled: !isTemp && !canDelete,
            itemData: item,
          );
        }).toList();
      },
    );
  }
}
// ===== HELPER FUNCTIONS =====

String brokerTitleKey(BrokerItem e) {
  final part = (e.noBrokerPartial ?? '').trim();
  if (part.isNotEmpty) return part;
  return e.noBroker ?? '-';
}

String mixerTitleKey(MixerItem e) {
  final part = (e.noMixerPartial ?? '').trim();
  if (part.isNotEmpty) return part;
  return e.noMixer ?? '-';
}

String gilinganTitleKey(GilinganItem e) {
  final part = (e.noGilinganPartial ?? '').trim();
  if (part.isNotEmpty) return part;
  return e.noGilingan ?? '-';
}

String fwipTitleKey(FurnitureWipItem e) {
  final part = (e.noFurnitureWIPPartial ?? '').trim();
  if (part.isNotEmpty) return part;
  return e.noFurnitureWIP ?? '-';
}

Map<K, List<T>> groupBy<K, T>(Iterable<T> items, K Function(T) keyFn) {
  final map = <K, List<T>>{};
  for (final item in items) {
    final key = keyFn(item);
    (map[key] ??= []).add(item);
  }
  return map;
}