// lib/features/bahan_pendukung/penerimaan/view/penerimaan_bahan_pendukung_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../model/tim_penerimaan_model.dart';
import '../repository/penerimaan_bahan_pendukung_repository.dart';
import '../widgets/penerimaan_bahan_pendukung_item_form_dialog.dart';

const _kAccent = Color(0xFF00897B);

/// Layar input barang ("create label") — mengikuti pola
/// `PenerimaanBahanBakuInputScreen`, TAPI hanya SATU section (tidak ada
/// split Pakai/Proses) karena bahan pendukung tidak punya kategori.
/// Dialog header (`PenerimaanBahanPendukungCreateDialog`) sudah membuat
/// NoPenerimaan di database (fase 1) sebelum screen ini dibuka; screen
/// PENUH ini adalah fase 2, tempat barang SUNGGUHAN ditambahkan — tiap
/// barang diinput lewat `PenerimaanBahanPendukungItemFormDialog` ("Tambah
/// Barang"), lalu tampil sebagai kartu grid — sebelum akhirnya dikirim ke
/// server lewat satu request `addItems()` berisi semua barang sekaligus.
class PenerimaanBahanPendukungInputScreen extends StatefulWidget {
  final TimPenerimaanInfo tim;
  final PenerimaanBahanPendukungHeaderResult header;

  const PenerimaanBahanPendukungInputScreen({
    super.key,
    required this.tim,
    required this.header,
  });

  @override
  State<PenerimaanBahanPendukungInputScreen> createState() =>
      _PenerimaanBahanPendukungInputScreenState();
}

class _PenerimaanBahanPendukungInputScreenState
    extends State<PenerimaanBahanPendukungInputScreen> {
  late final PenerimaanBahanPendukungRepository _repo;
  final List<PenerimaanBahanPendukungItemInput> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repo = PenerimaanBahanPendukungRepository(api: context.read<ApiClient>());
  }

  Future<void> _openItemDialog() async {
    final item = await showDialog<PenerimaanBahanPendukungItemInput>(
      context: context,
      builder: (_) => const PenerimaanBahanPendukungItemFormDialog(accentColor: _kAccent),
    );
    if (item == null || !mounted) return;
    setState(() => _items.add(item));
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  Future<void> _submit() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 1 barang wajib diisi')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repo.addItems(noPenerimaan: widget.header.noPenerimaan, items: _items);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Menyimpan',
          message: 'Penerimaan ${widget.header.noPenerimaan} berhasil disimpan.',
        ),
      );
      if (mounted) Navigator.of(context).pop(widget.header.noPenerimaan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorStatusDialog(title: 'Gagal Menyimpan', message: e.toString()),
      );
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtQty(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${widget.tim.namaTim} — Penerimaan Bahan Pendukung'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderInfoCard(),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Belum ada barang', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            )
          else
            LayoutBuilder(
              builder: (_, c) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 420 ? 1 : (c.maxWidth < 720 ? 2 : 3),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemCount: _items.length,
                itemBuilder: (_, i) => _buildItemTile(i),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _openItemDialog,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Barang'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _isSaving ? 'MENYIMPAN...' : 'SIMPAN PENERIMAAN',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoCard() {
    final h = widget.header;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: [
          _infoChip(Icons.assignment_outlined, 'No Penerimaan', h.noPenerimaan),
          _infoChip(Icons.calendar_today_outlined, 'Tanggal', _fmtDate(h.tanggal)),
          _infoChip(Icons.groups_outlined, 'Tim', widget.tim.namaTim),
          _infoChip(Icons.person_outline, 'Operator', h.namaOperators),
          _infoChip(Icons.schedule_outlined, 'Shift', 'Shift ${h.shift}'),
          _infoChip(Icons.access_time_outlined, 'Jam', '${h.hourStart} – ${h.hourEnd}'),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildItemTile(int index) {
    final item = _items[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: double.infinity,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(3)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.namaBarang,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmtQty(item.qty)} ${item.satuan}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kAccent),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeItem(index),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: const Color(0xFFDC2626),
            tooltip: 'Hapus Barang',
          ),
        ],
      ),
    );
  }
}
