// lib/features/production/washing/view/washing_production_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/production/washing/view_model/washing_production_input_view_model.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../washing/widgets/washing_input_group_popover.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/widgets/partial_mode_not_supported_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import '../model/washing_inputs_model.dart';

import 'package:pps_tablet/features/production/shared/shared.dart';
import '../widgets/washing_lookup_label_dialog.dart';
import '../widgets/washing_lookup_label_partial_dialog.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';

class WashingProductionInputScreen extends StatefulWidget {
  final String noProduksi;

  final bool? isLocked;
  final DateTime? lastClosedDate;

  const WashingProductionInputScreen({
    super.key,
    required this.noProduksi,
    this.isLocked,
    this.lastClosedDate,
  });

  @override
  State<WashingProductionInputScreen> createState() => _WashingProductionInputScreenState();
}

class _WashingProductionInputScreenState extends State<WashingProductionInputScreen> {
  String _selectedMode = 'full';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<WashingProductionInputViewModel>();
      final already = vm.inputsOf(widget.noProduksi) != null;
      final loading = vm.isInputsLoading(widget.noProduksi);
      if (!already && !loading) {
        vm.loadInputs(widget.noProduksi);
      }
    });
  }

  // Tambahkan di bagian atas file, setelah imports
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


  // ✅ Method untuk handle back button
  Future<bool> _onWillPop() async {
    final vm = context.read<WashingProductionInputViewModel>();

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
          // Tutup dialog dengan hasil false (tidak pop dulu)
          Navigator.of(dialogContext).pop(false);
          // Trigger flow save yang sudah ada
          _handleSave(context);
        },
      ),
    );

    // Jika user pilih "Keluar & Hapus"
    if (shouldPop == true) {
      vm.clearAllTempItems();
      return true;
    }

    // selain itu (Batal / Simpan Dulu) -> jangan keluar
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

  // ✅ Handler untuk bulk delete dari popover
  Future<bool> _handleBulkDelete(List<dynamic> items) async {
    final vm = context.read<WashingProductionInputViewModel>();

    // Call ViewModel deleteItems (1x API call)
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
    final vm = context.read<WashingProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      _showSnack('Tidak ada data untuk disimpan', backgroundColor: Colors.orange);
      return;
    }

    // 🔹 Dialog konfirmasi formal
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ConfirmSaveTempDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
      ),
    );

    if (confirm != true || !mounted) return;

    // Eksekusi submit → skeleton muncul dari state isSubmitting
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
      // retry kalau mau, user tinggal tekan tombol Save lagi
    }
  }

  Future<void> _onCodeReady(BuildContext context, String code) async {
    final vm = context.read<WashingProductionInputViewModel>();

    // ✅ VALIDASI: Cek jika mode partial tidak support untuk washing
    if (_selectedMode == 'partial') {
      final prefix = code.trim().toUpperCase().substring(0, 2);

      if (prefix == 'B.') {
        // ✅ Tampilkan dialog informatif
        await PartialModeNotSupportedDialog.show(
          context: context,
          labelType: 'Washing',
          onOk: () {
            // Optional: Bisa tambahkan aksi setelah user klik OK
          },
        );

        return; // ❌ Stop processing
      }
    }

    // // ✅ Lanjutkan proses lookup jika validasi OK
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

  /// MODE FULL: Langsung commit semua data tanpa dialog
  Future<void> _handleFullMode(
      BuildContext context,
      WashingProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp = labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp ? ' • ${vm.getTemporaryDataSummary(labelCode!)}' : '';
      _showSnack('Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix');
      return;
    }

    // Auto-select semua item baru (non-duplicate)
    vm.clearPicks();
    vm.pickAllNew(widget.noProduksi);

    // Commit langsung tanpa dialog
    final result = vm.commitPickedToTemp(noProduksi: widget.noProduksi);

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
      WashingProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    // Langsung tampilkan dialog
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WashingLookupLabelPartialDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  /// MODE SELECT: Dialog dengan checkbox (default all selected untuk item baru)
  Future<void> _handleSelectMode(
      BuildContext context,
      WashingProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);

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

  static bool _boolish(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WashingProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);
        final perm = context.watch<PermissionViewModel>();
        final locked = widget.isLocked == true;

        final canDeleteByPerm = perm.can('label_washing:delete');
        final canDelete = canDeleteByPerm && !locked;

        // ✅ WRAP dengan WillPopScope untuk intercept back button
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Inputs • ${widget.noProduksi}'),
              // ✅ Override back button untuk konsistensi
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

                // ===== MERGE DB + TEMP (termasuk PARTIAL) =====
                final bbAll = loading ? <BbItem>[] : [
                  ...vm.tempBb.reversed,
                  ...vm.tempBbPartial.reversed,
                  ...?inputs?.bb,
                ];
                final washingAll = loading ? <WashingItem>[] : [
                  ...vm.tempWashing,
                  ...?inputs?.washing
                ];
                final gilinganAll = loading ? <GilinganItem>[] : [
                  ...vm.tempGilingan.reversed,
                  ...vm.tempGilinganPartial.reversed,
                  ...?inputs?.gilingan,
                ];

                // ===== GROUPED (key = titleKey yang sudah handle partial) =====
                final bbGroups = groupBy(bbAll, bbTitleKey);
                final washingGroups = groupBy(washingAll, (WashingItem e) => e.noWashing ?? '-');
                final gilinganGroups = groupBy(gilinganAll, gilinganTitleKey);

                final locked = widget.isLocked == true;
                final closed = widget.lastClosedDate; // boleh null

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

                      // === SECTION KANAN: Data Cards ===
                      Expanded(
                        child: Column(
                          children: [
                            // ROW TUNGGAL (3 kolom: BB, Washing, Gilingan)
                            Expanded(
                              child: Row(
                                children: [
                                  // BAHAN BAKU
                                  Expanded(
                                    child: SectionCard(
                                      title: 'Bahan Baku',
                                      count: bbGroups.length,
                                      color: Colors.blue,
                                      isLoading: loading,

                                      // Tambahkan summaryBuilder
                                      summaryBuilder: () {
                                        int totalSak = 0;
                                        double totalBerat = 0.0;

                                        // Loop semua groups
                                        for (final entry in bbGroups.entries) {
                                          for (final item in entry.value) {
                                            totalSak += 1; // Count item (atau item.jumlahSak jika ada)
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
                                              final currentInputs = vm.inputsOf(widget.noProduksi);

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
                                                  onDelete: () {
                                                    if (isTemp) {
                                                      vm.deleteTempBbItem(item);
                                                    }
                                                  },
                                                  isTempRow: isTemp,
                                                  isHighlighted: isTemp,
                                                  isDisabled: !isTemp && !canDelete,
                                                  itemData: item, // ✅ PASS item asli
                                                );
                                              }).toList();
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // WASHING
                                  Expanded(
                                    child: SectionCard(
                                      title: 'Washing',
                                      count: washingGroups.length,
                                      color: Colors.blue,
                                      isLoading: loading,

                                      summaryBuilder: () {
                                        int totalSak = 0;
                                        double totalBerat = 0.0;

                                        // Loop semua groups
                                        for (final entry in washingGroups.entries) {
                                          for (final item in entry.value) {
                                            totalSak += 1; // Count item (atau item.jumlahSak jika ada)
                                            totalBerat += (item.berat ?? 0.0);
                                          }
                                        }

                                        return SectionSummary(
                                          totalData: washingGroups.length,
                                          totalSak: totalSak,
                                          totalBerat: totalBerat,
                                        );
                                      },

                                      child: washingGroups.isEmpty
                                          ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                          : ListView(
                                        padding: const EdgeInsets.all(8),
                                        children: washingGroups.entries.map((entry) {
                                          late final List<int> columnFlexes = [1, 2];
                                          return GroupTooltipAnchorTile(
                                            title: entry.key,
                                            headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                            color: Colors.blue,
                                            tableHeaders: const ['Sak', 'Berat', 'Action'],
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
                                              final currentInputs = vm.inputsOf(widget.noProduksi);
                                              final items = [
                                                if (currentInputs != null) ...currentInputs.washing.where((x) => (x.noWashing ?? '-') == entry.key),
                                                ...vm.tempWashing.where((x) => (x.noWashing ?? '-') == entry.key),
                                              ];
                                              return items.map((item) {
                                                final isTemp = vm.tempWashing.contains(item);
                                                return TooltipTableRow(
                                                  columns: [
                                                    item.noSak?.toString() ?? '-',
                                                    '${num2(item.berat)} kg',
                                                  ],
                                                  columnFlexes: [1, 2],
                                                  showDelete: isTemp,
                                                  onDelete: () {
                                                    if (isTemp) {
                                                      vm.deleteTempWashingItem(item);
                                                    }
                                                  },
                                                  isTempRow: isTemp,
                                                  isHighlighted: isTemp,
                                                  isDisabled: !isTemp && !canDelete,
                                                  itemData: item, // ✅ TETAP pass untuk checkbox mode
                                                );
                                              }).toList();
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // GILINGAN
                                  Expanded(
                                    child: SectionCard(
                                      title: 'Gilingan',
                                      count: gilinganGroups.length,
                                      color: Colors.blue,
                                      isLoading: loading,

                                      summaryBuilder: () {
                                        int totalSak = 0;
                                        double totalBerat = 0.0;

                                        // Loop semua groups
                                        for (final entry in gilinganGroups.entries) {
                                          for (final item in entry.value) {
                                            totalSak += 1; // Count item (atau item.jumlahSak jika ada)
                                            totalBerat += (item.berat ?? 0.0);
                                          }
                                        }

                                        return SectionSummary(
                                          totalData: gilinganGroups.length,
                                          totalSak: totalSak,
                                          totalBerat: totalBerat,
                                        );
                                      },

                                      child: gilinganGroups.isEmpty
                                          ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                          : ListView(
                                        padding: const EdgeInsets.all(8),
                                        children: gilinganGroups.entries.map((entry) {
                                          final hasPartial = entry.value.any((x) => x.isPartialRow);

                                          return GroupTooltipAnchorTile(
                                            title: entry.key,
                                            headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                            color: Colors.blue,
                                            tableHeaders: hasPartial ? const ['Label', 'Berat', 'Action'] : const ['Berat', 'Action'],
                                            canDelete: canDelete,
                                            onBulkDelete: _handleBulkDelete,
                                            detailsBuilder: () {
                                              final currentInputs = vm.inputsOf(widget.noProduksi);

                                              final dbItems = currentInputs == null ? <GilinganItem>[] : currentInputs.gilingan.where((x) => gilinganTitleKey(x) == entry.key);
                                              final tempFull = vm.tempGilingan.where((x) => gilinganTitleKey(x) == entry.key);
                                              final tempPart = vm.tempGilinganPartial.where((x) => gilinganTitleKey(x) == entry.key);

                                              final items = [
                                                ...tempPart,
                                                ...dbItems,
                                                ...tempFull,
                                              ];

                                              return items.map((item) {
                                                final isTemp = vm.tempGilingan.contains(item) || vm.tempGilinganPartial.contains(item);

                                                final columns = item.isPartialRow
                                                    ? <String>[
                                                  (item.noGilingan ?? '-'),
                                                  '${num2(item.berat)} kg',
                                                ]
                                                    : <String>[
                                                  '${num2(item.berat)} kg',
                                                ];

                                                return TooltipTableRow(
                                                  columns: columns,
                                                  showDelete: isTemp,
                                                  onDelete: () {
                                                    if (isTemp) {
                                                      vm.deleteTempGilinganItem(item);
                                                    }
                                                  },
                                                  isTempRow: isTemp,
                                                  isHighlighted: isTemp,
                                                  isDisabled: !isTemp && !canDelete,
                                                  itemData: item, // ✅ PASS item asli
                                                );
                                              }).toList();
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
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
}