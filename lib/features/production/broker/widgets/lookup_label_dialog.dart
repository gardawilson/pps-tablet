import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/utils/format.dart';
import '../view_model/broker_production_input_view_model.dart';
import '../model/broker_inputs_model.dart';
import '../../shared/models/production_label_lookup_result.dart';

/// Top-level enum (perlu di luar class)
enum _Presence { none, temp }

class LookupLabelDialog extends StatefulWidget {
  final String noProduksi;
  final String selectedMode;
  final Set<int>? preDisabledIndices;

  const LookupLabelDialog({
    super.key,
    required this.noProduksi,
    required this.selectedMode,
    this.preDisabledIndices,
  });

  @override
  State<LookupLabelDialog> createState() => _LookupLabelDialogState();
}

class _LookupLabelDialogState extends State<LookupLabelDialog> {
  // Pilihan lokal (berbasis index list saat ini)
  final Set<int> _localPickedIndices = <int>{};

  // Cache index disabled sejak dialog dibuka (hindari flicker)
  final Set<int> _disabledAtOpen = <int>{};

  // State baru untuk tracking berat yang diedit
  final Map<int, double> _editedWeights = {}; // index -> berat baru
  final Set<int> _showWeightEdit = {}; // index yang sedang show edit

  bool _inputsReady = false;
  bool _didAutoSelect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<BrokerProductionInputViewModel>();

      if (vm.inputsOf(widget.noProduksi) == null) {
        await vm.loadInputs(widget.noProduksi);
      }
      _inputsReady = true;

      _precomputeDisabledRows();
      _maybeAutoSelectFirstTime();

      if (mounted) setState(() {});
    });
  }

  void _precomputeDisabledRows() {
    final vm = context.read<BrokerProductionInputViewModel>();
    final result = vm.lastLookup;
    if (result == null) return;

    _disabledAtOpen.clear();
    for (int i = 0; i < result.data.length; i++) {
      final row = result.data[i];
      if (vm.willBeDuplicate(row, widget.noProduksi)) {
        _disabledAtOpen.add(i);
      }
    }
    _localPickedIndices.removeWhere(_disabledAtOpen.contains);
  }

  bool _isDisabled(int index) => _disabledAtOpen.contains(index);

  void _maybeAutoSelectFirstTime() {
    if (_didAutoSelect) return;
    final vm = context.read<BrokerProductionInputViewModel>();
    final result = vm.lastLookup;
    if (result == null || result.typedItems.isEmpty) return;

    final labelCode = _labelCodeOf(result.typedItems.first);
    final tempData = vm.getTemporaryDataForLabel(labelCode);
    final hasTempForLabel = tempData != null && !tempData.isEmpty;
    if (hasTempForLabel) return;

    _localPickedIndices.clear();
    for (int i = 0; i < result.data.length; i++) {
      if (!_disabledAtOpen.contains(i)) {
        _localPickedIndices.add(i);
      }
    }
    _didAutoSelect = true;
  }

  void _toggleRow(BrokerProductionInputViewModel vm, int index, Map<String, dynamic> row) {
    if (_isDisabled(index)) return;
    setState(() {
      if (_localPickedIndices.contains(index)) {
        _localPickedIndices.remove(index);
      } else {
        _localPickedIndices.add(index);
      }
    });
  }

  void _selectAllNew(BrokerProductionInputViewModel vm, ProductionLabelLookupResult result) {
    setState(() {
      _localPickedIndices.clear();
      for (int i = 0; i < result.data.length; i++) {
        if (!_isDisabled(i)) {
          _localPickedIndices.add(i);
        }
      }
    });
  }

  void _commitSelection(BrokerProductionInputViewModel vm, ProductionLabelLookupResult result) {
    if (_localPickedIndices.isEmpty) return;

    vm.clearPicks();
    for (final i in _localPickedIndices) {
      if (i < result.data.length) {
        final row = result.data[i];

        // ⬇️ PENTING: Update berat di row jika ada perubahan
        if (_editedWeights.containsKey(i)) {
          row['berat'] = _editedWeights[i];
          row['Berat'] = _editedWeights[i]; // Backup case sensitivity
        }

        if (!vm.isPicked(row)) vm.togglePick(row);
      }
    }

    final r = vm.commitPickedToTemp(noProduksi: widget.noProduksi);
    Navigator.pop(context);

    final msg = r.added > 0
        ? 'Ditambahkan ${r.added} item${r.skipped > 0 ? ' • Duplikat terlewati ${r.skipped}' : ''}'
        : 'Tidak ada item baru ditambahkan';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: r.added > 0 ? Colors.green : Colors.orange,
      ),
    );
  }

  /// Check presence: menggunakan method simpleKey dari model
  _Presence _presenceForRow(
      BrokerProductionInputViewModel vm,
      Map<String, dynamic> row,
      ProductionLabelLookupResult ctx,
      String noProduksi,
      ) {
    final sk = ctx.simpleKey(row); // ← dari model, clean!

    // Cek di TEMP (hanya cek TEMP sesuai requirement)
    if (vm.isInTempKeys(sk)) {
      return _Presence.temp;
    }

    return _Presence.none;
  }

  // Widget untuk editor berat
  Widget _buildWeightEditor(int idx, double? currentWeight, bool isDuplicate) {
    final controller = TextEditingController(
      text: currentWeight?.toString() ?? '',
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          suffixText: 'kg',
          suffixStyle: const TextStyle(fontSize: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.amber.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.amber.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
        ),
        onChanged: (value) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            setState(() {
              _editedWeights[idx] = parsed;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BrokerProductionInputViewModel>(
      builder: (context, vm, _) {
        final result = vm.lastLookup;
        if (result == null) {
          return const Dialog(
            child: SizedBox(height: 120, child: Center(child: Text('Tidak ada hasil lookup'))),
          );
        }

        if (!_inputsReady) {
          return const Dialog(
            child: SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final typedItems = result.typedItems;
        final prefixType = result.prefixType;

        final dynamic sample = typedItems.isNotEmpty ? typedItems.first : null;
        final labelCode = sample == null ? '-' : _labelCodeOf(sample);
        final namaJenis = sample == null ? prefixType.displayName : (_namaJenisOf(sample) ?? '-');

        // Hitung sekali di luar itemBuilder
        int newCount = 0;
        for (int i = 0; i < result.data.length; i++) {
          if (!_disabledAtOpen.contains(i)) newCount++;
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER (clean)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(labelCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            Text(
                              namaJenis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Chip(label: Text('${typedItems.length} item'), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ),

                // COLUMN HEADERS (tanpa IDX)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: const [
                      SizedBox(width: 40), // checkbox
                      Expanded(flex: 2, child: Text('SAK', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 2, child: Text('BERAT (KG)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700))),
                      SizedBox(width: 8),
                      SizedBox(width: 200), // ruang badge + button
                    ],
                  ),
                ),

                // LIST
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: typedItems.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                    itemBuilder: (_, idx) {
                      final item = typedItems[idx];
                      final rawRow = result.data[idx];

                      final presence = _presenceForRow(vm, rawRow, result, widget.noProduksi);
                      final isDuplicate = _isDisabled(idx); // pakai precompute
                      final picked = _localPickedIndices.contains(idx);

                      if (isDuplicate && picked) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _localPickedIndices.remove(idx));
                        });
                      }

                      final sak = _sakOf(item);
                      final originalBerat = _beratOf(item);

                      // Gunakan berat yang diedit jika ada, otherwise gunakan original
                      final displayBerat = _editedWeights[idx] ?? originalBerat;
                      final beratTxt = displayBerat == null ? '-' : num2(displayBerat);

                      // ==== PARTIAL DETECTION (tanpa sisa) ====
                      final isPartial = _isPartialOf(item, rawRow);
                      final isEditingWeight = _showWeightEdit.contains(idx);

                      String? statusText;
                      Color? statusColor;
                      switch (presence) {
                        case _Presence.temp:
                          statusText = 'Telah input (TEMP)';
                          statusColor = Colors.orange;
                          break;
                        case _Presence.none:
                          statusText = null;
                          statusColor = null;
                          break;
                      }

                      final hasStatusBadge = presence != _Presence.none;
                      final pillBg = hasStatusBadge ? statusColor!.withOpacity(0.12) : Colors.green.withOpacity(0.12);
                      final pillBorder = hasStatusBadge ? statusColor!.withOpacity(0.25) : Colors.green.withOpacity(0.25);
                      final pillText = hasStatusBadge ? statusColor!.withOpacity(0.95) : null;

                      // Badge PARTIAL (tanpa sisa)
                      final partialBadge = isPartial
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.amber.withOpacity(0.30)),
                        ),
                        child: const Text(
                          'PARTIAL',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      )
                          : const SizedBox.shrink();

                      final statusBadge = (statusText != null)
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor!.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: statusColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      )
                          : const SizedBox(width: 130);

                      final rowChild = Container(
                        // (opsional) garis indikator partial di kiri baris
                        decoration: isPartial
                            ? BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.amber.withOpacity(0.7), width: 3),
                          ),
                        )
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Checkbox
                            SizedBox(
                              width: 40,
                              child: AbsorbPointer(
                                absorbing: isDuplicate,
                                child: Checkbox(
                                  value: picked && !isDuplicate,
                                  onChanged: isDuplicate ? null : (_) => _toggleRow(vm, idx, rawRow),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),

                            // SAK
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  if (isPartial) ...[
                                    const Icon(Icons.content_cut, size: 14, color: Colors.amber),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      sak?.toString() ?? '-',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDuplicate ? Colors.grey : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // BERAT - Dengan Edit untuk Partial
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: isPartial && isEditingWeight
                                    ? _buildWeightEditor(idx, displayBerat, isDuplicate)
                                    : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: pillBg,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: pillBorder),
                                  ),
                                  child: Text(
                                    '$beratTxt kg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: pillText,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // BADGES & EDIT BUTTON
                            SizedBox(
                              width: 200, // diperlebar untuk tombol edit
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Tombol Edit Berat (hanya untuk partial)
                                  if (isPartial && !isDuplicate) ...[
                                    if (!isEditingWeight)
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          setState(() {
                                            _showWeightEdit.add(idx);
                                          });
                                        },
                                        tooltip: 'Ubah Berat',
                                        visualDensity: VisualDensity.compact,
                                      )
                                    else
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check, size: 16, color: Colors.green),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setState(() {
                                                _showWeightEdit.remove(idx);
                                              });
                                            },
                                            tooltip: 'Simpan',
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setState(() {
                                                _editedWeights.remove(idx);
                                                _showWeightEdit.remove(idx);
                                              });
                                            },
                                            tooltip: 'Batal',
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    const SizedBox(width: 8),
                                  ],

                                  // Badge Partial
                                  if (isPartial) partialBadge,

                                  // Status Badge
                                  statusBadge,
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      return IgnorePointer(
                        ignoring: isDuplicate,
                        child: Opacity(
                          opacity: isDuplicate ? 0.55 : 1.0,
                          child: InkWell(
                            onTap: isDuplicate || isEditingWeight ? null : () => _toggleRow(vm, idx, rawRow),
                            child: rowChild,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // FOOTER
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _localPickedIndices.isNotEmpty ? () => setState(_localPickedIndices.clear) : null,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Bersihkan'),
                      ),
                      const SizedBox(width: 8),
                      if (newCount > 0)
                        OutlinedButton.icon(
                          onPressed: () => _selectAllNew(vm, result),
                          icon: const Icon(Icons.select_all),
                          label: Text('Pilih Semua Baru ($newCount)'),
                        ),
                      const Spacer(),
                      if (_localPickedIndices.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '${_localPickedIndices.length} item dipilih',
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _localPickedIndices.isEmpty ? null : () => _commitSelection(vm, result),
                        icon: const Icon(Icons.check),
                        label: Text(_localPickedIndices.isEmpty ? 'Pilih Item' : 'Pakai (${_localPickedIndices.length})'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Helpers =====
  static String _labelCodeOf(dynamic item) {
    if (item is BrokerItem) return item.noBroker ?? '-';
    if (item is BbItem) {
      final npart = (item.noBBPartial ?? '').trim();
      if (npart.isNotEmpty) return npart;
      return item.noBahanBaku ?? '-';
    }
    if (item is WashingItem) return item.noWashing ?? '-';
    if (item is CrusherItem) return item.noCrusher ?? '-';
    if (item is GilinganItem) return item.noGilingan ?? '-';
    if (item is MixerItem) return item.noMixer ?? '-';
    if (item is RejectItem) return item.noReject ?? '-';
    return '-';
  }

  static String? _namaJenisOf(dynamic item) {
    if (item is BrokerItem) return item.namaJenis;
    if (item is BbItem) return item.namaJenis;
    if (item is WashingItem) return item.namaJenis;
    if (item is CrusherItem) return item.namaJenis;
    if (item is GilinganItem) return item.namaJenis;
    if (item is MixerItem) return item.namaJenis;
    if (item is RejectItem) return item.namaJenis;
    return null;
  }

  static int? _sakOf(dynamic item) {
    if (item is BrokerItem) return item.noSak;
    if (item is BbItem) return item.noSak;
    if (item is WashingItem) return item.noSak;
    if (item is MixerItem) return item.noSak;
    return null;
  }

  static double? _beratOf(dynamic item) {
    if (item is BrokerItem) return item.berat;
    if (item is BbItem) return item.berat;
    if (item is WashingItem) return item.berat;
    if (item is CrusherItem) return item.berat;
    if (item is GilinganItem) return item.berat;
    if (item is MixerItem) return item.berat;
    if (item is RejectItem) return item.berat;
    return null;
  }

  // ===== PARTIAL helper (tanpa sisa) =====
  static bool _boolish(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y';
  }

  static bool _isPartialOf(dynamic item, Map<String, dynamic> row) {
    // dari JSON row (contoh di pertanyaan)
    if (_boolish(row['isPartial']) || _boolish(row['IsPartial'])) return true;

    // fallback dari typed model (kalau ada)
    try {
      if (item is BbItem && item.isPartialRow == true) return true;
      // beberapa model pakai isPartial
      final dynamic dyn = item;
      final hasIsPartial = (dyn as dynamic?)?.isPartial;
      if (hasIsPartial is bool && hasIsPartial) return true;
    } catch (_) {}
    return false;
  }
}