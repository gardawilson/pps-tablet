// lib/features/production/penerimaan_bahan_baku/widgets/penerimaan_bahan_baku_pallet_form_dialog.dart
//
// Dialog tambah 1 pallet (label) bahan baku — format meniru
// `WashingProductionOutputFormDialog` ("Tambah Label Washing"): field
// pallet (Jenis Plastik/Warehouse/Keterangan) di atas, lalu quick-add
// "Berat per sak × Jumlah sak" yang membangun grid kartu sak (bisa
// dihapus), footer Batal/Simpan. TIDAK hit backend langsung (beda dengan
// washing yang punya endpoint per-label) — hasilnya dikembalikan sebagai
// [PenerimaanBahanBakuPalletDraft] ke screen input, yang baru benar-benar
// dikirim ke server saat "SIMPAN PENERIMAAN" (1 request per section berisi
// semua pallet-nya, lihat `PenerimaanBahanBakuRepository.addPallets`).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/plastic_type/jenis_plastik_dropdown.dart';
import '../../../shared/plastic_type/jenis_plastik_model.dart';
import '../../../warehouse/model/warehouse_model.dart';
import '../../../warehouse/widgets/warehouse_dropdown.dart';
import '../repository/penerimaan_bahan_baku_repository.dart';

const _kOutput = Color(0xFF00897B);
const _kBorder = Color(0xFFE2E6EA);

/// Satu sak yang sudah ditambahkan lewat quick-add di dalam dialog ini.
class _SakEntry {
  final int noSak;
  final double berat;
  const _SakEntry({required this.noSak, required this.berat});
}

/// Hasil 1 pallet lengkap (siap dikirim sebagai bagian dari
/// [PenerimaanPalletInput]) — dikembalikan lewat `Navigator.pop` saat SIMPAN
/// di dalam dialog ini ditekan.
class PenerimaanBahanBakuPalletDraft {
  final JenisPlastik jenisPlastik;
  final MstWarehouse? warehouse;
  final String? keterangan;
  final List<PenerimaanSakInput> saks;

  const PenerimaanBahanBakuPalletDraft({
    required this.jenisPlastik,
    this.warehouse,
    this.keterangan,
    required this.saks,
  });

  int get jumlahSak => saks.length;
  double get totalBerat => saks.fold(0.0, (s, e) => s + e.berat);

  PenerimaanPalletInput toPalletInput() => PenerimaanPalletInput(
    idJenisPlastik: jenisPlastik.idJenisPlastik,
    idWarehouse: warehouse?.idWarehouse,
    keterangan: keterangan,
    saks: saks,
  );
}

class PenerimaanBahanBakuPalletFormDialog extends StatefulWidget {
  final String kategoriTitle;
  final Color accentColor;

  const PenerimaanBahanBakuPalletFormDialog({
    super.key,
    required this.kategoriTitle,
    this.accentColor = _kOutput,
  });

  @override
  State<PenerimaanBahanBakuPalletFormDialog> createState() =>
      _PenerimaanBahanBakuPalletFormDialogState();
}

class _PenerimaanBahanBakuPalletFormDialogState
    extends State<PenerimaanBahanBakuPalletFormDialog> {
  JenisPlastik? _jenisPlastik;
  MstWarehouse? _warehouse;
  final _keteranganCtrl = TextEditingController();

  final _beratCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();
  String? _beratErr;
  String? _jumlahErr;

  final List<_SakEntry> _saks = [];
  String? _saveError;

  int get _totalSak => _saks.length;
  double get _totalBerat => _saks.fold(0.0, (s, e) => s + e.berat);

  int _nextSakNo() {
    if (_saks.isEmpty) return 1;
    return _saks.map((e) => e.noSak).reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    _beratCtrl.dispose();
    _jumlahCtrl.dispose();
    super.dispose();
  }

  void _commitAddSak() {
    final berat = double.tryParse(_beratCtrl.text.trim().replaceAll(',', '.'));
    final jumlah = int.tryParse(_jumlahCtrl.text.trim());

    setState(() {
      _beratErr = (berat == null || berat <= 0) ? 'Harus > 0' : null;
      _jumlahErr = (jumlah == null || jumlah <= 0) ? 'Minimal 1' : null;
    });
    if (_beratErr != null || _jumlahErr != null) return;

    setState(() {
      final start = _nextSakNo();
      for (var i = 0; i < jumlah!; i++) {
        _saks.add(_SakEntry(noSak: start + i, berat: berat!));
      }
      _jumlahCtrl.clear();
      _saveError = null;
    });
  }

  void _deleteSak(int index) => setState(() => _saks.removeAt(index));

  void _save() {
    if (_jenisPlastik == null) {
      setState(() => _saveError = 'Jenis plastik wajib dipilih.');
      return;
    }
    if (_saks.isEmpty) {
      setState(() => _saveError = 'Tambah minimal 1 sak terlebih dahulu.');
      return;
    }

    Navigator.of(context).pop(
      PenerimaanBahanBakuPalletDraft(
        jenisPlastik: _jenisPlastik!,
        warehouse: _warehouse,
        keterangan: _keteranganCtrl.text,
        saks: _saks.map((e) => PenerimaanSakInput(noSak: e.noSak, berat: e.berat)).toList(),
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
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDialogHeader(),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: _buildPalletFields(),
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            _buildInlineInputRow(),
            const Divider(height: 1, color: _kBorder),
            Expanded(child: _buildSakList()),
            if (_saveError != null) _buildErrorBanner(),
            const Divider(height: 1, color: _kBorder),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
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
          Expanded(
            child: Text(
              'Tambah Label ${widget.kategoriTitle}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
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

  Widget _buildPalletFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JenisPlastikDropdown(
          onChanged: (jp) => setState(() => _jenisPlastik = jp),
        ),
        const SizedBox(height: 12),
        WarehouseDropdown(
          onChanged: (w) => setState(() => _warehouse = w),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _keteranganCtrl,
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

  Widget _buildInlineInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _InlineField(
              controller: _beratCtrl,
              label: 'Berat per sak (kg)',
              icon: Icons.scale_outlined,
              accentColor: widget.accentColor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              errorText: _beratErr,
              onChanged: (_) => setState(() => _beratErr = null),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 10, right: 10),
            child: Text('×', style: TextStyle(fontSize: 18, color: Colors.grey.shade400)),
          ),
          Expanded(
            child: _InlineField(
              controller: _jumlahCtrl,
              label: 'Jumlah sak',
              icon: Icons.inventory_2_outlined,
              accentColor: widget.accentColor,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: _jumlahErr,
              onChanged: (_) => setState(() => _jumlahErr = null),
              onSubmitted: (_) => _commitAddSak(),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _commitAddSak,
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSakList() {
    if (_saks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 6),
            Text('Belum ada sak', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (_, c) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: c.maxWidth < 300 ? 3 : (c.maxWidth < 400 ? 4 : 5),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.3,
        ),
        itemCount: _saks.length,
        itemBuilder: (_, i) => _SakCard(entry: _saks[i], onDelete: () => _deleteSak(i)),
      ),
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.accentColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$_totalSak sak  ·  ${_totalBerat.toStringAsFixed(2)} kg',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.accentColor),
            ),
          ),
          const Spacer(),
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

class _SakCard extends StatelessWidget {
  final _SakEntry entry;
  final VoidCallback onDelete;

  const _SakCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sak ${entry.noSak}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF00695C)),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.berat.toStringAsFixed(2)} kg',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _InlineField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.keyboardType,
    required this.inputFormatters,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 15),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        errorText: errorText,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
      ),
    );
  }
}
