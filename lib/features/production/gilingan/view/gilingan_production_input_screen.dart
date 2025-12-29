// lib/features/production/gilingan/view/gilingan_production_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';

import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../../shared/widgets/partial_mode_not_supported_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';

import 'package:pps_tablet/features/production/shared/shared.dart'; // SectionCard, SectionInputCard, groupBy, helpers
import '../../shared/utils/format.dart';

// ✅ ganti ke path sesuai struktur project kamu
import '../view_model/gilingan_production_input_view_model.dart';
import '../model/gilingan_inputs_model.dart';

// ✅ ganti ke widget popover gilingan kamu (hasil copy dari broker, tapi type VM = GilinganProductionInputViewModel)
import '../widgets/gilingan_input_group_popover.dart';

// ✅ ganti ke dialog lookup gilingan versi kamu
import '../widgets/gilingan_lookup_label_dialog.dart';
import '../widgets/gilingan_lookup_label_partial_dialog.dart';

class GilinganProductionInputScreen extends StatefulWidget {
  final String noProduksi;
  final bool? isLocked;
  final DateTime? lastClosedDate;

  const GilinganProductionInputScreen({
    super.key,
    required this.noProduksi,
    this.isLocked,
    this.lastClosedDate,
  });

  @override
  State<GilinganProductionInputScreen> createState() =>
      _GilinganProductionInputScreenState();
}

class _GilinganProductionInputScreenState
    extends State<GilinganProductionInputScreen> {
  String _selectedMode = 'full';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<GilinganProductionInputViewModel>();
      final already = vm.inputsOf(widget.noProduksi) != null;
      final loading = vm.isInputsLoading(widget.noProduksi);
      if (!already && !loading) {
        vm.loadInputs(widget.noProduksi);
      }
    });
  }

  Future<bool> _onWillPop() async {
    final vm = context.read<GilinganProductionInputViewModel>();

    if (vm.totalTempCount == 0) return true;

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

  Future<bool> _handleBulkDelete(List<dynamic> items) async {
    final vm = context.read<GilinganProductionInputViewModel>();

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
    final vm = context.read<GilinganProductionInputViewModel>();

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
    final vm = context.read<GilinganProductionInputViewModel>();

    // ✅ VALIDASI partial mode untuk label yang TIDAK support partial
    // Di GilinganInputs kamu ada: Broker (D.), Bonggolan (M.), Crusher (F.), Reject (BF.)
    // Umumnya partial hanya untuk D. dan BF. (sesuaikan aturanmu)
    if (_selectedMode == 'partial') {
      final c = code.trim().toUpperCase();
      final prefix2 = c.length >= 2 ? c.substring(0, 2) : c;

      // Bonggolan M. dan Crusher F. tidak support partial
      if (prefix2 == 'M.' || prefix2 == 'F.') {
        final labelType = prefix2 == 'M.' ? 'Bonggolan' : 'Crusher';
        await PartialModeNotSupportedDialog.show(
          context: context,
          labelType: labelType,
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
          content: Text('Label "$code" tidak memiliki data yang tersedia.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }

    if (_selectedMode == 'full') {
      await _handleFullMode(context, vm, res);
    } else if (_selectedMode == 'partial') {
      await _handlePartialMode(context, vm, res);
    } else {
      await _handleSelectMode(context, vm, res);
    }
  }

  Future<void> _handleFullMode(
      BuildContext context,
      GilinganProductionInputViewModel vm,
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

    final r = vm.commitPickedToTemp(noProduksi: widget.noProduksi);

    final msg = r.added > 0
        ? '✅ Auto-added ${r.added} item${r.skipped > 0 ? ' • Duplikat terlewati ${r.skipped}' : ''}'
        : 'Tidak ada item baru ditambahkan';

    _showSnack(msg,
        backgroundColor: r.added > 0 ? Colors.green : Colors.orange);
  }

  Future<void> _handlePartialMode(
      BuildContext context,
      GilinganProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => GilinganLookupLabelPartialDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  Future<void> _handleSelectMode(
      BuildContext context,
      GilinganProductionInputViewModel vm,
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
      builder: (_) => GilinganLookupLabelDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;

    // pakai rule yang sama seperti di Broker screen (prioritas partial code jika ada)
    if (item is BrokerItem) {
      return (item.noBrokerPartial ?? '').trim().isNotEmpty
          ? item.noBrokerPartial
          : item.noBroker;
    }
    if (item is BonggolanItem) return item.noBonggolan;
    if (item is CrusherItem) return item.noCrusher;
    if (item is RejectItem) {
      return (item.noRejectPartial ?? '').trim().isNotEmpty
          ? item.noRejectPartial
          : item.noReject;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GilinganProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);

        final perm = context.watch<PermissionViewModel>();
        final locked = widget.isLocked == true;

        final canDeleteByPerm = perm.can('label_washing:delete');
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
                  if (canPop && mounted) Navigator.pop(context);
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
                                'Apakah Anda yakin ingin menghapus ${vm.totalTempCount} item temp?'),
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
                                size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus Semua Temp',
                                style: TextStyle(color: Colors.red)),
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
                final brokerAll = loading
                    ? <BrokerItem>[]
                    : [
                  ...vm.tempBroker.reversed,
                  ...vm.tempBrokerPartial.reversed,
                  ...?inputs?.broker,
                ];

                final bonggolanAll = loading
                    ? <BonggolanItem>[]
                    : [
                  ...vm.tempBonggolan.reversed,
                  ...?inputs?.bonggolan,
                ];

                final crusherAll = loading
                    ? <CrusherItem>[]
                    : [
                  ...vm.tempCrusher.reversed,
                  ...?inputs?.crusher,
                ];

                final rejectAll = loading
                    ? <RejectItem>[]
                    : [
                  ...vm.tempReject.reversed,
                  ...vm.tempRejectPartial.reversed,
                  ...?inputs?.reject,
                ];

                // ===== GROUPS =====
                final brokerGroups = groupBy(brokerAll, brokerTitleKey);
                final bonggolanGroups = groupBy(
                  bonggolanAll,
                      (BonggolanItem e) => e.noBonggolan ?? '-',
                );
                final crusherGroups = groupBy(
                  crusherAll,
                      (CrusherItem e) => e.noCrusher ?? '-',
                );
                final rejectGroups = groupBy(rejectAll, rejectTitleKey);

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // === KIRI: Scan / Manual ===
                      SizedBox(
                        width: 380,
                        child: SectionInputCard(
                          title: 'Input via Scan / Manual',
                          modeLabel: 'Pilih Mode',
                          modeItems: const [
                            DropdownMenuItem(value: 'full', child: Text('FULL PALLET')),
                            DropdownMenuItem(value: 'select', child: Text('SEBAGIAN PALLET')),
                            DropdownMenuItem(value: 'partial', child: Text('PARTIAL')),
                          ],
                          selectedMode: _selectedMode,
                          manualHint: 'X.XXXXXXXXXX',
                          isProcessing: vm.isLookupLoading,
                          isLocked: locked,
                          onModeChanged: (mode) => setState(() => _selectedMode = mode),
                          onCodeScanned: (code) => _onCodeReady(context, code),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // === KANAN: 4 Cards ===
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  // BROKER
                                  Expanded(
                                    child: _buildCardBroker(
                                      loading: loading,
                                      canDelete: canDelete,
                                      groups: brokerGroups,
                                      vm: vm,
                                      inputs: inputs,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // BONGGOLAN
                                  Expanded(
                                    child: _buildCardBonggolan(
                                      loading: loading,
                                      canDelete: canDelete,
                                      groups: bonggolanGroups,
                                      vm: vm,
                                      inputs: inputs,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // CRUSHER
                                  Expanded(
                                    child: _buildCardCrusher(
                                      loading: loading,
                                      canDelete: canDelete,
                                      groups: crusherGroups,
                                      vm: vm,
                                      inputs: inputs,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // REJECT
                                  Expanded(
                                    child: _buildCardReject(
                                      loading: loading,
                                      canDelete: canDelete,
                                      groups: rejectGroups,
                                      vm: vm,
                                      inputs: inputs,
                                      onBulkDelete: _handleBulkDelete,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // const SizedBox(height: 12),
                            // Expanded(
                            //   child: Row(
                            //     children: [
                            //
                            //     ],
                            //   ),
                            // ),
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

  // ---------------- UI Builders ----------------

  Widget _buildCardBroker({
    required bool loading,
    required bool canDelete,
    required Map<String, List<BrokerItem>> groups,
    required GilinganProductionInputViewModel vm,
    required GilinganInputs? inputs,
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
          final hasPartial = entry.value.any((x) => x.isPartialRow);
          final headers = hasPartial
              ? const ['Label', 'Sak', 'Berat', 'Action']
              : const ['Sak', 'Berat', 'Action'];
          final columnFlexes =
          hasPartial ? const [3, 1, 2] : const [1, 2];

          return GroupTooltipAnchorTile(
            title: entry.key,
            headerSubtitle:
            (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ??
                '-',
            color: Colors.blue,
            tableHeaders: headers,
            columnFlexes: columnFlexes,
            canDelete: canDelete,
            onBulkDelete: (items) => _handleBulkDelete(items),
            summaryBuilder: () {
              double totalBerat = 0.0;
              for (final item in entry.value) {
                totalBerat += (item.berat ?? 0.0);
              }
              return TooltipSummary(totalBerat: totalBerat);
            },
            detailsBuilder: () {
              final dbItems = inputs == null
                  ? <BrokerItem>[]
                  : inputs.broker.where((x) => brokerTitleKey(x) == entry.key).toList();

              final tempFull = vm.tempBroker
                  .where((x) => brokerTitleKey(x) == entry.key)
                  .toList();

              final tempPart = vm.tempBrokerPartial
                  .where((x) => brokerTitleKey(x) == entry.key)
                  .toList();

              final items = <BrokerItem>[
                ...tempPart,
                ...dbItems,
                ...tempFull,
              ];

              return items.map((item) {
                final isTemp =
                    vm.tempBroker.contains(item) ||
                        vm.tempBrokerPartial.contains(item);

                final columns = hasPartial
                    ? <String>[
                  item.isPartialRow ? (item.noBroker ?? '-') : '-',
                  '${item.noSak ?? '-'}',
                  '${num2(item.berat)} kg',
                ]
                    : <String>[
                  '${item.noSak ?? '-'}',
                  '${num2(item.berat)} kg',
                ];

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
        }).toList(),
      ),
    );
  }

  Widget _buildCardBonggolan({
    required bool loading,
    required bool canDelete,
    required Map<String, List<BonggolanItem>> groups,
    required GilinganProductionInputViewModel vm,
    required GilinganInputs? inputs,
  }) {
    return SectionCard(
      title: 'Bonggolan',
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
          return GroupTooltipAnchorTile(
            title: entry.key,
            headerSubtitle:
            (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ??
                '-',
            color: Colors.blue,
            tableHeaders: const ['Berat', 'Action'],
            canDelete: canDelete,
            onBulkDelete: (items) => _handleBulkDelete(items),
            detailsBuilder: () {
              final dbItems = inputs == null
                  ? <BonggolanItem>[]
                  : inputs.bonggolan
                  .where((x) => (x.noBonggolan ?? '-') == entry.key)
                  .toList();

              final tempItems = vm.tempBonggolan
                  .where((x) => (x.noBonggolan ?? '-') == entry.key)
                  .toList();

              final items = <BonggolanItem>[
                ...dbItems,
                ...tempItems,
              ];

              return items.map((item) {
                final isTemp = vm.tempBonggolan.contains(item);
                return TooltipTableRow(
                  columns: ['${num2(item.berat)} kg'],
                  showDelete: isTemp,
                  onDelete:
                  isTemp ? () => vm.deleteTempBonggolanItem(item) : null,
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
  }

  Widget _buildCardCrusher({
    required bool loading,
    required bool canDelete,
    required Map<String, List<CrusherItem>> groups,
    required GilinganProductionInputViewModel vm,
    required GilinganInputs? inputs,
  }) {
    return SectionCard(
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
          child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
          : ListView(
        padding: const EdgeInsets.all(8),
        children: groups.entries.map((entry) {
          return GroupTooltipAnchorTile(
            title: entry.key,
            headerSubtitle:
            (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ??
                '-',
            color: Colors.blue,
            tableHeaders: const ['Berat', 'Action'],
            canDelete: canDelete,
            onBulkDelete: (items) => _handleBulkDelete(items),
            detailsBuilder: () {
              final dbItems = inputs == null
                  ? <CrusherItem>[]
                  : inputs.crusher
                  .where((x) => (x.noCrusher ?? '-') == entry.key)
                  .toList();

              final tempItems = vm.tempCrusher
                  .where((x) => (x.noCrusher ?? '-') == entry.key)
                  .toList();

              final items = <CrusherItem>[
                ...dbItems,
                ...tempItems,
              ];

              return items.map((item) {
                final isTemp = vm.tempCrusher.contains(item);
                return TooltipTableRow(
                  columns: ['${num2(item.berat)} kg'],
                  showDelete: isTemp,
                  onDelete:
                  isTemp ? () => vm.deleteTempCrusherItem(item) : null,
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
  }

  Widget _buildCardReject({
    required bool loading,
    required bool canDelete,
    required Map<String, List<RejectItem>> groups,
    required GilinganProductionInputViewModel vm,
    required GilinganInputs? inputs,
    required Future<bool> Function(List<dynamic>) onBulkDelete,
  }) {
    return SectionCard(
      title: 'Reject',
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
          final hasPartial = entry.value.any((x) => x.isPartialRow);

          return GroupTooltipAnchorTile(
            title: entry.key,
            headerSubtitle:
            (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ??
                '-',
            color: Colors.blue,
            tableHeaders:
            hasPartial ? const ['Label', 'Berat', 'Action'] : const ['Berat', 'Action'],
            canDelete: canDelete,
            onBulkDelete: onBulkDelete,
            detailsBuilder: () {
              final dbItems = inputs == null
                  ? <RejectItem>[]
                  : inputs.reject
                  .where((x) => rejectTitleKey(x) == entry.key)
                  .toList();

              final tempFull = vm.tempReject
                  .where((x) => rejectTitleKey(x) == entry.key)
                  .toList();

              final tempPart = vm.tempRejectPartial
                  .where((x) => rejectTitleKey(x) == entry.key)
                  .toList();

              final items = <RejectItem>[
                ...tempPart,
                ...dbItems,
                ...tempFull,
              ];

              return items.map((item) {
                final isTemp =
                    vm.tempReject.contains(item) ||
                        vm.tempRejectPartial.contains(item);

                final columns = item.isPartialRow
                    ? <String>[
                  (item.noReject ?? '-'),
                  '${num2(item.berat)} kg',
                ]
                    : <String>[
                  '${num2(item.berat)} kg',
                ];

                return TooltipTableRow(
                  columns: columns,
                  showDelete: isTemp,
                  onDelete: isTemp ? () => vm.deleteTempRejectItem(item) : null,
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
  }
}
