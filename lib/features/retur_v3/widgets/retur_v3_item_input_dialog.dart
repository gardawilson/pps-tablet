import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../furniture_wip_type/model/furniture_wip_type_model.dart';
import '../../furniture_wip_type/widgets/furniture_wip_type_dropdown.dart';
import '../../mst_barang_jadi/model/mst_barang_jadi_model.dart';
import '../../mst_barang_jadi/repository/mst_barang_jadi_repository.dart';
import '../../mst_barang_jadi/view_model/mst_barang_jadi_view_model.dart';
import '../../mst_barang_jadi/widgets/barang_jadi_dropdown.dart';
import '../model/retur_v3_item.dart';

const _kPrimary = Color(0xFF1E6FD9);

/// Hasil input dialog tambah item Retur v3 — dikirim balik ke pemanggil
/// lewat `Navigator.pop(result)`.
class ReturV3ItemInput {
  final String kodeKategori;
  final int idJenis;
  final String namaJenis;
  final int pcs;
  final String kategoriInput;

  const ReturV3ItemInput({
    required this.kodeKategori,
    required this.idJenis,
    required this.namaJenis,
    required this.pcs,
    required this.kategoriInput,
  });
}

/// Dialog tambah item retur: toggle kategori (Barang Jadi / Furniture WIP),
/// dropdown jenis sesuai kategori, input pcs, dan toggle Bagus/Reject
/// (kategoriInput) yang dipilih di awal sebelum keputusan PIC.
class ReturV3ItemInputDialog extends StatefulWidget {
  const ReturV3ItemInputDialog({super.key});

  @override
  State<ReturV3ItemInputDialog> createState() =>
      _ReturV3ItemInputDialogState();
}

class _ReturV3ItemInputDialogState extends State<ReturV3ItemInputDialog> {
  String _kodeKategori = ReturV3Kategori.barangJadi;
  String _kategoriInput = ReturV3KategoriInput.bagus;

  MstBarangJadi? _selectedBarangJadi;
  FurnitureWipType? _selectedFurnitureWip;

  final _pcsCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pcsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pcs = int.tryParse(_pcsCtrl.text.trim()) ?? 0;
    if (pcs <= 0) {
      setState(() => _error = 'Pcs harus lebih dari 0');
      return;
    }

    int idJenis;
    String namaJenis;
    if (_kodeKategori == ReturV3Kategori.barangJadi) {
      if (_selectedBarangJadi == null) {
        setState(() => _error = 'Pilih jenis barang jadi');
        return;
      }
      idJenis = _selectedBarangJadi!.idJenis;
      namaJenis = _selectedBarangJadi!.namaJenis;
    } else {
      if (_selectedFurnitureWip == null) {
        setState(() => _error = 'Pilih jenis furniture WIP');
        return;
      }
      idJenis = _selectedFurnitureWip!.idCabinetWip;
      namaJenis = _selectedFurnitureWip!.nama;
    }

    Navigator.of(context).pop(
      ReturV3ItemInput(
        kodeKategori: _kodeKategori,
        idJenis: idJenis,
        namaJenis: namaJenis,
        pcs: pcs,
        kategoriInput: _kategoriInput,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MstBarangJadiViewModel>(
      create: (_) =>
          MstBarangJadiViewModel(repository: MstBarangJadiRepository()),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tambah Item Retur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildKategoriToggle(),
                  const SizedBox(height: 16),
                  if (_kodeKategori == ReturV3Kategori.barangJadi)
                    BarangJadiDropdown(
                      onChanged: (v) =>
                          setState(() => _selectedBarangJadi = v),
                    )
                  else
                    FurnitureWipTypeDropdown(
                      onChanged: (v) =>
                          setState(() => _selectedFurnitureWip = v),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _pcsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Pcs',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _buildKategoriInputToggle()),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Tambah'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKategoriToggle() {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Barang Jadi',
            selected: _kodeKategori == ReturV3Kategori.barangJadi,
            onTap: () => setState(() {
              _kodeKategori = ReturV3Kategori.barangJadi;
              _error = null;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleChip(
            label: 'Furniture WIP',
            selected: _kodeKategori == ReturV3Kategori.furnitureWip,
            onTap: () => setState(() {
              _kodeKategori = ReturV3Kategori.furnitureWip;
              _error = null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriInputToggle() {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Bagus',
            color: Colors.green,
            selected: _kategoriInput == ReturV3KategoriInput.bagus,
            onTap: () =>
                setState(() => _kategoriInput = ReturV3KategoriInput.bagus),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleChip(
            label: 'Rusak',
            color: Colors.red,
            selected: _kategoriInput == ReturV3KategoriInput.reject,
            onTap: () =>
                setState(() => _kategoriInput = ReturV3KategoriInput.reject),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = _kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
