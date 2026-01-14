import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../production/shared/models/barang_jadi_item.dart';
import '../../production/shared/models/production_label_lookup_result.dart';
import '../../production/shared/utils/format.dart';

import '../view_model/bj_jual_input_view_model.dart';

enum _Presence { none, temp }

class BJJualLookupLabelPartialDialog extends StatefulWidget {
  final String noBJJual;
  final String selectedMode;

  const BJJualLookupLabelPartialDialog({
    super.key,
    required this.noBJJual,
    required this.selectedMode,
  });

  @override
  State<BJJualLookupLabelPartialDialog> createState() =>
      _BJJualLookupLabelPartialDialogState();
}

class _BJJualLookupLabelPartialDialogState
    extends State<BJJualLookupLabelPartialDialog> {
  int? _selectedIndex; // index pada list filtered (BJ only)
  int? _editedPcs;
  bool _inputsReady = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = null;
    _editedPcs = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<BJJualInputViewModel>();

      // Refresh lookup based on first item label code
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

      if (mounted) setState(() {});
    });
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

  void _toggleRow(int filteredIdx, Map<String, dynamic> row, bool isDisabled) {
    if (isDisabled) return;

    setState(() {
      if (_selectedIndex == filteredIdx) {
        _selectedIndex = null;
        _editedPcs = null;
      } else {
        _selectedIndex = filteredIdx;
        _editedPcs = _pcsFromRow(row);
      }
    });
  }

  void _commitSelection(
      BJJualInputViewModel vm,
      ProductionLabelLookupResult result,
      Map<String, dynamic> selectedRow,
      ) {
    // selectedRow adalah row asli dari result.data (bukan copy)
    final originalPcs = selectedRow['pcs'];
    final originalIsPartial = selectedRow['isPartial'];

    // paksa jadi partial + pcs edited (kalau user edit)
    if (_editedPcs != null) {
      selectedRow['isPartial'] = true;
      selectedRow['IsPartial'] = true;
      selectedRow['pcs'] = _editedPcs;
      selectedRow['Pcs'] = _editedPcs;
    }

    vm.clearPicks();
    vm.togglePick(selectedRow);

    final r = vm.commitPickedToTemp(noBJJual: widget.noBJJual);

    // restore row value biar gak “mengotori” cache lookup
    if (_editedPcs != null) {
      selectedRow['pcs'] = originalPcs;
      selectedRow['Pcs'] = originalPcs;
      selectedRow['isPartial'] = originalIsPartial;
      selectedRow['IsPartial'] = originalIsPartial;
    }

    Navigator.pop(context);

    final msg = r.added > 0
        ? 'Ditambahkan ${r.added} item${r.skipped > 0 ? ' • Duplikat terlewati ${r.skipped}' : ''}'
        : 'Item sudah ada atau gagal ditambahkan';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: r.added > 0 ? Colors.green : Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              height: 160,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data...',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final allTypedItems = result.typedItems;
        final allData = result.data;

        // ✅ Filter: hanya Barang Jadi
        final bjIndexes = <int>[];
        for (int i = 0; i < allTypedItems.length; i++) {
          if (allTypedItems[i] is BarangJadiItem) bjIndexes.add(i);
        }

        if (bjIndexes.isEmpty) {
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      size: 44, color: Colors.orange.shade700),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak ada data Barang Jadi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lookup label ini tidak mengembalikan item BJ.',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          );
        }

        final sample = allTypedItems[bjIndexes.first] as BarangJadiItem;
        final labelCode = _labelCodeOf(sample);
        const namaJenis = 'Barang Jadi';

        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
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
                      colors: [Colors.amber.shade600, Colors.amber.shade700],
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
                        child: const Icon(Icons.inventory_2,
                            size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  labelCode,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PARTIAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${bjIndexes.length} item',
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

                // INFO BOX
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.lightbulb_outline,
                            size: 20, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Pilih SATU item BJ, lalu klik Edit untuk mengubah jumlah pcs (partial)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // COLUMN HEADERS
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border:
                    Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                        width: 140,
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

                // LIST (BJ only)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: bjIndexes.length,
                    itemBuilder: (_, filteredIdx) {
                      final realIdx = bjIndexes[filteredIdx];
                      final item = allTypedItems[realIdx] as BarangJadiItem;
                      final rawRow = allData[realIdx];

                      final presence = _presenceForRow(vm, rawRow, result);
                      final isDisabled = presence == _Presence.temp;

                      final isSelected = _selectedIndex == filteredIdx;

                      final originalPcs = item.pcs;
                      final originalBerat = item.berat;

                      final displayPcs =
                      isSelected && _editedPcs != null ? _editedPcs! : originalPcs;
                      final pcsText = displayPcs?.toString() ?? '-';
                      final beratText =
                      originalBerat == null ? '-' : num2(originalBerat);

                      final isOriginalPartial = _isPartialOf(item, rawRow);
                      final isPcsEdited = isSelected &&
                          _editedPcs != null &&
                          _editedPcs != originalPcs;

                      String? statusText;
                      Color? statusColor;
                      if (presence == _Presence.temp) {
                        statusText = 'Sudah Input';
                        statusColor = Colors.orange;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IgnorePointer(
                          ignoring: isDisabled,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isDisabled ? 0.4 : 1.0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isDisabled
                                    ? null
                                    : () => _toggleRow(
                                  filteredIdx,
                                  rawRow,
                                  isDisabled,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected && !isDisabled
                                        ? Colors.amber.shade50
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected && !isDisabled
                                          ? Colors.amber.shade400
                                          : Colors.grey.shade200,
                                      width: isSelected && !isDisabled ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected && !isDisabled
                                        ? [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Radio
                                      Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Radio<int>(
                                          value: filteredIdx,
                                          groupValue: _selectedIndex,
                                          activeColor: Colors.amber,
                                          onChanged: isDisabled
                                              ? null
                                              : (_) => _toggleRow(
                                            filteredIdx,
                                            rawRow,
                                            isDisabled,
                                          ),
                                          materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),

                                      // PCS
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            if (isOriginalPartial) ...[
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(
                                                  Icons.content_cut,
                                                  size: 14,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Expanded(
                                              child: Text(
                                                '$pcsText pcs',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: isDisabled
                                                      ? Colors.grey.shade400
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Berat
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isPcsEdited
                                                    ? [
                                                  Colors.amber.shade300,
                                                  Colors.amber.shade400
                                                ]
                                                    : statusText != null
                                                    ? [
                                                  statusColor!.withOpacity(0.2),
                                                  statusColor.withOpacity(0.3)
                                                ]
                                                    : [
                                                  Colors.green.shade100,
                                                  Colors.green.shade200
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$beratText kg',
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

                                      // Status + Edit
                                      SizedBox(
                                        width: 140,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (isSelected && !isDisabled)
                                              SizedBox(
                                                height: 32,
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    side: BorderSide(
                                                      color: Colors.amber.shade600,
                                                      width: 1.5,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  icon: Icon(
                                                    Icons.edit_outlined,
                                                    size: 14,
                                                    color: Colors.amber.shade700,
                                                  ),
                                                  label: Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.amber.shade700,
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    final maxPcs = item.pcs;
                                                    if (maxPcs != null && maxPcs > 0) {
                                                      final newPcs =
                                                      await _showPcsInputDialog(
                                                        context,
                                                        maxPcs: maxPcs,
                                                        currentPcs: _editedPcs,
                                                      );
                                                      if (newPcs != null && mounted) {
                                                        setState(() => _editedPcs = newPcs);
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            if (isSelected && !isDisabled)
                                              const SizedBox(width: 8),
                                            if (statusText != null)
                                              _badge(statusText, statusColor!)
                                            else if (isPcsEdited)
                                              _badge('EDITED', Colors.amber.shade700)
                                            else if (isOriginalPartial)
                                                _badge('PARTIAL', Colors.orange.shade700),
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
                        onPressed: _selectedIndex != null
                            ? () => setState(() {
                          _selectedIndex = null;
                          _editedPcs = null;
                        })
                            : null,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Batal'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedIndex != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade100, Colors.amber.shade200],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '1 item${_editedPcs != null ? ' • Diubah' : ''}',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _selectedIndex == null
                            ? null
                            : () {
                          final realIdx = bjIndexes[_selectedIndex!];
                          final selectedRow = allData[realIdx];
                          _commitSelection(vm, result, selectedRow);
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(_selectedIndex == null ? 'Pilih Item' : 'Tambahkan'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
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

  // ===== UI HELPERS =====
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

  // ===== DATA HELPERS =====
  int? _pcsFromRow(Map<String, dynamic> row) {
    final pcs = row['pcs'] ?? row['Pcs'];
    if (pcs is num) return pcs.toInt();
    if (pcs is String) return int.tryParse(pcs);
    return null;
  }

  static String _labelCodeOf(dynamic item) {
    if (item is BarangJadiItem) {
      final p = (item.noBJPartial ?? '').trim();
      if (p.isNotEmpty) return p;
      return item.noBJ ?? '-';
    }
    return '-';
  }

  static bool _boolish(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y';
  }

  static bool _isPartialOf(BarangJadiItem item, Map<String, dynamic> row) {
    if (_boolish(row['isPartial']) || _boolish(row['IsPartial'])) return true;
    if (item.isPartialRow) return true;
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
