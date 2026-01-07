// lib/features/production/hot_stamping/view/hot_stamping_production_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';

import '../../shared/widgets/add_cabinet_material_dialog.dart';
import '../../shared/widgets/cabinet_material_card.dart';
import '../widgets/hot_stamp_input_group_popover.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../view_model/hot_stamp_production_input_view_model.dart';
import '../widgets/hot_stamp_lookup_label_dialog.dart';
import '../widgets/hot_stamp_lookup_label_partial_dialog.dart';
import '../model/hot_stamping_inputs_model.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import 'package:pps_tablet/features/production/shared/shared.dart';

class HotStampingProductionInputScreen extends StatefulWidget {
  final String noProduksi;
  final bool? isLocked;
  final DateTime? lastClosedDate;

  const HotStampingProductionInputScreen({
    super.key,
    required this.noProduksi,
    this.isLocked,
    this.lastClosedDate,
  });

  @override
  State<HotStampingProductionInputScreen> createState() =>
      _HotStampingProductionInputScreenState();
}

class _HotStampingProductionInputScreenState
    extends State<HotStampingProductionInputScreen> {
  String _selectedMode = 'full';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<HotStampingProductionInputViewModel>();
      final already = vm.inputsOf(widget.noProduksi) != null;
      final loading = vm.isInputsLoading(widget.noProduksi);
      if (!already && !loading) {
        vm.loadInputs(widget.noProduksi);
      }
    });
  }

  // ✅ Handle back button
  Future<bool> _onWillPop() async {
    final vm = context.read<HotStampingProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UnsavedTempWarningDialog(
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
    final vm = context.read<HotStampingProductionInputViewModel>();

    final success = await vm.deleteItems(widget.noProduksi, items);

    if (!success && mounted) {
      final errMsg = vm.deleteError ?? 'Gagal menghapus item';
      await showDialog(
        context: context,
        builder: (_) => ErrorStatusDialog(
          title: 'Gagal Menghapus',
          message: errMsg,
        ),
      );
    }
    return success;
  }

  Future<void> _handleSave(BuildContext context) async {
    final vm = context.read<HotStampingProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      _showSnack('Tidak ada data untuk disimpan',
          backgroundColor: Colors.orange);
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
    } else {
      final errMsg = vm.submitError ?? 'Kesalahan tidak diketahui';

      await showDialog(
        context: context,
        builder: (_) => ErrorStatusDialog(
          title: 'Gagal Menyimpan',
          message: errMsg,
        ),
      );
    }
  }

  Future<void> _onCodeReady(BuildContext context, String code) async {
    final vm = context.read<HotStampingProductionInputViewModel>();

    final res = await vm.lookupFwipLabel(code, force: true);
    if (!mounted) return;

    if (vm.lookupError != null) {
      _showSnack('Gagal ambil data: ${vm.lookupError}',
          backgroundColor: Colors.red);
      return;
    }

    if (res == null || res.found == false || res.data.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
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
  Future<void> _handleFullMode(
      BuildContext context,
      HotStampingProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
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
        ? '✅ Auto-added ${result.added} item${result.skipped > 0 ? ' • Duplikat terlewati ${result.skipped}' : ''}'
        : 'Tidak ada item baru ditambahkan';

    _showSnack(
      msg,
      backgroundColor: result.added > 0 ? Colors.green : Colors.orange,
    );
  }

  /// MODE PARTIAL: Dialog khusus untuk partial
  Future<void> _handlePartialMode(
      BuildContext context,
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

  /// MODE SELECT: Dialog dengan checkbox
  Future<void> _handleSelectMode(
      BuildContext context,
      HotStampingProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<HotStampingProductionInputViewModel>(
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
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus Semua Temp?'),
                            content: Text(
                              'Apakah Anda yakin ingin menghapus ${vm.totalTempCount} item temp?',
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
                  itemBuilder: (context) => [
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

                // ===== MERGE DB + TEMP =====
                final fwipAll = loading
                    ? <FurnitureWipItem>[]
                    : [
                  ...vm.tempFurnitureWip.reversed,
                  ...vm.tempFurnitureWipPartial.reversed,
                  ...?inputs?.furnitureWip
                ];

                // ===== GROUPED =====
                final fwipGroups = groupBy(fwipAll, fwipTitleKey);

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // === SECTION KIRI: Scan / Manual ===
                      SizedBox(
                        width: 380,
                        child: SectionInputCard(
                          title: 'Input via Scan / Manual',
                          modeLabel: 'Pilih Mode',
                          modeItems: const [
                            DropdownMenuItem(
                                value: 'full', child: Text('FULL')),
                            DropdownMenuItem(
                                value: 'select', child: Text('SEBAGIAN')),
                            DropdownMenuItem(
                                value: 'partial', child: Text('PARTIAL')),
                          ],
                          selectedMode: _selectedMode,
                          manualHint: 'F.XXXXXXXXXX',
                          isProcessing: vm.isLookupLoading,
                          isLocked: locked,
                          onModeChanged: (mode) =>
                              setState(() => _selectedMode = mode),
                          onCodeScanned: (code) => _onCodeReady(context, code),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // === SECTION KANAN: Data Cards ===
                      Expanded(
                        child: Row(
                          children: [
                            // ===== FURNITURE WIP =====
                            Expanded(
                              flex: 1,
                              child: SectionCard(
                                title: 'Furniture WIP',
                                count: fwipGroups.length,
                                color: Colors.blue,
                                isLoading: loading,
                                summaryBuilder: () {
                                  int totalPcs = 0;
                                  double totalBerat = 0.0;

                                  for (final entry in fwipGroups.entries) {
                                    for (final item in entry.value) {
                                      totalPcs += (item.pcs ?? 0);
                                      totalBerat += (item.berat ?? 0.0);
                                    }
                                  }

                                  return SectionSummary(
                                    totalData: fwipGroups.length,
                                    totalSak: totalPcs,
                                    totalBerat: totalBerat,
                                  );
                                },
                                child: fwipGroups.isEmpty
                                    ? const Center(
                                  child: Text('Tidak ada data',
                                      style: TextStyle(fontSize: 11)),
                                )
                                    : ListView(
                                  padding: const EdgeInsets.all(8),
                                  children:
                                  fwipGroups.entries.map((entry) {
                                    final hasPartial = entry.value
                                        .any((x) => x.isPartialRow);

                                    late final List<String> headers;
                                    late final List<int> columnFlexes;

                                    if (hasPartial) {
                                      headers = const [
                                        'Label',
                                        'Pcs',
                                        'Berat',
                                        'Action'
                                      ];
                                      columnFlexes = const [3, 1, 2];
                                    } else {
                                      headers = const [
                                        'Pcs',
                                        'Berat',
                                        'Action'
                                      ];
                                      columnFlexes = const [1, 2];
                                    }

                                    return GroupTooltipAnchorTile(
                                      title: entry.key,
                                      headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',                                      color: Colors.blue,
                                      tableHeaders: headers,
                                      columnFlexes: columnFlexes,
                                      canDelete: canDelete,
                                      onBulkDelete: _handleBulkDelete,
                                      summaryBuilder: () {
                                        int totalPcs = 0;
                                        double totalBerat = 0.0;

                                        for (final item in entry.value) {
                                          totalPcs += (item.pcs ?? 0);
                                          totalBerat +=
                                          (item.berat ?? 0.0);
                                        }

                                        return TooltipSummary(
                                          totalBerat: totalBerat,
                                          totalPcs: totalPcs,
                                        );
                                      },
                                      detailsBuilder: () {
                                        final currentInputs =
                                        vm.inputsOf(widget.noProduksi);

                                        final dbItems = currentInputs ==
                                            null
                                            ? <FurnitureWipItem>[]
                                            : currentInputs.furnitureWip
                                            .where((x) =>
                                        fwipTitleKey(x) ==
                                            entry.key);

                                        final tempFull = vm
                                            .tempFurnitureWip
                                            .where((x) =>
                                        fwipTitleKey(x) ==
                                            entry.key);
                                        final tempPart = vm
                                            .tempFurnitureWipPartial
                                            .where((x) =>
                                        fwipTitleKey(x) ==
                                            entry.key);

                                        final items = <FurnitureWipItem>[
                                          ...tempPart,
                                          ...dbItems,
                                          ...tempFull,
                                        ];

                                        return items.map((item) {
                                          final isTemp = vm
                                              .tempFurnitureWip
                                              .contains(item) ||
                                              vm.tempFurnitureWipPartial
                                                  .contains(item);

                                          late final List<String>
                                          columns;

                                          if (hasPartial) {
                                            columns = [
                                              item.isPartialRow
                                                  ? (item.noFurnitureWIP ??
                                                  '-')
                                                  : '-',
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
                                            onDelete: isTemp
                                                ? () => vm
                                                .deleteTempFurnitureWipItem(
                                                item)
                                                : null,
                                            isTempRow: isTemp,
                                            isHighlighted: isTemp,
                                            isDisabled:
                                            !isTemp && !canDelete,
                                            itemData: item,
                                          );
                                        }).toList();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // ===== CABINET MATERIAL (USING CARD) =====
                            Expanded(
                              flex: 2,
                              child: Builder(
                                builder: (context) {
                                  // ambil inputs terbaru
                                  final currentInputs = vm.inputsOf(widget.noProduksi);

                                  // list TEMP + DB (screen yg merge)
                                  final tempList = vm.tempCabinetMaterial;
                                  final dbList = currentInputs?.cabinetMaterial ?? const <CabinetMaterialItem>[];

                                  final materialAll = <CabinetMaterialItem>[
                                    ...tempList,
                                    ...dbList,
                                  ];

                                  // penanda TEMP by ID (kalau temp item belum punya Id, kamu bisa pakai fallback lain)
                                  final tempIds = tempList
                                      .map((x) => x.IdCabinetMaterial ?? 0)
                                      .where((id) => id > 0)
                                      .toSet();

                                  return CabinetMaterialCard(
                                    items: materialAll,
                                    tempIds: tempIds,
                                    locked: locked,
                                    canDelete: canDelete,

                                    onAdd: locked
                                        ? null
                                        : () {
                                      final vm = context.read<HotStampingProductionInputViewModel>();

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

                                    onDeleteTemp: (item) {
                                      vm.deleteTempCabinetMaterialItem(item);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✅ Material TEMP dihapus'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },

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
}

// ===== HELPER FUNCTIONS =====
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