// lib/features/shared/bongkar_susun/view/bongkar_susun_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../production/shared/models/barang_jadi_item.dart';
import '../../production/shared/models/bb_item.dart';
import '../../production/shared/models/bonggolan_item.dart';
import '../../production/shared/models/broker_item.dart';
import '../../production/shared/models/crusher_item.dart';
import '../../production/shared/models/furniture_wip_item.dart';
import '../../production/shared/models/gilingan_item.dart';
import '../../production/shared/models/mixer_item.dart';
import '../../production/shared/models/washing_item.dart';
import '../../production/shared/utils/title_keys/barang_jadi.dart';
import '../../production/shared/utils/title_keys/furniture_wip.dart';
import '../view_model/bongkar_susun_input_view_model.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/loading_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../production/shared/models/production_label_lookup_result.dart';
import '../../production/shared/widgets/confirm_save_temp_dialog.dart';
import '../../production/shared/widgets/unsaved_temp_warning_dialog.dart';
import '../widgets/bongkar_susun_input_group_popover.dart';
import '../../production/shared/widgets/partial_mode_not_supported_dialog.dart';
import '../../production/shared/widgets/save_button_with_badge.dart';
import '../model/bongkar_susun_inputs_model.dart';

import 'package:pps_tablet/features/production/shared/shared.dart';
import '../widgets/bongkar_susun_lookup_label_dialog.dart';
import '../widgets/bongkar_susun_lookup_label_partial_dialog.dart';

class BongkarSusunInputScreen extends StatefulWidget {
  final String noBongkarSusun;

  const BongkarSusunInputScreen({
    super.key,
    required this.noBongkarSusun,
  });

  @override
  State<BongkarSusunInputScreen> createState() =>
      _BongkarSusunInputScreenState();
}

class _BongkarSusunInputScreenState extends State<BongkarSusunInputScreen> {
  String _selectedMode = 'full';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BongkarSusunInputViewModel>();
      final already = vm.inputsOf(widget.noBongkarSusun) != null;
      final loading = vm.isInputsLoading(widget.noBongkarSusun);
      if (!already && !loading) {
        vm.loadInputs(widget.noBongkarSusun);
      }
    });
  }

  // ✅ Handle back button with temp data warning
  Future<bool> _onWillPop() async {
    final vm = context.read<BongkarSusunInputViewModel>();

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
    final vm = context.read<BongkarSusunInputViewModel>();

    final success = await vm.deleteItems(widget.noBongkarSusun, items);

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
    final vm = context.read<BongkarSusunInputViewModel>();

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

    final success = await vm.submitTempItems(widget.noBongkarSusun);

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
    final vm = context.read<BongkarSusunInputViewModel>();

    // ✅ VALIDASI: Washing/Crusher tidak support partial
    if (_selectedMode == 'partial') {
      final prefix = code.trim().toUpperCase().substring(0, 2);

      if (prefix == 'B.' || prefix == 'F.') {
        final labelType = prefix == 'B.' ? 'Washing' : 'Crusher';

        await PartialModeNotSupportedDialog.show(
          context: context,
          labelType: labelType,
          onOk: () {},
        );

        return;
      }
    }

    // ✅ VALIDASI: Bonggolan tidak support partial
    if (_selectedMode == 'partial') {
      final prefix = code.trim().toUpperCase().substring(0, 2);

      if (prefix == 'M.') {
        await PartialModeNotSupportedDialog.show(
          context: context,
          labelType: 'Bonggolan',
          onOk: () {},
        );

        return;
      }
    }

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
        builder: (_) => AlertDialog(
          title: const Text('Data Tidak Ditemukan'),
          content:
          Text('Label "$code" tidak memiliki data yang tersedia.'),
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
      BongkarSusunInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noBongkarSusun);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp =
          labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp
          ? ' • ${vm.getTemporaryDataSummary(labelCode!)}'
          : '';
      _showSnack('Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix');
      return;
    }

    vm.clearPicks();
    vm.pickAllNew(widget.noBongkarSusun);

    final result = vm.commitPickedToTemp(noBongkarSusun: widget.noBongkarSusun);

    final msg = result.added > 0
        ? '✅ Auto-added ${result.added} item${result.skipped > 0 ? ' • Duplikat terlewati ${result.skipped}' : ''}'
        : 'Tidak ada item baru ditambahkan';

    _showSnack(
      msg,
      backgroundColor: result.added > 0 ? Colors.green : Colors.orange,
    );
  }

  /// MODE PARTIAL: Dialog khusus untuk partial dengan radio button
  Future<void> _handlePartialMode(
      BuildContext context,
      BongkarSusunInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BongkarSusunLookupLabelPartialDialog(
        noBongkarSusun: widget.noBongkarSusun,
        selectedMode: _selectedMode,
      ),
    );
  }

  /// MODE SELECT: Dialog dengan checkbox
  Future<void> _handleSelectMode(
      BuildContext context,
      BongkarSusunInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noBongkarSusun);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp =
          labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp
          ? ' • ${vm.getTemporaryDataSummary(labelCode!)}'
          : '';
      _showSnack('Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix');
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BongkarSusunLookupLabelDialog(
        noBongkarSusun: widget.noBongkarSusun,
        selectedMode: _selectedMode,
      ),
    );
  }

  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;

    if (item is BrokerItem) {
      return (item.noBrokerPartial ?? '').trim().isNotEmpty
          ? item.noBrokerPartial
          : item.noBroker;
    }
    if (item is BbItem) {
      final npart = (item.noBBPartial ?? '').trim();
      return npart.isNotEmpty ? npart : item.noBahanBaku;
    }
    if (item is WashingItem) return item.noWashing;
    if (item is CrusherItem) return item.noCrusher;
    if (item is GilinganItem) {
      return (item.noGilinganPartial ?? '').trim().isNotEmpty
          ? item.noGilinganPartial
          : item.noGilingan;
    }
    if (item is MixerItem) {
      return (item.noMixerPartial ?? '').trim().isNotEmpty
          ? item.noMixerPartial
          : item.noMixer;
    }
    if (item is BonggolanItem) return item.noBonggolan;
    if (item is FurnitureWipItem) {
      // ✅ CEK DULU apakah ini partial (BC.) atau full (BB.)
      final partialCode = (item.noFurnitureWIPPartial ?? '').trim();
      if (partialCode.isNotEmpty) {
        return partialCode;  // BC.0000003358
      }
      return item.noFurnitureWIP;  // BB.0000036786
    }
    if (item is BarangJadiItem) {
      // ✅ CEK DULU apakah ini partial (BL.) atau full (BA.)
      final partialCode = (item.noBJPartial ?? '').trim();
      if (partialCode.isNotEmpty) {
        return partialCode;  // BL.0000001305
      }
      return item.noBJ;  // BA.XXXXXXXXXX
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BongkarSusunInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noBongkarSusun);
        final err = vm.inputsError(widget.noBongkarSusun);
        final inputs = vm.inputsOf(widget.noBongkarSusun);
        final perm = context.watch<PermissionViewModel>();
        final canDelete = perm.can('label_crusher:delete');

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Inputs • ${widget.noBongkarSusun}'),
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
                      vm.loadInputs(widget.noBongkarSusun, force: true);
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
                  return Center(
                      child: Text('Gagal memuat inputs:\n$err'));
                }

                // ===== MERGE DB + TEMP (9 categories) =====
                final brokerAll = loading
                    ? <BrokerItem>[]
                    : [
                  ...vm.tempBrokerPartial.reversed,
                  ...vm.tempBroker.reversed,
                  ...?inputs?.broker
                ];

                final bbAll = loading
                    ? <BbItem>[]
                    : [
                  ...vm.tempBbPartial.reversed,
                  ...vm.tempBb.reversed,
                  ...?inputs?.bb,
                ];

                final washingAll = loading
                    ? <WashingItem>[]
                    : [...vm.tempWashing, ...?inputs?.washing];

                final crusherAll = loading
                    ? <CrusherItem>[]
                    : [...vm.tempCrusher, ...?inputs?.crusher];

                final gilinganAll = loading
                    ? <GilinganItem>[]
                    : [
                  ...vm.tempGilinganPartial.reversed,
                  ...vm.tempGilingan.reversed,
                  ...?inputs?.gilingan,
                ];

                final mixerAll = loading
                    ? <MixerItem>[]
                    : [
                  ...vm.tempMixerPartial.reversed,
                  ...vm.tempMixer.reversed,
                  ...?inputs?.mixer,
                ];

                // ✅ NEW: Bonggolan, FurnitureWIP, BarangJadi
                final bonggolanAll = loading
                    ? <BonggolanItem>[]
                    : [...vm.tempBonggolan, ...?inputs?.bonggolan];

                final furnitureWipAll = loading
                    ? <FurnitureWipItem>[]
                    : [
                  ...vm.tempFurnitureWipPartial.reversed,
                  ...vm.tempFurnitureWip.reversed,
                  ...?inputs?.furnitureWip,
                ];

                final barangJadiAll = loading
                    ? <BarangJadiItem>[]
                    : [
                  ...vm.tempBarangJadiPartial.reversed,
                  ...vm.tempBarangJadi.reversed,
                  ...?inputs?.barangJadi,
                ];

                // ===== GROUPED =====
                final brokerGroups = groupBy(brokerAll, brokerTitleKey);
                final bbGroups = groupBy(bbAll, bbTitleKey);
                final washingGroups = groupBy(
                    washingAll, (WashingItem e) => e.noWashing ?? '-');
                final crusherGroups = groupBy(
                    crusherAll, (CrusherItem e) => e.noCrusher ?? '-');
                final gilinganGroups =
                groupBy(gilinganAll, gilinganTitleKey);
                final mixerGroups = groupBy(mixerAll, mixerTitleKey);
                final bonggolanGroups = groupBy(
                    bonggolanAll,  (BonggolanItem e) => e.noBonggolan ?? '-');
                final furnitureWipGroups =
                groupBy(furnitureWipAll, furnitureWipTitleKey);
                final barangJadiGroups =
                groupBy(barangJadiAll, barangJadiTitleKey);

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
                                value: 'full', child: Text('FULL PALLET')),
                            DropdownMenuItem(
                                value: 'select',
                                child: Text('SEBAGIAN PALLET')),
                            DropdownMenuItem(
                                value: 'partial', child: Text('PARTIAL')),
                          ],
                          selectedMode: _selectedMode,
                          manualHint: 'X.XXXXXXXXXX',
                          isProcessing: vm.isLookupLoading,
                          onModeChanged: (mode) =>
                              setState(() => _selectedMode = mode),
                          onCodeScanned: (code) =>
                              _onCodeReady(context, code),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // === SECTION KANAN: Data Cards (3x3 Grid) ===
                      Expanded(
                        child: Column(
                          children: [
                            // ROW 1: Broker, BB, Washing
                            Expanded(
                              child: Row(
                                children: [
                                  _buildBrokerCard(
                                      brokerGroups, vm, loading, canDelete),
                                  const SizedBox(width: 8),
                                  _buildBbCard(
                                      bbGroups, vm, loading, canDelete),
                                  const SizedBox(width: 8),
                                  _buildWashingCard(
                                      washingGroups, vm, loading, canDelete),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ROW 2: Crusher, Gilingan, Mixer
                            Expanded(
                              child: Row(
                                children: [
                                  _buildCrusherCard(
                                      crusherGroups, vm, loading, canDelete),
                                  const SizedBox(width: 8),
                                  _buildGilinganCard(
                                      gilinganGroups, vm, loading, canDelete),
                                  const SizedBox(width: 8),
                                  _buildMixerCard(
                                      mixerGroups, vm, loading, canDelete),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ROW 3: Bonggolan, FurnitureWIP, BarangJadi
                            Expanded(
                              child: Row(
                                children: [
                                  _buildBonggolanCard(
                                      bonggolanGroups, vm, loading, canDelete),
                                  const SizedBox(width: 8),
                                  _buildFurnitureWipCard(furnitureWipGroups,
                                      vm, loading, canDelete),
                                  const SizedBox(width: 8),
                                  _buildBarangJadiCard(barangJadiGroups, vm,
                                      loading, canDelete),
                                ],
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

  // ===== CARD BUILDERS (1-6: sama seperti broker) =====

  Widget _buildBrokerCard(Map<String, List<BrokerItem>> groups,
      BongkarSusunInputViewModel vm, bool loading, bool canDelete) {
    return Expanded(
      child: SectionCard(
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
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            final hasPartial =
            entry.value.any((x) => x.isPartialRow);

            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: hasPartial
                  ? const ['Label', 'Sak', 'Berat', 'Action']
                  : const ['Sak', 'Berat', 'Action'],
              columnFlexes: hasPartial ? const [3, 1, 2] : const [1, 2],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              summaryBuilder: () {
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(totalBerat: totalBerat);
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final dbItems = currentInputs == null
                    ? <BrokerItem>[]
                    : currentInputs.broker
                    .where((x) => brokerTitleKey(x) == entry.key);
                final tempFull = vm.tempBroker
                    .where((x) => brokerTitleKey(x) == entry.key);
                final tempPart = vm.tempBrokerPartial
                    .where((x) => brokerTitleKey(x) == entry.key);

                final items = <BrokerItem>[
                  ...tempPart,
                  ...dbItems,
                  ...tempFull,
                ];

                return items.map((item) {
                  final bool isTemp = vm.tempBroker.contains(item) ||
                      vm.tempBrokerPartial.contains(item);

                  final columns = hasPartial
                      ? [
                    item.isPartialRow
                        ? item.noBroker.toString()
                        : '-',
                    '${item.noSak ?? '-'}',
                    '${num2(item.berat)} kg',
                  ]
                      : [
                    '${item.noSak ?? '-'}',
                    '${num2(item.berat)} kg',
                  ];

                  return BongkarSusunTooltipTableRow(
                    columns: columns,
                    columnFlexes:
                    hasPartial ? const [3, 1, 2] : const [1, 2],
                    showDelete: isTemp,
                    onDelete: isTemp
                        ? () => vm.deleteTempBrokerItem(item)
                        : null,
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
      ),
    );
  }

  Widget _buildBbCard(Map<String, List<BbItem>> groups,
      BongkarSusunInputViewModel vm, bool loading, bool canDelete) {
    return Expanded(
      child: SectionCard(
        title: 'Bahan Baku',
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
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            final hasPartial =
            entry.value.any((x) => x.isPartialRow);

            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: hasPartial
                  ? const ['Label', 'Sak', 'Berat', 'Action']
                  : const ['Sak', 'Berat', 'Action'],
              columnFlexes: hasPartial ? const [3, 1, 2] : const [1, 2],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              summaryBuilder: () {
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(totalBerat: totalBerat);
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final dbItems = currentInputs == null
                    ? <BbItem>[]
                    : currentInputs.bb
                    .where((x) => bbTitleKey(x) == entry.key);
                final tempFull = vm.tempBb
                    .where((x) => bbTitleKey(x) == entry.key);
                final tempPart = vm.tempBbPartial
                    .where((x) => bbTitleKey(x) == entry.key);

                final items = [
                  ...tempPart,
                  ...dbItems,
                  ...tempFull,
                ];

                return items.map((item) {
                  final isTemp = vm.tempBb.contains(item) ||
                      vm.tempBbPartial.contains(item);

                  final columns = hasPartial
                      ? [
                    item.isPartialRow
                        ? bbPairLabel(item)
                        : '-',
                    '${item.noSak ?? '-'}',
                    '${num2(item.berat)} kg',
                  ]
                      : [
                    '${item.noSak ?? '-'}',
                    '${num2(item.berat)} kg',
                  ];

                  return BongkarSusunTooltipTableRow(
                    columns: columns,
                    columnFlexes:
                    hasPartial ? const [3, 1, 2] : const [1, 2],
                    showDelete: isTemp,
                    onDelete:
                    isTemp ? () => vm.deleteTempBbItem(item) : null,
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
      ),
    );
  }

  Widget _buildWashingCard(Map<String, List<WashingItem>> groups,
      BongkarSusunInputViewModel vm, bool loading, bool canDelete) {
    return Expanded(
      child: SectionCard(
        title: 'Washing',
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
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: const ['Sak', 'Berat', 'Action'],
              columnFlexes: const [1, 2],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              summaryBuilder: () {
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(totalBerat: totalBerat);
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final items = [
                  if (currentInputs != null)
                    ...currentInputs.washing.where(
                            (x) => (x.noWashing ?? '-') == entry.key),
                  ...vm.tempWashing
                      .where((x) => (x.noWashing ?? '-') == entry.key),
                ];
                return items.map((item) {
                  final isTemp = vm.tempWashing.contains(item);
                  return BongkarSusunTooltipTableRow(
                    columns: [
                      item.noSak?.toString() ?? '-',
                      '${num2(item.berat)} kg',
                    ],
                    columnFlexes: const [1, 2],
                    showDelete: isTemp,
                    onDelete: isTemp
                        ? () => vm.deleteTempWashingItem(item)
                        : null,
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
      ),
    );
  }

  Widget _buildCrusherCard(Map<String, List<CrusherItem>> groups,
      BongkarSusunInputViewModel vm, bool loading, bool canDelete) {
    return Expanded(
      child: SectionCard(
        title: 'Crusher',
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
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: const ['Berat', 'Action'],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              summaryBuilder: () {
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(totalBerat: totalBerat);
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final items = [
                  if (currentInputs != null)
                    ...currentInputs.crusher.where(
                            (x) => (x.noCrusher ?? '-') == entry.key),
                  ...vm.tempCrusher
                      .where((x) => (x.noCrusher ?? '-') == entry.key),
                ];
                return items.map((item) {
                  final isTemp = vm.tempCrusher.contains(item);
                  return BongkarSusunTooltipTableRow(
                    columns: ['${num2(item.berat)} kg'],
                    showDelete: isTemp,
                    onDelete: isTemp
                        ? () => vm.deleteTempCrusherItem(item)
                        : null,
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
      ),
    );
  }

  Widget _buildGilinganCard(Map<String, List<GilinganItem>> groups,
      BongkarSusunInputViewModel vm, bool loading, bool canDelete) {
    return Expanded(
      child: SectionCard(
        title: 'Gilingan',
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
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            final hasPartial =
            entry.value.any((x) => x.isPartialRow);

            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: hasPartial
                  ? const ['Label', 'Berat', 'Action']
                  : const ['Berat', 'Action'],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              summaryBuilder: () {
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(totalBerat: totalBerat);
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final dbItems = currentInputs == null
                    ? <GilinganItem>[]
                    : currentInputs.gilingan
                    .where((x) => gilinganTitleKey(x) == entry.key);
                final tempFull = vm.tempGilingan
                    .where((x) => gilinganTitleKey(x) == entry.key);
                final tempPart = vm.tempGilinganPartial
                    .where((x) => gilinganTitleKey(x) == entry.key);

                final items = [
                  ...tempPart,
                  ...dbItems,
                  ...tempFull,
                ];

                return items.map((item) {
                  final isTemp =
                      vm.tempGilingan.contains(item) ||
                          vm.tempGilinganPartial.contains(item);

                  final columns = item.isPartialRow
                      ? <String>[
                    (item.noGilingan ?? '-'),
                    '${num2(item.berat)} kg',
                  ]
                      : <String>[
                    '${num2(item.berat)} kg',
                  ];

                  return BongkarSusunTooltipTableRow(
                    columns: columns,
                    showDelete: isTemp,
                    onDelete: isTemp
                        ? () => vm.deleteTempGilinganItem(item)
                        : null,
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
      ),
    );
  }

  Widget _buildMixerCard(Map<String, List<MixerItem>> groups,
      BongkarSusunInputViewModel vm, bool loading, bool canDelete) {
    return Expanded(
      child: SectionCard(
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
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            final hasPartial =
            entry.value.any((x) => x.isPartialRow);

            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: hasPartial
                  ? const ['Label', 'Sak', 'Berat', 'Action']
                  : const ['Sak', 'Berat', 'Action'],
              columnFlexes: hasPartial ? const [3, 1, 2] : const [1, 2],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              summaryBuilder: () {
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(totalBerat: totalBerat);
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final dbItems = currentInputs == null
                    ? <MixerItem>[]
                    : currentInputs.mixer
                    .where((x) => mixerTitleKey(x) == entry.key)
                    .toList();
                final tempFull = vm.tempMixer
                    .where((x) => mixerTitleKey(x) == entry.key)
                    .toList();
                final tempPart = vm.tempMixerPartial
                    .where((x) => mixerTitleKey(x) == entry.key)
                    .toList();

                final items = [
                  ...tempPart,
                  ...dbItems,
                  ...tempFull,
                ];

                return items.map((item) {
                  final isTemp = vm.tempMixer.contains(item) ||
                      vm.tempMixerPartial.contains(item);

                  final columns = item.isPartialRow
                      ? [
                    item.noMixer ?? '-',
                    '${item.noSak ?? '-'}',
                    '${num2(item.berat)} kg',
                  ]
                      : [
                    '${item.noSak ?? '-'}',
                    '${num2(item.berat)} kg',
                  ];

                  return BongkarSusunTooltipTableRow(
                    columns: columns,
                    columnFlexes:
                    hasPartial ? const [3, 1, 2] : const [1, 2],
                    showDelete: isTemp,
                    onDelete: isTemp
                        ? () => vm.deleteTempMixerItem(item)
                        : null,
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
      ),
    );
  }

  // ===== NEW CARD BUILDERS (7-9) =====

  Widget _buildBonggolanCard(Map<String, List<BonggolanItem>> groups,
      BongkarSusunInputViewModel vm, bool loading, bool canDelete) {
    return Expanded(
      child: SectionCard(
        title: 'Bonggolan',
        count: groups.length,
        color: Colors.blue,
        isLoading: loading,
        summaryBuilder: () {
          int totalData = groups.length;
          double totalBerat = 0.0;
          for (final entry in groups.entries) {
            for (final item in entry.value) {
              totalBerat += (item.berat ?? 0.0);
            }
          }
          return SectionSummary(
            totalData: totalData,
            totalSak: 0, // No sak for Bonggolan
            totalBerat: totalBerat,
          );
        },
        child: groups.isEmpty
            ? const Center(
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: const ['Berat', 'Action'],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              summaryBuilder: () {
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(totalBerat: totalBerat);
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final items = [
                  if (currentInputs != null)
                    ...currentInputs.bonggolan.where(
                            (x) => (x.noBonggolan ?? '-') == entry.key),
                  ...vm.tempBonggolan.where(
                          (x) => (x.noBonggolan ?? '-') == entry.key),
                ];
                return items.map((item) {
                  final isTemp = vm.tempBonggolan.contains(item);
                  return BongkarSusunTooltipTableRow(
                    columns: ['${num2(item.berat)} kg'],
                    showDelete: isTemp,
                    onDelete: isTemp
                        ? () => vm.deleteTempBonggolanItem(item)
                        : null,
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
      ),
    );
  }

  Widget _buildFurnitureWipCard(
      Map<String, List<FurnitureWipItem>> groups,
      BongkarSusunInputViewModel vm,
      bool loading,
      bool canDelete) {
    return Expanded(
      child: SectionCard(
        title: 'Furniture WIP',
        count: groups.length,
        color: Colors.blue,
        isLoading: loading,
        summaryBuilder: () {
          int totalData = groups.length;
          int totalPcs = 0;
          double totalBerat = 0.0;
          for (final entry in groups.entries) {
            for (final item in entry.value) {
              totalPcs += (item.pcs ?? 0);
              totalBerat += (item.berat ?? 0.0);
            }
          }
          return SectionSummary(
            totalData: totalData,
            totalSak: totalPcs, // Use PCS field
            totalBerat: totalBerat,
          );
        },
        child: groups.isEmpty
            ? const Center(
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            final hasPartial =
            entry.value.any((x) => x.isPartialRow);

            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: hasPartial
                  ? const ['Label', 'Pcs', 'Berat', 'Action']
                  : const ['Pcs', 'Berat', 'Action'],
              columnFlexes: hasPartial ? const [3, 1, 2] : const [1, 2],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              hasPcsColumn: true, // ✅ Enable PCS summary
              summaryBuilder: () {
                int totalPcs = 0;
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalPcs += (item.pcs ?? 0);
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(
                  totalBerat: totalBerat,
                  totalPcs: totalPcs,
                );
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final dbItems = currentInputs == null
                    ? <FurnitureWipItem>[]
                    : currentInputs.furnitureWip.where(
                        (x) => furnitureWipTitleKey(x) == entry.key);
                final tempFull = vm.tempFurnitureWip.where(
                        (x) => furnitureWipTitleKey(x) == entry.key);
                final tempPart = vm.tempFurnitureWipPartial
                    .where(
                        (x) => furnitureWipTitleKey(x) == entry.key);

                final items = [
                  ...tempPart,
                  ...dbItems,
                  ...tempFull,
                ];

                return items.map((item) {
                  final isTemp =
                      vm.tempFurnitureWip.contains(item) ||
                          vm.tempFurnitureWipPartial.contains(item);

                  final columns = hasPartial
                      ? [
                    item.isPartialRow
                        ? item.noFurnitureWIP ?? '-'
                        : '-',
                    '${item.pcs ?? 0} pcs',
                    '${num2(item.berat)} kg',
                  ]
                      : [
                    '${item.pcs ?? 0} pcs',
                    '${num2(item.berat)} kg',
                  ];

                  return BongkarSusunTooltipTableRow(
                    columns: columns,
                    columnFlexes:
                    hasPartial ? const [3, 1, 2] : const [1, 2],
                    showDelete: isTemp,
                    onDelete: isTemp
                        ? () => vm.deleteTempFurnitureWipItem(item)
                        : null,
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
      ),
    );
  }

  Widget _buildBarangJadiCard(Map<String, List<BarangJadiItem>> groups,
      BongkarSusunInputViewModel vm, bool loading, bool canDelete) {
    return Expanded(
      child: SectionCard(
        title: 'Barang Jadi',
        count: groups.length,
        color: Colors.blue,
        isLoading: loading,
        summaryBuilder: () {
          int totalData = groups.length;
          int totalPcs = 0;
          double totalBerat = 0.0;
          for (final entry in groups.entries) {
            for (final item in entry.value) {
              totalPcs += (item.pcs ?? 0);
              totalBerat += (item.berat ?? 0.0);
            }
          }
          return SectionSummary(
            totalData: totalData,
            totalSak: totalPcs, // Use PCS field
            totalBerat: totalBerat,
          );
        },
        child: groups.isEmpty
            ? const Center(
            child: Text('Tidak ada data',
                style: TextStyle(fontSize: 11)))
            : ListView(
          padding: const EdgeInsets.all(8),
          children: groups.entries.map((entry) {
            final hasPartial =
            entry.value.any((x) => x.isPartialRow);

            return BongkarSusunGroupTooltipAnchorTile(
              title: entry.key,
              headerSubtitle: (entry.value.isNotEmpty
                  ? entry.value.first.namaJenis
                  : '-') ??
                  '-',
              color: Colors.blue,
              tableHeaders: hasPartial
                  ? const ['Label', 'Pcs', 'Berat', 'Action']
                  : const ['Pcs', 'Berat', 'Action'],
              columnFlexes: hasPartial ? const [3, 1, 2] : const [1, 2],
              canDelete: canDelete,
              onBulkDelete: _handleBulkDelete,
              hasPcsColumn: true, // ✅ Enable PCS summary
              summaryBuilder: () {
                int totalPcs = 0;
                double totalBerat = 0.0;
                for (final item in entry.value) {
                  totalPcs += (item.pcs ?? 0);
                  totalBerat += (item.berat ?? 0.0);
                }
                return TooltipSummary(
                  totalBerat: totalBerat,
                  totalPcs: totalPcs,
                );
              },
              detailsBuilder: () {
                final currentInputs =
                vm.inputsOf(widget.noBongkarSusun);
                final dbItems = currentInputs == null
                    ? <BarangJadiItem>[]
                    : currentInputs.barangJadi.where(
                        (x) => barangJadiTitleKey(x) == entry.key);
                final tempFull = vm.tempBarangJadi
                    .where((x) => barangJadiTitleKey(x) == entry.key);
                final tempPart = vm.tempBarangJadiPartial.where(
                        (x) => barangJadiTitleKey(x) == entry.key);

                final items = [
                  ...tempPart,
                  ...dbItems,
                  ...tempFull,
                ];

                return items.map((item) {
                  final isTemp = vm.tempBarangJadi.contains(item) ||
                      vm.tempBarangJadiPartial.contains(item);

                  final columns = hasPartial
                      ? [
                    item.isPartialRow ? item.noBJ ?? '-' : '-',
                    '${item.pcs ?? 0} pcs',
                    '${num2(item.berat)} kg',
                  ]
                      : [
                    '${item.pcs ?? 0} pcs',
                    '${num2(item.berat)} kg',
                  ];

                  return BongkarSusunTooltipTableRow(
                    columns: columns,
                    columnFlexes:
                    hasPartial ? const [3, 1, 2] : const [1, 2],
                    showDelete: isTemp,
                    onDelete: isTemp
                        ? () => vm.deleteTempBarangJadiItem(item)
                        : null,
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
      ),
    );
  }
}