import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/utils/format.dart';
import '../view_model/broker_production_input_view_model.dart';
import '../model/broker_inputs_model.dart';
import '../../shared/models/production_label_lookup_result.dart';

class LookupLabelPartialDialog extends StatefulWidget {
  final String noProduksi;
  final String selectedMode;

  const LookupLabelPartialDialog({
    super.key,
    required this.noProduksi,
    required this.selectedMode,
  });

  @override
  State<LookupLabelPartialDialog> createState() => _LookupLabelPartialDialogState();
}

class _LookupLabelPartialDialogState extends State<LookupLabelPartialDialog> {
  int? _selectedIndex; // Single selection dengan radio button
  double? _editedWeight; // Berat yang diedit
  bool _isEditingWeight = false;

  bool _inputsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<BrokerProductionInputViewModel>();

      if (vm.inputsOf(widget.noProduksi) == null) {
        await vm.loadInputs(widget.noProduksi);
      }
      _inputsReady = true;

      if (mounted) setState(() {});
    });
  }

  void _toggleRow(int index, Map<String, dynamic> row) {
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null;
        _editedWeight = null;
        _isEditingWeight = false;
      } else {
        _selectedIndex = index;
        // Set default weight dari row
        final weight = _beratFromRow(row);
        _editedWeight = weight;
        _isEditingWeight = false;
      }
    });
  }

  void _commitSelection(BrokerProductionInputViewModel vm, ProductionLabelLookupResult result) {
    if (_selectedIndex == null) return;

    final row = result.data[_selectedIndex!];

    // ⬇️ PENTING: Update berat jika ada perubahan
    // Ini akan membuat item menjadi partial jika berat diubah
    if (_editedWeight != null) {
      row['berat'] = _editedWeight;
      row['Berat'] = _editedWeight;

      // ⬇️ Tandai sebagai partial karena berat diubah
      row['isPartial'] = true;
      row['IsPartial'] = true;
    }

    vm.clearPicks();
    if (!vm.isPicked(row)) vm.togglePick(row);

    final r = vm.commitPickedToTemp(noProduksi: widget.noProduksi);
    Navigator.pop(context);

    final msg = r.added > 0
        ? 'Ditambahkan ${r.added} item${r.skipped > 0 ? ' • Duplikat terlewati ${r.skipped}' : ''}'
        : 'Item sudah ada atau gagal ditambahkan';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: r.added > 0 ? Colors.green : Colors.orange,
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

        // ⬇️ TIDAK FILTER - Tampilkan semua item (partial dan non-partial)
        final allTypedItems = result.typedItems;
        final allData = result.data;

        if (allTypedItems.isEmpty) {
          return Dialog(
            child: SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.orange.shade700),
                    const SizedBox(height: 16),
                    const Text(
                      'Tidak ada data',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Label ini tidak memiliki data.',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final prefixType = result.prefixType;
        final dynamic sample = allTypedItems.first;
        final labelCode = _labelCodeOf(sample);
        final namaJenis = _namaJenisOf(sample) ?? '-';

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(color: Colors.amber.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.content_cut, size: 22, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  labelCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                  ),
                                  child: const Text(
                                    'MODE PARTIAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              namaJenis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text('${allTypedItems.length} item'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.amber.withOpacity(0.2),
                      ),
                    ],
                  ),
                ),

                // INFO BOX
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pilih SATU item dan ubah beratnya untuk membuat partial. Berat yang diubah akan menjadi partial baru.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // COLUMN HEADERS
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 40), // radio button space
                      Expanded(
                        flex: 2,
                        child: Text(
                          _getDetailHeader(prefixType),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'BERAT (KG)',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'STATUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                // LIST
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    itemCount: allTypedItems.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                    itemBuilder: (_, idx) {
                      final item = allTypedItems[idx];
                      final rawRow = allData[idx];

                      final isSelected = _selectedIndex == idx;
                      final detail = _getDetailText(item, prefixType);
                      final originalWeight = _beratOf(item);

                      // ⬇️ Gunakan edited weight jika sedang diedit
                      final displayWeight = isSelected && _editedWeight != null
                          ? _editedWeight!
                          : originalWeight;
                      final weightText = displayWeight == null ? '-' : num2(displayWeight);

                      // ⬇️ Cek apakah ini item partial (dari data asli)
                      final isOriginalPartial = _isPartialOf(item, rawRow);

                      // ⬇️ Cek apakah berat sudah diubah (akan menjadi partial)
                      final isWeightEdited = isSelected &&
                          _editedWeight != null &&
                          _editedWeight != originalWeight;

                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber.withOpacity(0.1) : null,
                          border: isSelected
                              ? Border.all(color: Colors.amber.withOpacity(0.5), width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: InkWell(
                          onTap: () => _toggleRow(idx, rawRow),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              children: [
                                // RADIO BUTTON
                                SizedBox(
                                  width: 40,
                                  child: Radio<int>(
                                    value: idx,
                                    groupValue: _selectedIndex,
                                    onChanged: (_) => _toggleRow(idx, rawRow),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),

                                // DETAIL
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    detail,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // BERAT
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: isSelected && _isEditingWeight
                                        ? _buildWeightEditor(displayWeight)
                                        : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isWeightEdited
                                            ? Colors.amber.withOpacity(0.2)
                                            : Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: isWeightEdited
                                              ? Colors.amber.withOpacity(0.4)
                                              : Colors.green.withOpacity(0.25),
                                        ),
                                      ),
                                      child: Text(
                                        '$weightText kg',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // STATUS & EDIT BUTTON
                                SizedBox(
                                  width: 120,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Status Badge
                                      if (isWeightEdited)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                          ),
                                          child: const Text(
                                            'PARTIAL',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        )
                                      else if (isOriginalPartial)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            'PARTIAL',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),

                                      const SizedBox(width: 4),

                                      // Edit Button (hanya untuk yang selected)
                                      if (isSelected)
                                        if (!_isEditingWeight)
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 16),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setState(() => _isEditingWeight = true);
                                            },
                                            tooltip: 'Ubah Berat',
                                            visualDensity: VisualDensity.compact,
                                          )
                                        else
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() => _isEditingWeight = false);
                                                },
                                                tooltip: 'Simpan',
                                                visualDensity: VisualDensity.compact,
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() {
                                                    _editedWeight = originalWeight;
                                                    _isEditingWeight = false;
                                                  });
                                                },
                                                tooltip: 'Batal',
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ],
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // FOOTER
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _selectedIndex != null
                            ? () => setState(() {
                          _selectedIndex = null;
                          _editedWeight = null;
                          _isEditingWeight = false;
                        })
                            : null,
                        icon: const Icon(Icons.clear),
                        label: const Text('Batal Pilihan'),
                      ),
                      const Spacer(),
                      if (_selectedIndex != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '1 item dipilih${_editedWeight != null && _editedWeight != _beratOf(allTypedItems[_selectedIndex!]) ? ' (berat diubah)' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: _selectedIndex == null
                            ? null
                            : () => _commitSelection(vm, result),
                        icon: const Icon(Icons.check),
                        label: Text(
                          _selectedIndex == null ? 'Pilih Item' : 'Tambahkan',
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

  Widget _buildWeightEditor(double? currentWeight) {
    final controller = TextEditingController(
      text: currentWeight?.toString() ?? '',
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        autofocus: true,
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
            setState(() => _editedWeight = parsed);
          }
        },
      ),
    );
  }

  // ===== HELPERS =====

  String _getDetailHeader(PrefixType type) {
    switch (type) {
      case PrefixType.bb:
        return 'SAK';
      case PrefixType.gilingan:
        return 'NO GILINGAN';
      case PrefixType.mixer:
        return 'SAK';
      case PrefixType.reject:
        return 'NO REJECT';
      case PrefixType.broker:
        return 'SAK';
      case PrefixType.washing:
        return 'SAK';
      case PrefixType.crusher:
        return 'NO CRUSHER';
      default:
        return 'DETAIL';
    }
  }

  String _getDetailText(dynamic item, PrefixType type) {
    if (item is BbItem) return '${item.noSak ?? '-'}';
    if (item is GilinganItem) return item.noGilingan ?? '-';
    if (item is MixerItem) return '${item.noSak ?? '-'}';
    if (item is RejectItem) return item.noReject ?? '-';
    if (item is BrokerItem) return '${item.noSak ?? '-'}';
    if (item is WashingItem) return '${item.noSak ?? '-'}';
    if (item is CrusherItem) return item.noCrusher ?? '-';
    return '-';
  }

  double? _beratFromRow(Map<String, dynamic> row) {
    final berat = row['berat'] ?? row['Berat'];
    if (berat is num) return berat.toDouble();
    if (berat is String) return double.tryParse(berat);
    return null;
  }

  static String _labelCodeOf(dynamic item) {
    if (item is BrokerItem) return item.noBroker ?? '-';
    if (item is BbItem) {
      final npart = (item.noBBPartial ?? '').trim();
      if (npart.isNotEmpty) return npart;
      return item.noBahanBaku ?? '-';
    }
    if (item is WashingItem) return item.noWashing ?? '-';
    if (item is CrusherItem) return item.noCrusher ?? '-';
    if (item is GilinganItem) {
      return (item.noGilinganPartial ?? '').trim().isNotEmpty
          ? item.noGilinganPartial!
          : item.noGilingan ?? '-';
    }
    if (item is MixerItem) {
      return (item.noMixerPartial ?? '').trim().isNotEmpty
          ? item.noMixerPartial!
          : item.noMixer ?? '-';
    }
    if (item is RejectItem) {
      return (item.noRejectPartial ?? '').trim().isNotEmpty
          ? item.noRejectPartial!
          : item.noReject ?? '-';
    }
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
}