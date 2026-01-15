import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/utils/format.dart';
import '../view_model/sortir_reject_production_input_view_model.dart';

enum _Presence { none, temp }

class SortirRejectLookupLabelDialogPartial extends StatefulWidget {
  final String noBJSortir;
  final String selectedMode;

  const SortirRejectLookupLabelDialogPartial({
    super.key,
    required this.noBJSortir,
    required this.selectedMode,
  });

  @override
  State<SortirRejectLookupLabelDialogPartial> createState() =>
      _SortirRejectLookupLabelDialogPartialState();
}

class _SortirRejectLookupLabelDialogPartialState
    extends State<SortirRejectLookupLabelDialogPartial> {
  int? _selectedIndex; // index pada list result (ALL items)
  int? _editedPcs;
  bool _inputsReady = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = null;
    _editedPcs = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<SortirRejectInputViewModel>();

      // Refresh lookup based on first item label code
      final lastLookup = vm.lastLookup;
      if (lastLookup != null && lastLookup.typedItems.isNotEmpty) {
        final firstItem = lastLookup.typedItems.first;
        final labelCode = _labelCodeOf(firstItem, lastLookup.data.first);
        if (labelCode != '-') {
          await vm.lookupLabel(labelCode, force: true);
        }
      }

      if (vm.inputsOf(widget.noBJSortir) == null) {
        await vm.loadInputs(widget.noBJSortir);
      }
      _inputsReady = true;

      if (mounted) setState(() {});
    });
  }

  _Presence _presenceForRow(
      SortirRejectInputViewModel vm,
      Map<String, dynamic> row,
      ProductionLabelLookupResult ctx,
      ) {
    final sk = ctx.simpleKey(row);
    if (vm.isInTempKeys(sk)) return _Presence.temp;
    return _Presence.none;
  }

  void _toggleRow(int idx, Map<String, dynamic> row, bool isDisabled) {
    if (isDisabled) return;

    setState(() {
      if (_selectedIndex == idx) {
        _selectedIndex = null;
        _editedPcs = null;
      } else {
        _selectedIndex = idx;
        _editedPcs = _pcsFromRow(row);
      }
    });
  }

  void _commitSelection(
      SortirRejectInputViewModel vm,
      ProductionLabelLookupResult result,
      Map<String, dynamic> selectedRow,
      ) {
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

    final r = vm.commitPickedToTemp(noBJSortir: widget.noBJSortir);

    // restore row value biar gak "mengotori" cache lookup
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
    return Consumer<SortirRejectInputViewModel>(
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              height: 160,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blue),
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

        if (allTypedItems.isEmpty) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 44, color: Colors.orange.shade700),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak ada data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lookup label ini tidak mengembalikan item.',
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

        final sampleItem = allTypedItems.first;
        final sampleRow = allData.first;

        final labelCode = _labelCodeOf(sampleItem, sampleRow);
        final namaJenis = result.tableName ?? result.prefix ?? 'Lookup';

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
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
                        child: const Icon(Icons.qr_code_scanner,
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
                          '${allTypedItems.length} item',
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
                          'Pilih SATU item, lalu klik Edit untuk mengubah pcs (jika tersedia)',
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

                // COLUMN HEADERS (generic)
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
                          'DETAIL',
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

                // LIST (ALL)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: allTypedItems.length,
                    itemBuilder: (_, idx) {
                      final item = allTypedItems[idx];
                      final rawRow = allData[idx];

                      final presence = _presenceForRow(vm, rawRow, result);
                      final isDisabled = presence == _Presence.temp;

                      final isSelected = _selectedIndex == idx;

                      final originalPcs = _pcsFromRow(rawRow);
                      final originalBerat = _beratFromRow(rawRow);

                      final displayPcs =
                      isSelected && _editedPcs != null ? _editedPcs : originalPcs;

                      final detailText = _detailTextOf(item, rawRow, displayPcs);

                      final beratText = originalBerat == null ? '-' : num2(originalBerat);

                      final isOriginalPartial = _isPartialOf(rawRow);
                      final isPcsEdited = isSelected &&
                          _editedPcs != null &&
                          originalPcs != null &&
                          _editedPcs != originalPcs;

                      String? statusText;
                      Color? statusColor;
                      if (presence == _Presence.temp) {
                        statusText = 'Sudah Input';
                        statusColor = Colors.orange;
                      }

                      final canEditPcs = (originalPcs != null && originalPcs > 0);

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
                                    : () => _toggleRow(idx, rawRow, isDisabled),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected && !isDisabled
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected && !isDisabled
                                          ? Colors.blue.shade400
                                          : Colors.grey.shade200,
                                      width: isSelected && !isDisabled ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected && !isDisabled
                                        ? [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
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
                                          value: idx,
                                          groupValue: _selectedIndex,
                                          activeColor: Colors.blue,
                                          onChanged: isDisabled
                                              ? null
                                              : (_) => _toggleRow(idx, rawRow, isDisabled),
                                          materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),

                                      // Detail
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
                                                detailText,
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
                                                  Colors.blue.shade300,
                                                  Colors.blue.shade400
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
                                                    ? Colors.blue.shade900
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
                                            if (isSelected && !isDisabled && canEditPcs)
                                              SizedBox(
                                                height: 32,
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    side: BorderSide(
                                                      color: Colors.blue.shade600,
                                                      width: 1.5,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  icon: Icon(
                                                    Icons.edit_outlined,
                                                    size: 14,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                  label: Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.blue.shade700,
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    final maxPcs = originalPcs!;
                                                    final newPcs = await _showPcsInputDialog(
                                                      context,
                                                      maxPcs: maxPcs,
                                                      currentPcs: _editedPcs,
                                                    );
                                                    if (newPcs != null && mounted) {
                                                      setState(() => _editedPcs = newPcs);
                                                    }
                                                  },
                                                ),
                                              ),

                                            if (isSelected && !isDisabled && canEditPcs)
                                              const SizedBox(width: 8),

                                            if (statusText != null)
                                              _badge(statusText, statusColor!)
                                            else if (isPcsEdited)
                                              _badge('EDITED', Colors.blue.shade700)
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
                              colors: [Colors.blue.shade100, Colors.blue.shade200],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '1 item${_editedPcs != null ? ' • Diubah' : ''}',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _selectedIndex == null
                            ? null
                            : () {
                          final selectedRow = allData[_selectedIndex!];
                          _commitSelection(vm, result, selectedRow);
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(_selectedIndex == null ? 'Pilih Item' : 'Tambahkan'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
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

  double? _beratFromRow(Map<String, dynamic> row) {
    final v = row['berat'] ?? row['Berat'];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String _labelCodeOf(dynamic item, Map<String, dynamic> row) {
    // Try row first (more universal)
    final candidates = [
      row['labelCode'],
      row['LabelCode'],
      row['noLabel'],
      row['NoLabel'],
      row['noBJ'],
      row['NoBJ'],
      row['noReject'],
      row['NoReject'],
      row['noFurnitureWip'],
      row['NoFurnitureWip'],
      row['noFurnitureWIP'],
      row['NoFurnitureWIP'],
    ];

    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }

    // Fallback: try common typed fields via dynamic (safe try/catch)
    try {
      final dyn = item as dynamic;
      final s = (dyn.noBJ ??
          dyn.noReject ??
          dyn.noFurnitureWip ??
          dyn.noFurnitureWIP ??
          '')
          .toString()
          .trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}

    return '-';
  }

  static String _detailTextOf(dynamic item, Map<String, dynamic> row, int? pcs) {
    // Prefer a meaningful identifier
    final ref = (row['ref1'] ??
        row['Ref1'] ??
        row['noSak'] ??
        row['NoSak'] ??
        row['noPallet'] ??
        row['NoPallet'])
        ?.toString()
        .trim();

    if (ref != null && ref.isNotEmpty && ref.toLowerCase() != 'null') return ref;

    if (pcs != null) return '$pcs pcs';

    // last fallback: label code
    return _labelCodeOf(item, row);
  }

  static bool _boolish(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y';
  }

  static bool _isPartialOf(Map<String, dynamic> row) {
    if (_boolish(row['isPartial']) || _boolish(row['IsPartial'])) return true;
    return false;
  }

  Future<int?> _showPcsInputDialog(
      BuildContext context, {
        required int maxPcs,
        int? currentPcs,
      }) async {
    final controller = TextEditingController(text: currentPcs?.toString() ?? '');

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