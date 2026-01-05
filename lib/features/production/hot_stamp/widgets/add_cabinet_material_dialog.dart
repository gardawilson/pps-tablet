// lib/features/production/hot_stamping/widgets/add_cabinet_material_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../view_model/hot_stamp_production_input_view_model.dart';
import '../../shared/models/cabinet_material_item.dart';

class AddCabinetMaterialDialog extends StatefulWidget {
  final int idWarehouse;

  const AddCabinetMaterialDialog({
    super.key,
    required this.idWarehouse,
  });

  @override
  State<AddCabinetMaterialDialog> createState() => _AddCabinetMaterialDialogState();
}

class _AddCabinetMaterialDialogState extends State<AddCabinetMaterialDialog> {
  CabinetMaterialItem? _selected;
  final _jumlahController = TextEditingController(text: '1');

  bool _isLoading = false;
  String? _loadError;
  List<CabinetMaterialItem> _materials = const [];

  @override
  void initState() {
    super.initState();
    _loadMasterMaterials();
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterMaterials() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final vm = context.read<HotStampingProductionInputViewModel>();

      final items = await vm.loadMasterCabinetMaterials(
        idWarehouse: widget.idWarehouse,
        force: false,
      );

      if (!mounted) return;

      items.sort((a, b) => (a.Nama ?? '').compareTo(b.Nama ?? ''));

      setState(() {
        _materials = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  num _parseJumlah() {
    final raw = _jumlahController.text.trim();
    if (raw.isEmpty) return 0;
    final v = num.tryParse(raw);
    return v ?? 0;
  }

  void _handleSubmit() {
    final vm = context.read<HotStampingProductionInputViewModel>();

    final selected = _selected;
    if (selected == null || (selected.IdCabinetMaterial ?? 0) <= 0) {
      _showSnack('Pilih material terlebih dahulu', isError: true);
      return;
    }

    final id = selected.IdCabinetMaterial ?? 0;

    if (vm.hasCabinetMaterialInTemp(id)) {
      _showSnack('${selected.Nama ?? "Material"} sudah ada di TEMP', isError: true);
      return;
    }

    final jumlah = _parseJumlah();
    if (jumlah <= 0) {
      _showSnack('Jumlah harus lebih dari 0', isError: true);
      return;
    }

    final available = (selected.SaldoAkhir ?? 0);
    if (jumlah > available) {
      _showSnack(
        'Jumlah melebihi stok tersedia ($available ${selected.NamaUOM ?? "unit"})',
        isError: true,
      );
      return;
    }

    vm.addTempCabinetMaterialFromMaster(
      masterItem: selected,
      Jumlah: jumlah,
    );

    Navigator.pop(context);
    _showSnack('✅ ${selected.Nama ?? "Material"} ditambahkan ke TEMP');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.orange : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedStock = (_selected?.SaldoAkhir ?? 0);
    final selectedUom = _selected?.NamaUOM ?? 'unit';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
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
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tambah Material',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Warehouse ${widget.idWarehouse}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // ===== CONTENT =====
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== ERROR MESSAGE =====
                  if (_loadError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gagal memuat data',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _loadError!,
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isLoading ? null : _loadMasterMaterials,
                            icon: Icon(Icons.refresh, color: Colors.red.shade700),
                            tooltip: 'Coba lagi',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ===== EMPTY STATE =====
                  if (!_isLoading && _loadError == null && _materials.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada material tersedia',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ===== DROPDOWN MATERIAL =====
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Material',
                      hintText: 'Pilih material',
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
                      ),
                    ),
                    value: _selected?.IdCabinetMaterial,
                    isExpanded: true,
                    items: _isLoading
                        ? const []
                        : _materials.map((m) {
                      final stock = (m.SaldoAkhir ?? 0);
                      final uom = m.NamaUOM ?? 'unit';
                      final name = m.Nama ?? 'Material ${m.IdCabinetMaterial ?? 0}';

                      return DropdownMenuItem<int>(
                        value: m.IdCabinetMaterial,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: stock > 0 ? Colors.green.shade200 : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                '$stock $uom',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                      if (value == null) {
                        setState(() => _selected = null);
                        return;
                      }
                      final picked = _materials.firstWhere(
                            (x) => (x.IdCabinetMaterial ?? 0) == value,
                        orElse: () => _materials.first,
                      );
                      setState(() => _selected = picked);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ===== STOCK INFO (COMPACT) =====
                  if (_selected != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedStock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedStock > 0 ? Icons.check_circle : Icons.warning_rounded,
                            size: 18,
                            color: selectedStock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Stok tersedia: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '$selectedStock $selectedUom',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: selectedStock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ===== INPUT JUMLAH =====
                  TextField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: _selected != null,
                    decoration: InputDecoration(
                      labelText: 'Jumlah',
                      hintText: 'Masukkan jumlah',
                      prefixIcon: const Icon(Icons.pin_outlined),
                      suffixText: selectedUom,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== FOOTER BUTTONS =====
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (_isLoading || _selected == null) ? null : _handleSubmit,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Tambah'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.deepPurple.shade600,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
  }
}