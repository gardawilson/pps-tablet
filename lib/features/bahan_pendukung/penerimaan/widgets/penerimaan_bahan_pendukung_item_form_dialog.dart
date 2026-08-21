// lib/features/bahan_pendukung/penerimaan/widgets/penerimaan_bahan_pendukung_item_form_dialog.dart
//
// Dialog tambah 1 barang ("label") bahan pendukung — format meniru
// `PenerimaanBahanBakuPalletFormDialog` ("Tambah Label"), TAPI jauh lebih
// sederhana karena tidak ada pallet/sak: cukup Supplier + Nama Barang +
// Qty + Satuan + Keterangan dalam satu form, tanpa quick-add grid.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../supplier/widgets/supplier_dropdown.dart';
import '../repository/penerimaan_bahan_pendukung_repository.dart';

const _kBorder = Color(0xFFE2E6EA);

class PenerimaanBahanPendukungItemFormDialog extends StatefulWidget {
  final Color accentColor;

  const PenerimaanBahanPendukungItemFormDialog({
    super.key,
    this.accentColor = const Color(0xFF00897B),
  });

  @override
  State<PenerimaanBahanPendukungItemFormDialog> createState() =>
      _PenerimaanBahanPendukungItemFormDialogState();
}

class _PenerimaanBahanPendukungItemFormDialogState
    extends State<PenerimaanBahanPendukungItemFormDialog> {
  int? _selectedSupplierId;
  final _namaBarangCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController(text: 'PCS');
  final _keteranganCtrl = TextEditingController();
  String? _saveError;

  @override
  void dispose() {
    _namaBarangCtrl.dispose();
    _qtyCtrl.dispose();
    _satuanCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_selectedSupplierId == null) {
      setState(() => _saveError = 'Supplier wajib dipilih.');
      return;
    }
    final namaBarang = _namaBarangCtrl.text.trim();
    if (namaBarang.isEmpty) {
      setState(() => _saveError = 'Nama barang wajib diisi.');
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text.trim().replaceAll(',', '.'));
    if (qty == null || qty <= 0) {
      setState(() => _saveError = 'Qty wajib diisi dan harus > 0.');
      return;
    }
    final satuan = _satuanCtrl.text.trim().isEmpty ? 'PCS' : _satuanCtrl.text.trim();

    Navigator.of(context).pop(
      PenerimaanBahanPendukungItemInput(
        idSupplier: _selectedSupplierId!,
        namaBarang: namaBarang,
        qty: qty,
        satuan: satuan,
        keterangan: _keteranganCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: _buildFields(),
              ),
            ),
            if (_saveError != null) _buildErrorBanner(),
            const Divider(height: 1, color: _kBorder),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: widget.accentColor, size: 17),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tambah Barang',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SupplierDropdown(
          onChanged: (s) => setState(() {
            _selectedSupplierId = s?.idSupplier;
            _saveError = null;
          }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _namaBarangCtrl,
          onChanged: (_) => setState(() => _saveError = null),
          decoration: InputDecoration(
            labelText: 'Nama Barang',
            prefixIcon: const Icon(Icons.category_outlined, size: 20),
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                onChanged: (_) => setState(() => _saveError = null),
                decoration: InputDecoration(
                  labelText: 'Qty',
                  prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _satuanCtrl,
                decoration: InputDecoration(
                  labelText: 'Satuan',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _keteranganCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Keterangan',
            hintText: 'Opsional',
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 15, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_saveError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Batal', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, size: 15),
            label: const Text('Simpan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
