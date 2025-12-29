// lib/features/production/crusher/view/crusher_production_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/production/crusher/view_model/crusher_production_input_view_model.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/loading_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../shared/models/broker_item.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/partial_mode_not_supported_dialog.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../widgets/crusher_input_group_popover.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import '../model/crusher_inputs_model.dart';


import 'package:pps_tablet/features/production/shared/shared.dart';

import '../widgets/crusher_lookup_label_dialog.dart';
import '../widgets/crusher_lookup_label_partial_dialog.dart';

class CrusherProductionInputScreen extends StatefulWidget {
  final String noCrusherProduksi;
  final bool? isLocked;
  final DateTime? lastClosedDate;

  const CrusherProductionInputScreen({
    super.key,
    required this.noCrusherProduksi,
    this.isLocked,
    this.lastClosedDate,
  });

  @override
  State<CrusherProductionInputScreen> createState() => _CrusherProductionInputScreenState();
}

class _CrusherProductionInputScreenState extends State<CrusherProductionInputScreen> {
  String _selectedMode = 'full';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CrusherProductionInputViewModel>();
      final already = vm.inputsOf(widget.noCrusherProduksi) != null;
      final loading = vm.isInputsLoading(widget.noCrusherProduksi);
      if (!already && !loading) {
        vm.loadInputs(widget.noCrusherProduksi);
      }
    });
  }

  // ✅ Handle back button with temp data check
  Future<bool> _onWillPop() async {
    final vm = context.read<CrusherProductionInputViewModel>();

    // Tidak ada temp data, boleh keluar langsung
    if (vm.totalTempCount == 0) {
      return true;
    }

    // Tampilkan dialog konfirmasi
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
    final vm = context.read<CrusherProductionInputViewModel>();

    final success = await vm.deleteItems(widget.noCrusherProduksi, items);

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
    final vm = context.read<CrusherProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      _showSnack('Tidak ada data untuk disimpan', backgroundColor: Colors.orange);
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

    final success = await vm.submitTempItems(widget.noCrusherProduksi);

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
    final vm = context.read<CrusherProductionInputViewModel>();

    // ✅ VALIDASI: Cek jika mode partial tidak support untuk washing/crusher
    if (_selectedMode == 'partial') {
      final prefix = code.trim().toUpperCase().substring(0, 2);

      if (prefix == 'B.' || prefix == 'M.') {
        final labelType = prefix == 'B.' ? 'Washing' : 'Bonggolan';

        // ✅ Tampilkan dialog informatif
        await PartialModeNotSupportedDialog.show(
          context: context,
          labelType: labelType,
          onOk: () {
            // Optional: Bisa tambahkan aksi setelah user klik OK
            // Misalnya log atau analytics
          },
        );

        return; // ❌ Stop processing
      }
    }

    // ✅ Lanjutkan proses lookup jika validasi OK
    final res = await vm.lookupLabel(code, force: true);
    if (!mounted) return;

    if (vm.lookupError != null) {
      _showSnack('Gagal ambil data: ${vm.lookupError}', backgroundColor: Colors.red);
      return;
    }

    if (res == null || res.found == false || res.data.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Data Tidak Ditemukan'),
          content: Text('Label "$code" tidak memiliki data yang tersedia.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
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


  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;

    if (item is BbItem) {
      final noBB = (item.noBahanBaku ?? '').trim();
      final palletStr = item.noPallet == null
          ? ''
          : item.noPallet.toString().trim(); // biasanya int → string

      if (noBB.isEmpty) return null;
      if (palletStr.isEmpty) {
        // Kalau tidak ada pallet, ya tampilkan NoBahanBaku saja
        return noBB;
      }

      // Contoh: A.0000000001-1
      return '$noBB-$palletStr';
    }

    return null;
  }


  /// MODE FULL: Langsung commit semua data tanpa dialog
  Future<void> _handleFullMode(
      BuildContext context,
      CrusherProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noCrusherProduksi);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp = labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp ? ' • ${vm.getTemporaryDataSummary(labelCode!)}' : '';
      _showSnack('Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix');
      return;
    }

    // Auto-select semua item baru (non-duplicate)
    vm.clearPicks();
    vm.pickAllNew(widget.noCrusherProduksi);

    // Commit langsung tanpa dialog
    final result = vm.commitPickedToTemp(noProduksi: widget.noCrusherProduksi);

    final msg = result.added > 0
        ? '✅ Auto-added ${result.added} item${result.skipped > 0 ? ' • Duplikat terlewati ${result.skipped}' : ''}'
        : 'Tidak ada item baru ditambahkan';

    _showSnack(
      msg,
      backgroundColor: result.added > 0 ? Colors.green : Colors.orange,
    );
  }

  /// MODE PARTIAL: Dialog khusus untuk partial dengan radio button (single selection)
  Future<void> _handlePartialMode(
      BuildContext context,
      CrusherProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    // ⬇️ PERBAIKAN: Tidak perlu filter karena dialog sudah menampilkan semua
    // Langsung tampilkan dialog
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CrusherLookupLabelPartialDialog(
        noProduksi: widget.noCrusherProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  /// MODE SELECT: Dialog dengan checkbox (default all selected untuk item baru)
  Future<void> _handleSelectMode(
      BuildContext context,
      CrusherProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noCrusherProduksi);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp = labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp ? ' • ${vm.getTemporaryDataSummary(labelCode!)}' : '';
      _showSnack('Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix');
      return;
    }

    // Tampilkan dialog biasa (dengan auto-select default)
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CrusherLookupLabelDialog(
        noProduksi: widget.noCrusherProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrusherProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noCrusherProduksi);
        final err = vm.inputsError(widget.noCrusherProduksi);
        final inputs = vm.inputsOf(widget.noCrusherProduksi);
        final perm = context.watch<PermissionViewModel>();
        final locked = widget.isLocked == true;

        final canDeleteByPerm = perm.can('label_washing:delete');
        final canDelete = canDeleteByPerm && !locked;
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Inputs • ${widget.noCrusherProduksi}'),
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
                      vm.loadInputs(widget.noCrusherProduksi, force: true);
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
                            Icon(Icons.delete_sweep, size: 20, color: Colors.red.shade700),
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

                // ===== MERGE DB + TEMP (BB with partial, Bonggolan without) =====
                final bbAll = loading ? <BbItem>[] : [
                  ...vm.tempBb.reversed,
                  ...vm.tempBbPartial.reversed,
                  ...?inputs?.bb,
                ];
                final bonggolAll = loading ? <BonggolanItem>[] : [
                  ...vm.tempBonggolan,
                  ...?inputs?.bonggolan,
                ];

                // ===== GROUPED =====
                final bbGroups = groupBy(bbAll, bbTitleKey);
                final bonggolGroups = groupBy(bonggolAll, (BonggolanItem e) => e.noBonggolan ?? '-');

                final locked = widget.isLocked == true;
                final closed = widget.lastClosedDate; // boleh null

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // === TODO: SECTION KIRI: Scan / Manual (akan diaktifkan nanti) ===
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

                      const SizedBox(width: 150),
                      // === SECTION: Data Cards (Full Width untuk sementara) ===
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BAHAN BAKU
                            Expanded(
                              flex: 2,
                              child: SectionCard(
                                title: 'Bahan Baku',
                                count: bbGroups.length,
                                color: Colors.blue,
                                isLoading: loading,

                                summaryBuilder: () {
                                  int totalSak = 0;
                                  double totalBerat = 0.0;

                                  for (final entry in bbGroups.entries) {
                                    for (final item in entry.value) {
                                      totalSak += 1;
                                      totalBerat += (item.berat ?? 0.0);
                                    }
                                  }

                                  return SectionSummary(
                                    totalData: bbGroups.length,
                                    totalSak: totalSak,
                                    totalBerat: totalBerat,
                                  );
                                },

                                child: bbGroups.isEmpty
                                    ? const Center(
                                  child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
                                )
                                    : ListView(
                                  padding: const EdgeInsets.all(8),
                                  children: bbGroups.entries.map((entry) {
                                    final hasPartial = entry.value.any((x) => x.isPartialRow);

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
                                      title: entry.key,
                                      headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                      color: Colors.blue,
                                      tableHeaders: headers,
                                      columnFlexes: columnFlexes,
                                      canDelete: canDelete,
                                      onBulkDelete: _handleBulkDelete,

                                      summaryBuilder: () {
                                        double totalBerat = 0.0;

                                        for (final item in entry.value) {
                                          totalBerat += (item.berat ?? 0.0);
                                        }

                                        return TooltipSummary(
                                          totalBerat: totalBerat,
                                        );
                                      },

                                      detailsBuilder: () {
                                        final currentInputs = vm.inputsOf(widget.noCrusherProduksi);

                                        final dbItems = currentInputs == null
                                            ? <BbItem>[]
                                            : currentInputs.bb.where((x) => bbTitleKey(x) == entry.key);
                                        final tempFull = vm.tempBb.where((x) => bbTitleKey(x) == entry.key);
                                        final tempPart = vm.tempBbPartial.where((x) => bbTitleKey(x) == entry.key);

                                        final items = [
                                          ...tempPart,
                                          ...dbItems,
                                          ...tempFull,
                                        ];

                                        return items.map((item) {
                                          final isTemp = vm.tempBb.contains(item) || vm.tempBbPartial.contains(item);

                                          late final List<String> columns;

                                          if (hasPartial) {
                                            columns = [
                                              item.isPartialRow ? bbPairLabel(item) : '-',
                                              '${item.noSak ?? '-'}',
                                              '${num2(item.berat)} kg',
                                            ];
                                          } else {
                                            columns = [
                                              '${item.noSak ?? '-'}',
                                              '${num2(item.berat)} kg',
                                            ];
                                          }

                                          return TooltipTableRow(
                                            columns: columns,
                                            columnFlexes: columnFlexes,
                                            showDelete: isTemp,
                                            onDelete: isTemp
                                                ? () => vm.deleteTempBbItem(item)
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
                            ),
                            const SizedBox(width: 8),
                            // BONGGOLAN
                            Expanded(
                              flex: 2,
                              child: SectionCard(
                                title: 'Bonggolan',
                                count: bonggolGroups.length,
                                color: Colors.blue,
                                isLoading: loading,

                                summaryBuilder: () {
                                  int totalCount = 0;
                                  double totalBerat = 0.0;

                                  for (final entry in bonggolGroups.entries) {
                                    for (final item in entry.value) {
                                      totalCount += 1;
                                      totalBerat += (item.berat ?? 0.0);
                                    }
                                  }

                                  return SectionSummary(
                                    totalData: bonggolGroups.length,
                                    totalSak: totalCount,
                                    totalBerat: totalBerat,
                                  );
                                },

                                child: bonggolGroups.isEmpty
                                    ? const Center(
                                  child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
                                )
                                    : ListView(
                                  padding: const EdgeInsets.all(8),
                                  children: bonggolGroups.entries.map((entry) {
                                    return GroupTooltipAnchorTile(
                                      title: entry.key,
                                      headerSubtitle: 'Bonggolan',
                                      color: Colors.blue,
                                      tableHeaders: const ['Berat', 'Action'],
                                      columnFlexes: const [2],
                                      canDelete: canDelete,
                                      onBulkDelete: _handleBulkDelete,

                                      summaryBuilder: () {
                                        double totalBerat = 0.0;

                                        for (final item in entry.value) {
                                          totalBerat += (item.berat ?? 0.0);
                                        }

                                        return TooltipSummary(
                                          totalBerat: totalBerat,
                                        );
                                      },

                                      detailsBuilder: () {
                                        final currentInputs = vm.inputsOf(widget.noCrusherProduksi);
                                        final items = [
                                          if (currentInputs != null)
                                            ...currentInputs.bonggolan.where(
                                                  (x) => (x.noBonggolan ?? '-') == entry.key,
                                            ),
                                          ...vm.tempBonggolan.where(
                                                (x) => (x.noBonggolan ?? '-') == entry.key,
                                          ),
                                        ];

                                        return items.map((item) {
                                          final isTemp = vm.tempBonggolan.contains(item);
                                          return TooltipTableRow(
                                            columns: ['${num2(item.berat)} kg'],
                                            columnFlexes: const [2],
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
                            ),

                            const SizedBox(width: 150),

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