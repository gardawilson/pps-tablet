// lib/features/production/broker/view/broker_inputs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/production/broker/view_model/broker_production_input_view_model.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../widgets/inputs_group_popover.dart';
import '../widgets/save_button_with_badge.dart';
import '../model/broker_inputs_model.dart';

import 'package:pps_tablet/features/production/shared/shared.dart';
import '../widgets/lookup_label_dialog.dart';
import '../widgets/lookup_label_partial_dialog.dart';

class BrokerInputsScreen extends StatefulWidget {
  final String noProduksi;

  const BrokerInputsScreen({
    super.key,
    required this.noProduksi,
  });

  @override
  State<BrokerInputsScreen> createState() => _BrokerInputsScreenState();
}

class _BrokerInputsScreenState extends State<BrokerInputsScreen> {
  String _selectedMode = 'full';
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BrokerProductionInputViewModel>();
      final already = vm.inputsOf(widget.noProduksi) != null;
      final loading = vm.isInputsLoading(widget.noProduksi);
      if (!already && !loading) {
        vm.loadInputs(widget.noProduksi);
      }
    });
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

  Future<void> _handleSave(BuildContext context) async {
    final vm = context.read<BrokerProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      _showSnack('Tidak ada data untuk disimpan', backgroundColor: Colors.orange);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Simpan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin menyimpan data berikut?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                vm.getSubmitSummary(),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Data yang sudah disimpan tidak dapat dibatalkan.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Menyimpan data...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await vm.submitTempItems(widget.noProduksi);

    if (mounted) Navigator.pop(context);
    if (!mounted) return;

    if (success) {
      _showSnack('✅ Data berhasil disimpan', backgroundColor: Colors.green);
    } else {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('Gagal Menyimpan'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terjadi kesalahan saat menyimpan data:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    vm.submitError ?? 'Kesalahan tidak diketahui',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleSave(context);
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onCodeReady(BuildContext context, String code) async {
    final vm = context.read<BrokerProductionInputViewModel>();

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
      // MODE FULL: Auto-commit semua item tanpa dialog
      await _handleFullMode(context, vm, res);
    } else if (_selectedMode == 'partial') {
      // MODE PARTIAL: Tampilkan dialog khusus partial dengan radio button
      await _handlePartialMode(context, vm, res);
    } else {
      // MODE SELECT (sebagian pallet): Tampilkan dialog dengan checkbox (default all selected)
      await _handleSelectMode(context, vm, res);
    }
  }

  /// MODE FULL: Langsung commit semua data tanpa dialog
  Future<void> _handleFullMode(
      BuildContext context,
      BrokerProductionInputViewModel vm,
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
      BrokerProductionInputViewModel vm,
      ProductionLabelLookupResult res,
      ) async {
    // ⬇️ PERBAIKAN: Tidak perlu filter karena dialog sudah menampilkan semua
    // Langsung tampilkan dialog
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => LookupLabelPartialDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  /// MODE SELECT: Dialog dengan checkbox (default all selected untuk item baru)
  Future<void> _handleSelectMode(
      BuildContext context,
      BrokerProductionInputViewModel vm,
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
      builder: (_) => LookupLabelDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;

    if (item is BrokerItem) return item.noBroker;
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
    if (item is RejectItem) {
      return (item.noRejectPartial ?? '').trim().isNotEmpty
          ? item.noRejectPartial
          : item.noReject;
    }
    return null;
  }

  static bool _boolish(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y';
  }

  static bool _isPartialOf(dynamic item, Map<String, dynamic> row) {
    if (_boolish(row['isPartial']) || _boolish(row['IsPartial'])) return true;

    try {
      if (item is BbItem && item.isPartialRow == true) return true;
      final dynamic dyn = item;
      final hasIsPartial = (dyn as dynamic?)?.isPartial;
      if (hasIsPartial is bool && hasIsPartial) return true;
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BrokerProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);
        final perm = context.watch<PermissionViewModel>();
        final canDelete = perm.can('stock_opname:delete');

        return Scaffold(
          appBar: AppBar(
            title: Text('Inputs • ${widget.noProduksi}'),
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
              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (err != null) {
                return Center(child: Text('Gagal memuat inputs:\n$err'));
              }
              if (inputs == null) {
                return const Center(child: Text('Tidak ada data inputs.'));
              }

              // ===== MERGE DB + TEMP (termasuk PARTIAL) =====
              final brokerAll   = [...vm.tempBroker.reversed, ...inputs.broker];
              final bbAll       = [
                ...vm.tempBb.reversed,
                ...vm.tempBbPartial.reversed, // ⬅️ tambahkan partial
                ...inputs.bb,
              ];
              final washingAll  = [...vm.tempWashing, ...inputs.washing];
              final crusherAll  = [...vm.tempCrusher, ...inputs.crusher];
              final gilinganAll = [
                ...vm.tempGilingan.reversed,
                ...vm.tempGilinganPartial.reversed, // ⬅️ tambahkan partial
                ...inputs.gilingan,
              ];
              final mixerAll    = [
                ...vm.tempMixer.reversed,
                ...vm.tempMixerPartial.reversed, // ⬅️ tambahkan partial
                ...inputs.mixer,
              ];
              final rejectAll   = [
                ...vm.tempReject.reversed,
                ...vm.tempRejectPartial.reversed, // ⬅️ tambahkan partial
                ...inputs.reject,
              ];

              // ===== GROUPED (key = titleKey yang sudah handle partial) =====
              final brokerGroups   = groupBy(brokerAll,   (BrokerItem e)   => e.noBroker  ?? '-');
              final bbGroups       = groupBy(bbAll,       bbTitleKey);
              final washingGroups  = groupBy(washingAll,  (WashingItem e)  => e.noWashing ?? '-');
              final crusherGroups  = groupBy(crusherAll,  (CrusherItem e)  => e.noCrusher ?? '-');
              final gilinganGroups = groupBy(gilinganAll, gilinganTitleKey);
              final mixerGroups    = groupBy(mixerAll,    mixerTitleKey);
              final rejectGroups   = groupBy(rejectAll,   rejectTitleKey);

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // === SECTION KIRI: Scan / Manual ===
                    SizedBox(
                      width: 380,
                      child: ScanManualCard(
                        title: 'Input via Scan / Manual',
                        modeLabel: 'Pilih Mode',
                        modeItems: const [
                          DropdownMenuItem(value: 'full',    child: Text('FULL PALLET')),
                          DropdownMenuItem(value: 'select',  child: Text('SEBAGIAN PALLET')),
                          DropdownMenuItem(value: 'partial', child: Text('PARTIAL')),
                        ],
                        selectedMode: _selectedMode,
                          manualHint: 'F.XXXXXXXXXX',
                        onModeChanged: (m) => setState(() => _selectedMode = m),
                        onCodeChanged: (code) async {
                          setState(() => _scannedCode = code);
                          if (code != null && code.isNotEmpty) {
                            _showSnack('Kode ter-set: $code');
                            await _onCodeReady(context, code);
                          }
                        },
                        noProduksi: widget.noProduksi,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // === SECTION KANAN: Data Cards ===
                    Expanded(
                      child: Column(
                        children: [
                          // ROW ATAS
                          Expanded(
                            child: Row(
                              children: [
                                // BROKER
                                Expanded(
                                  child: SectionCard(
                                    title: 'Broker',
                                    count: brokerGroups.length,
                                    color: Colors.blue,
                                    child: brokerGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: brokerGroups.entries.map((entry) {
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.blue,
                                          tableHeaders: const ['Sak', 'Berat', 'Action'],
                                          detailsBuilder: () {
                                            final currentInputs = vm.inputsOf(widget.noProduksi);
                                            final items = [
                                              ...vm.tempBroker.where((x) => (x.noBroker ?? '-') == entry.key),
                                              if (currentInputs != null)
                                                ...currentInputs.broker.where((x) => (x.noBroker ?? '-') == entry.key),
                                            ];
                                            return items.map((item) {
                                              final isTemp = vm.tempBroker.contains(item);
                                              return TooltipTableRow(
                                                columns: [
                                                  item.noSak?.toString() ?? '-',
                                                  '${num2(item.berat)} kg',
                                                ],
                                                showDelete: isTemp || canDelete,
                                                onDelete: isTemp ? () => vm.deleteTempBrokerItem(item) : null,
                                                isHighlighted: isTemp,
                                              );
                                            }).toList();
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // BAHAN BAKU
                                Expanded(
                                  child: SectionCard(
                                    title: 'Bahan Baku',
                                    count: bbGroups.length,
                                    color: Colors.green,
                                    child: bbGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: bbGroups.entries.map((entry) {
                                        // Cek apakah group ini mengandung partial
                                        final hasPartial = entry.value.any((x) => x.isPartialRow);

                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.green,
                                          // ⬇️ Ubah header sesuai kondisi
                                          tableHeaders: hasPartial
                                              ? const ['Label', 'Sak', 'Berat', 'Action']
                                              : const ['Sak', 'Berat', 'Action'],
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

                                              // ⬇️ Ubah columns sesuai kondisi
                                              final columns = item.isPartialRow
                                                  ? [
                                                bbPairLabel(item), // LabelCode
                                                '${item.noSak ?? '-'}', // Sak
                                                '${num2(item.berat)} kg', // Berat
                                              ]
                                                  : [
                                                '${item.noSak ?? '-'}', // Detail
                                                '${num2(item.berat)} kg', // Berat
                                              ];

                                              return TooltipTableRow(
                                                columns: columns,
                                                showDelete: isTemp || canDelete,
                                                onDelete: isTemp ? () => vm.deleteTempBbItem(item) : null,
                                                isHighlighted: isTemp,
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
                                    color: Colors.cyan,
                                    child: washingGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: washingGroups.entries.map((entry) {
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.cyan,
                                          tableHeaders: const ['Sak', 'Berat', 'Action'],
                                          detailsBuilder: () {
                                            final currentInputs = vm.inputsOf(widget.noProduksi);
                                            final items = [
                                              if (currentInputs != null)
                                                ...currentInputs.washing.where((x) => (x.noWashing ?? '-') == entry.key),
                                              ...vm.tempWashing.where((x) => (x.noWashing ?? '-') == entry.key),
                                            ];
                                            return items.map((item) {
                                              final isTemp = vm.tempWashing.contains(item);
                                              return TooltipTableRow(
                                                columns: [
                                                  item.noSak?.toString() ?? '-',
                                                  '${num2(item.berat)} kg',
                                                ],
                                                showDelete: isTemp || canDelete,
                                                onDelete: isTemp ? () => vm.deleteTempWashingItem(item) : null,
                                                isHighlighted: isTemp,
                                              );
                                            }).toList();
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // CRUSHER
                                Expanded(
                                  child: SectionCard(
                                    title: 'Crusher',
                                    count: crusherGroups.length,
                                    color: Colors.orange,
                                    child: crusherGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: crusherGroups.entries.map((entry) {
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.orange,
                                          tableHeaders: const ['Berat', 'Action'],
                                          detailsBuilder: () {
                                            final currentInputs = vm.inputsOf(widget.noProduksi);
                                            final items = [
                                              if (currentInputs != null)
                                                ...currentInputs.crusher.where((x) => (x.noCrusher ?? '-') == entry.key),
                                              ...vm.tempCrusher.where((x) => (x.noCrusher ?? '-') == entry.key),
                                            ];
                                            return items.map((item) {
                                              final isTemp = vm.tempCrusher.contains(item);
                                              return TooltipTableRow(
                                                columns: ['${num2(item.berat)} kg'],
                                                showDelete: isTemp || canDelete,
                                                onDelete: isTemp ? () => vm.deleteTempCrusherItem(item) : null,
                                                isHighlighted: isTemp,
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

                          const SizedBox(height: 12),

                          // ROW BAWAH
                          Expanded(
                            child: Row(
                              children: [
                                // GILINGAN
                                Expanded(
                                  child: SectionCard(
                                    title: 'Gilingan',
                                    count: gilinganGroups.length,
                                    color: Colors.green,
                                    child: gilinganGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: gilinganGroups.entries.map((entry) {
                                        // ⬇️ Cek apakah group ini mengandung partial
                                        final hasPartial = entry.value.any((x) => x.isPartialRow);

                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.green,
                                          // ⬇️ Header dinamis seperti BB
                                          tableHeaders: hasPartial
                                              ? const ['Label', 'Berat', 'Action']
                                              : const ['Berat', 'Action'],
                                          detailsBuilder: () {
                                            final currentInputs = vm.inputsOf(widget.noProduksi);

                                            final dbItems = currentInputs == null
                                                ? <GilinganItem>[]
                                                : currentInputs.gilingan.where((x) => gilinganTitleKey(x) == entry.key);
                                            final tempFull = vm.tempGilingan.where((x) => gilinganTitleKey(x) == entry.key);
                                            final tempPart = vm.tempGilinganPartial.where((x) => gilinganTitleKey(x) == entry.key);

                                            final items = [
                                              ...tempPart,
                                              ...dbItems,
                                              ...tempFull,
                                            ];

                                            return items.map((item) {
                                              final isTemp = vm.tempGilingan.contains(item) || vm.tempGilinganPartial.contains(item);

                                              // ⬇️ Kolom dinamis: partial vs non-partial
                                              final columns = item.isPartialRow
                                                  ? <String>[
                                                // Detail/Label (kode gilingan)
                                                (item.noGilingan ?? '-'),
                                                // Berat
                                                '${num2(item.berat)} kg',
                                              ]
                                                  : <String>[
                                                // Hanya Berat untuk non-partial (meniru BB yang menyembunyikan "Detail")
                                                '${num2(item.berat)} kg',
                                              ];

                                              return TooltipTableRow(
                                                columns: columns,
                                                // Meniru BB: izinkan hapus saat temp, atau saat canDelete global true
                                                showDelete: isTemp || canDelete,
                                                onDelete: isTemp ? () => vm.deleteTempGilinganItem(item) : null,
                                                isHighlighted: isTemp,
                                              );
                                            }).toList();
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // MIXER
                                Expanded(
                                  child: SectionCard(
                                    title: 'Mixer',
                                    count: mixerGroups.length,
                                    color: Colors.teal,
                                    child: mixerGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: mixerGroups.entries.map((entry) {
                                        // Cek apakah group ini mengandung partial
                                        final hasPartial = entry.value.any((x) => x.isPartialRow);

                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.teal,
                                          tableHeaders: hasPartial
                                              ? const ['Label', 'Sak', 'Berat', 'Action']
                                              : const ['Sak', 'Berat', 'Action'],
                                          detailsBuilder: () {
                                            final currentInputs = vm.inputsOf(widget.noProduksi);

                                            // ⬇️ PERBAIKAN: Filter berdasarkan entry.key
                                            final dbItems = currentInputs == null
                                                ? <MixerItem>[]
                                                : currentInputs.mixer.where((x) {
                                              // Untuk item dari DB, cek apakah titleKey-nya sama dengan entry.key
                                              return mixerTitleKey(x) == entry.key;
                                            }).toList();

                                            final tempFull = vm.tempMixer.where((x) => mixerTitleKey(x) == entry.key).toList();
                                            final tempPart = vm.tempMixerPartial.where((x) => mixerTitleKey(x) == entry.key).toList();

                                            // ⬇️ PENTING: Gabungkan semua items
                                            final items = [
                                              ...tempPart,  // Partial di atas
                                              ...dbItems,   // DB di tengah
                                              ...tempFull,  // Temp full di bawah
                                            ];

                                            // ⬇️ DEBUG: Tambahkan print untuk cek
                                            if (items.isEmpty) {
                                              print('[DEBUG-MIXER] Group "${entry.key}" has NO items in detailsBuilder!');
                                              print('[DEBUG-MIXER]   dbItems.length = ${dbItems.length}');
                                              print('[DEBUG-MIXER]   tempFull.length = ${tempFull.length}');
                                              print('[DEBUG-MIXER]   tempPart.length = ${tempPart.length}');
                                            }

                                            return items.map((item) {
                                              final isTemp = vm.tempMixer.contains(item) || vm.tempMixerPartial.contains(item);

                                              // ⬇️ Ubah columns sesuai kondisi
                                              final columns = item.isPartialRow
                                                  ? [
                                                item.noMixer ?? '-',           // LabelCode
                                                '${item.noSak ?? '-'}',   // Sak
                                                '${num2(item.berat)} kg',      // Berat
                                              ]
                                                  : [
                                                '${item.noSak ?? '-'}',   // Sak
                                                '${num2(item.berat)} kg',      // Berat
                                              ];

                                              return TooltipTableRow(
                                                columns: columns,
                                                showDelete: isTemp || canDelete,
                                                onDelete: isTemp ? () => vm.deleteTempMixerItem(item) : null,
                                                isHighlighted: isTemp,
                                              );
                                            }).toList();
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // REJECT
                                Expanded(
                                  child: SectionCard(
                                    title: 'Reject',
                                    count: rejectGroups.length,
                                    color: Colors.red,
                                    child: rejectGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: rejectGroups.entries.map((entry) {
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.red,
                                          tableHeaders: const ['Partial', 'Berat', 'Action'],
                                          detailsBuilder: () {
                                            final currentInputs = vm.inputsOf(widget.noProduksi);

                                            final dbItems = currentInputs == null
                                                ? <RejectItem>[]
                                                : currentInputs.reject.where((x) => rejectTitleKey(x) == entry.key);
                                            final tempFull = vm.tempReject.where((x) => rejectTitleKey(x) == entry.key);
                                            final tempPart = vm.tempRejectPartial.where((x) => rejectTitleKey(x) == entry.key);

                                            final items = [
                                              ...tempPart,
                                              ...dbItems,
                                              ...tempFull,
                                            ];

                                            return items.map((item) {
                                              final isTemp = vm.tempReject.contains(item) || vm.tempRejectPartial.contains(item);
                                              return TooltipTableRow(
                                                columns: [
                                                  'Partial: ${item.noRejectPartial ?? '-'}',
                                                  '${num2(item.berat)} kg',
                                                ],
                                                showDelete: isTemp || canDelete,
                                                onDelete: isTemp ? () => vm.deleteTempRejectItem(item) : null,
                                                isHighlighted: isTemp,
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
        );
      },
    );
  }
}