import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../production/shared/utils/format.dart'; // sesuaikan path kalau beda
import '../../production/shared/models/production_label_lookup_result.dart';

// ✅ BJ item
import '../../production/shared/models/barang_jadi_item.dart';

// ✅ BJ Jual Input VM
import '../view_model/bj_jual_input_view_model.dart';

enum _Presence { none, temp }

class BJJualLookupLabelDialog extends StatefulWidget {
  final String noBJJual;
  final String selectedMode;
  final Set<int>? preDisabledIndices;

  const BJJualLookupLabelDialog({
    super.key,
    required this.noBJJual,
    required this.selectedMode,
    this.preDisabledIndices,
  });

  @override
  State<BJJualLookupLabelDialog> createState() => _BJJualLookupLabelDialogState();
}

class _BJJualLookupLabelDialogState extends State<BJJualLookupLabelDialog> {
  final Set<int> _localPickedIndices = <int>{};
  final Set<int> _disabledAtOpen = <int>{};
  final Map<int, int> _editedPcs = {}; // idx -> pcs edited

  bool _inputsReady = false;
  bool _didAutoSelect = false;

  @override
  void initState() {
    super.initState();
    _editedPcs.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<BJJualInputViewModel>();

      // ✅ refresh lookup based on first item label (same pattern)
      final lastLookup = vm.lastLookup;
      if (lastLookup != null && lastLookup.typedItems.isNotEmpty) {
        final firstItem = lastLookup.typedItems.first;
        final labelCode = _labelCodeOf(firstItem);
        if (labelCode != '-') {
          await vm.lookupLabel(labelCode, force: true);
        }
      }

      if (vm.inputsOf(widget.noBJJual) == null) {
        await vm.loadInputs(widget.noBJJual);
      }
      _inputsReady = true;

      _precomputeDisabledRows();
      _maybeAutoSelectFirstTime();

      if (mounted) setState(() {});
    });
  }

  void _precomputeDisabledRows() {
    final vm = context.read<BJJualInputViewModel>();
    final result = vm.lastLookup;
    if (result == null) return;

    _disabledAtOpen.clear();

    // allow injected disables
    if (widget.preDisabledIndices != null) {
      _disabledAtOpen.addAll(widget.preDisabledIndices!);
    }

    for (int i = 0; i < result.data.length; i++) {
      final row = result.data[i];
      if (vm.willBeDuplicate(row, widget.noBJJual)) {
        _disabledAtOpen.add(i);
      }
    }

    _localPickedIndices.removeWhere(_disabledAtOpen.contains);
  }

  bool _isDisabled(int index) => _disabledAtOpen.contains(index);

  void _maybeAutoSelectFirstTime() {
    if (_didAutoSelect) return;
    final vm = context.read<BJJualInputViewModel>();
    final result = vm.lastLookup;
    if (result == null || result.typedItems.isEmpty) return;

    final labelCode = _labelCodeOf(result.typedItems.first);

    // jika label ini sudah punya temp data, jangan auto select
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

  void _toggleRow(BJJualInputViewModel vm, int index, Map<String, dynamic> row) {
    if (_isDisabled(index)) return;
    setState(() {
      if (_localPickedIndices.contains(index)) {
        _localPickedIndices.remove(index);
      } else {
        _localPickedIndices.add(index);
      }
    });
  }

  void _selectAllNew(BJJualInputViewModel vm, ProductionLabelLookupResult result) {
    setState(() {
      _localPickedIndices.clear();
      for (int i = 0; i < result.data.length; i++) {
        if (!_isDisabled(i)) _localPickedIndices.add(i);
      }
    });
  }

  void _commitSelection(BJJualInputViewModel vm, ProductionLabelLookupResult result) {
    if (_localPickedIndices.isEmpty) return;

    vm.clearPicks();

    // penting: kita modif row (pcs/isPartial) sementara, lalu commit, lalu restore (optional)
    for (final idx in _localPickedIndices) {
      if (idx >= result.data.length) continue;

      final row = result.data[idx];

      // ✅ Apply edited PCS
      if (_editedPcs.containsKey(idx)) {
        row['pcs'] = _editedPcs[idx];
        row['Pcs'] = _editedPcs[idx];

        // ✅ ensure treated as partial when edited (kalau kamu pakai pola ini)
        row['isPartial'] = true;
        row['IsPartial'] = true;
      }

      if (!vm.isPicked(row)) vm.togglePick(row);
    }

    final r = vm.commitPickedToTemp(noBJJual: widget.noBJJual);

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

  _Presence _presenceForRow(
      BJJualInputViewModel vm,
      Map<String, dynamic> row,
      ProductionLabelLookupResult ctx,
      ) {
    final sk = ctx.simpleKey(row);
    if (vm.isInTempKeys(sk)) return _Presence.temp;
    return _Presence.none;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BJJualInputViewModel>(
      builder: (context, vm, _) {
        final result = vm.lastLookup;
        if (result == null) {
          return const Dialog(
            child: SizedBox(
              height: 120,
              child: Center(child: Text('Tidak ada hasil lookup')),
            ),
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

        // untuk BJ Jual, label yang kamu lookup biasanya Barang Jadi
        final namaJenis = sample == null ? prefixType.displayName : 'Barang Jadi';

        int newCount = 0;
        for (int i = 0; i < result.data.length; i++) {
          if (!_disabledAtOpen.contains(i)) newCount++;
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.indigo.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shopping_cart_outlined,
                            size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labelCode,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              namaJenis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${typedItems.length} item',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // COLUMN HEADERS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 40),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'PCS',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'BERAT (KG)',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 220,
                        child: Text(
                          'STATUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // LIST
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: typedItems.length,
                    itemBuilder: (_, idx) {
                      final item = typedItems[idx];
                      final rawRow = result.data[idx];

                      final presence = _presenceForRow(vm, rawRow, result);
                      final isDuplicate = _isDisabled(idx);
                      final picked = _localPickedIndices.contains(idx);

                      if (isDuplicate && picked) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _localPickedIndices.remove(idx));
                        });
                      }

                      final originalPcs = _pcsOf(item);
                      final displayPcs = _editedPcs[idx] ?? originalPcs;
                      final pcsTxt = displayPcs?.toString() ?? '-';

                      final berat = _beratOf(item);
                      final beratTxt = berat == null ? '-' : num2(berat);

                      final isPartial = _isPartialOf(item, rawRow);
                      final isPcsEdited = _editedPcs.containsKey(idx);

                      String? statusText;
                      Color? statusColor;
                      if (presence == _Presence.temp) {
                        statusText = 'Sudah Input';
                        statusColor = Colors.orange;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IgnorePointer(
                          ignoring: isDuplicate,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isDuplicate ? 0.4 : 1.0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isDuplicate ? null : () => _toggleRow(vm, idx, rawRow),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: picked && !isDuplicate
                                        ? Colors.indigo.shade50
                                        : Colors.white,
                                    border: Border.all(
                                      color: picked && !isDuplicate
                                          ? Colors.indigo.shade300
                                          : Colors.grey.shade200,
                                      width: picked && !isDuplicate ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: picked && !isDuplicate
                                        ? [
                                      BoxShadow(
                                        color: Colors.indigo.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Checkbox
                                      Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Checkbox(
                                          value: picked && !isDuplicate,
                                          onChanged: isDuplicate ? null : (_) => _toggleRow(vm, idx, rawRow),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),

                                      // PCS
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            if (isPartial) ...[
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(
                                                  Icons.content_cut,
                                                  size: 14,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Expanded(
                                              child: Text(
                                                '$pcsTxt pcs',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: isDuplicate
                                                      ? Colors.grey.shade400
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // BERAT
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isPcsEdited
                                                    ? [Colors.amber.shade300, Colors.amber.shade400]
                                                    : statusText != null
                                                    ? [
                                                  statusColor!.withOpacity(0.2),
                                                  statusColor.withOpacity(0.3)
                                                ]
                                                    : [Colors.green.shade100, Colors.green.shade200],
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$beratTxt kg',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isPcsEdited
                                                    ? Colors.amber.shade900
                                                    : statusText != null
                                                    ? statusColor
                                                    : Colors.green.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // STATUS + BUTTONS
                                      SizedBox(
                                        width: 220,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            // Edit PCS (hanya partial)
                                            if (isPartial && !isDuplicate)
                                              SizedBox(
                                                height: 32,
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    side: BorderSide(color: Colors.amber.shade600, width: 1.5),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  icon: Icon(Icons.edit_outlined,
                                                      size: 14, color: Colors.amber.shade700),
                                                  label: Text(
                                                    'Edit Pcs',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.amber.shade700,
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    if (originalPcs != null) {
                                                      final newPcs = await _showPcsInputDialog(
                                                        context,
                                                        maxPcs: originalPcs,
                                                        currentPcs: _editedPcs[idx],
                                                      );
                                                      if (newPcs != null && mounted) {
                                                        setState(() => _editedPcs[idx] = newPcs);
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),

                                            if (isPartial && !isDuplicate) const SizedBox(width: 8),

                                            if (isPartial) _badge('PARTIAL', Colors.amber.shade700),

                                            if (statusText != null)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: _badge(statusText!, statusColor!),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // FOOTER
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _localPickedIndices.isNotEmpty
                            ? () => setState(_localPickedIndices.clear)
                            : null,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Bersihkan'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),

                      if (newCount > 0)
                        OutlinedButton.icon(
                          onPressed: () => _selectAllNew(vm, result),
                          icon: const Icon(Icons.done_all, size: 18),
                          label: Text('Pilih Semua ($newCount)'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.indigo.shade300),
                            foregroundColor: Colors.indigo.shade700,
                          ),
                        ),

                      const Spacer(),

                      if (_localPickedIndices.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_localPickedIndices.length} terpilih',
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      FilledButton.icon(
                        onPressed: _localPickedIndices.isEmpty
                            ? null
                            : () => _commitSelection(vm, result),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(
                          _localPickedIndices.isEmpty
                              ? 'Pilih Item'
                              : 'Tambahkan (${_localPickedIndices.length})',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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

  // ===== Small UI helper =====
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ===== Helpers (BJ) =====
  static String _labelCodeOf(dynamic item) {
    // ✅ Barang Jadi: partial code preferred
    if (item is BarangJadiItem) {
      final partial = (item.noBJPartial ?? '').trim();
      if (partial.isNotEmpty) return partial;
      return item.noBJ ?? '-';
    }

    // fallback: kalau ternyata typedItems masih Map/dynamic
    try {
      final dyn = item as dynamic;
      final p = (dyn.noBJPartial ?? '').toString().trim();
      if (p.isNotEmpty) return p;
      final b = (dyn.noBJ ?? '').toString().trim();
      return b.isNotEmpty ? b : '-';
    } catch (_) {}

    return '-';
  }

  static int? _pcsOf(dynamic item) {
    if (item is BarangJadiItem) return item.pcs;
    try {
      final dyn = item as dynamic;
      final v = dyn.pcs;
      if (v is int) return v;
      if (v is num) return v.toInt();
    } catch (_) {}
    return null;
  }

  static double? _beratOf(dynamic item) {
    if (item is BarangJadiItem) return item.berat;
    try {
      final dyn = item as dynamic;
      final v = dyn.berat;
      if (v is double) return v;
      if (v is num) return v.toDouble();
    } catch (_) {}
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

    if (item is BarangJadiItem) return item.isPartialRow == true;

    try {
      final dyn = item as dynamic;
      final v = dyn.isPartial;
      if (v is bool && v) return true;
      final p = (dyn.noBJPartial ?? '').toString().trim();
      if (p.isNotEmpty) return true;
    } catch (_) {}
    return false;
  }

  Future<int?> _showPcsInputDialog(
      BuildContext context, {
        required int maxPcs,
        int? currentPcs,
      }) async {
    final controller = TextEditingController(
      text: currentPcs?.toString() ?? '',
    );

    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Pcs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Maksimal: $maxPcs pcs'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Pcs',
                border: OutlineInputBorder(),
                suffixText: 'pcs',
              ),
              onSubmitted: (_) {
                final val = int.tryParse(controller.text.trim());
                if (val != null && val > 0 && val <= maxPcs) {
                  Navigator.of(ctx).pop(val);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0 && val <= maxPcs) {
                Navigator.of(ctx).pop(val);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Pcs harus antara 1 - $maxPcs'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
