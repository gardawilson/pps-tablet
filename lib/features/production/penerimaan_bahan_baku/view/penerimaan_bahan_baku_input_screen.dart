// lib/features/production/penerimaan_bahan_baku/view/penerimaan_bahan_baku_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../../../supplier/widgets/supplier_dropdown.dart';
import '../model/penerimaan_kategori.dart';
import '../model/tim_penerimaan_bahan_baku_model.dart';
import '../repository/penerimaan_bahan_baku_repository.dart';
import '../widgets/penerimaan_bahan_baku_pallet_form_dialog.dart';

/// Layar input pallet/sak — mengikuti pola `WashingProductionInputScreen`,
/// TAPI hanya sisi OUTPUT (menciptakan label baru), tanpa sisi input (scan
/// label existing) karena Penerimaan Bahan Baku memang selalu menciptakan
/// label baru dari nol (struktur tabelnya sama seperti `label/bahan-baku`:
/// header `BahanBaku_h`, pallet `BahanBakuPallet_h`, detail sak
/// `BahanBaku_d`). Dialog header (`PenerimaanBahanBakuCreateDialog`) sudah
/// membuat NoPenerimaan di database (fase 1) sebelum screen ini dibuka;
/// screen PENUH ini adalah fase 2, tempat label/pallet SUNGGUHAN ditambahkan
/// — tiap pallet diinput lewat dialog `PenerimaanBahanBakuPalletFormDialog`
/// (format sama seperti "Tambah Label Washing"), lalu tampil sebagai kartu
/// dalam grid per section — sebelum akhirnya dikirim ke server.
///
/// Screen ini menampung DUA section: "Bahan Baku Pakai" dan "Bahan Baku
/// Proses" (menu PBB Pakai & PBB Proses sudah digabung jadi satu menu —
/// kategori kini dipilih di level section, bukan level menu/screen lagi).
/// Supplier & No Plat BUKAN atribut tim, jadi diinput per section — Pakai
/// dan Proses bisa datang dari supplier/truk yang berbeda.
///
/// Backend `POST /api/penerimaan-bahan-baku/:noPenerimaan/pallets` mewajibkan
/// SATU `kodeKategori` per request (lihat
/// `PenerimaanBahanBakuRepository.addPallets`), jadi saat SIMPAN PENERIMAAN,
/// tiap section yang terisi dikirim sebagai satu request `addPallets()`
/// (berisi SEMUA pallet yang sudah ditambah di section itu) — tapi SEMUA
/// request memakai NoPenerimaan yang SAMA (dibuat sekali di dialog header).
class PenerimaanBahanBakuInputScreen extends StatefulWidget {
  final TimPenerimaanInfo tim;
  final PenerimaanBahanBakuHeaderResult header;

  const PenerimaanBahanBakuInputScreen({
    super.key,
    required this.tim,
    required this.header,
  });

  @override
  State<PenerimaanBahanBakuInputScreen> createState() =>
      _PenerimaanBahanBakuInputScreenState();
}

class _PenerimaanBahanBakuInputScreenState
    extends State<PenerimaanBahanBakuInputScreen> {
  late final PenerimaanBahanBakuRepository _repo;

  final List<PenerimaanBahanBakuPalletDraft> _palletsPakai = [];
  final List<PenerimaanBahanBakuPalletDraft> _palletsProses = [];
  int? _pakaiSupplierId;
  int? _prosesSupplierId;
  final _pakaiNoPlatCtrl = TextEditingController();
  final _prosesNoPlatCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repo = PenerimaanBahanBakuRepository(api: context.read<ApiClient>());
  }

  @override
  void dispose() {
    _pakaiNoPlatCtrl.dispose();
    _prosesNoPlatCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPalletDialog({
    required String kategoriTitle,
    required Color accentColor,
    required List<PenerimaanBahanBakuPalletDraft> pallets,
  }) async {
    final draft = await showDialog<PenerimaanBahanBakuPalletDraft>(
      context: context,
      builder: (_) => PenerimaanBahanBakuPalletFormDialog(
        kategoriTitle: kategoriTitle,
        accentColor: accentColor,
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => pallets.add(draft));
  }

  void _removePallet(List<PenerimaanBahanBakuPalletDraft> pallets, int index) {
    setState(() => pallets.removeAt(index));
  }

  Future<void> _submit() async {
    if (_palletsPakai.isEmpty && _palletsProses.isEmpty) {
      _snack('Minimal 1 pallet wajib diisi (Bahan Baku Pakai atau Proses)');
      return;
    }
    if (_palletsPakai.isNotEmpty && _pakaiSupplierId == null) {
      _snack('Supplier Bahan Baku Pakai wajib dipilih');
      return;
    }
    if (_palletsProses.isNotEmpty && _prosesSupplierId == null) {
      _snack('Supplier Bahan Baku Proses wajib dipilih');
      return;
    }

    setState(() => _isSaving = true);
    final savedSections = <String>[];
    try {
      if (_palletsPakai.isNotEmpty) {
        await _repo.addPallets(
          noPenerimaan: widget.header.noPenerimaan,
          idSupplier: _pakaiSupplierId!,
          noPlat: _pakaiNoPlatCtrl.text,
          kodeKategori: PenerimaanKategori.pakai.kodeKategori,
          pallets: _palletsPakai.map((p) => p.toPalletInput()).toList(),
        );
        savedSections.add('Bahan Baku Pakai');
      }
      if (_palletsProses.isNotEmpty) {
        await _repo.addPallets(
          noPenerimaan: widget.header.noPenerimaan,
          idSupplier: _prosesSupplierId!,
          noPlat: _prosesNoPlatCtrl.text,
          kodeKategori: PenerimaanKategori.proses.kodeKategori,
          pallets: _palletsProses.map((p) => p.toPalletInput()).toList(),
        );
        savedSections.add('Bahan Baku Proses');
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Menyimpan',
          message:
              'Penerimaan ${widget.header.noPenerimaan} (${savedSections.join(' & ')}) berhasil disimpan.',
        ),
      );
      if (mounted) Navigator.of(context).pop(widget.header.noPenerimaan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final savedInfo = savedSections.isNotEmpty
          ? ' (Sudah tersimpan sebagian: ${savedSections.join(', ')})'
          : '';
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorStatusDialog(
          title: 'Gagal Menyimpan',
          message: '${e.toString()}$savedInfo',
        ),
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtBerat(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${widget.tim.namaTim} — Penerimaan Bahan Baku'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderInfoCard(),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Bahan Baku Pakai',
            color: const Color(0xFF00695C),
            pallets: _palletsPakai,
            selectedSupplierId: _pakaiSupplierId,
            onSupplierChanged: (id) => setState(() => _pakaiSupplierId = id),
            noPlatCtrl: _pakaiNoPlatCtrl,
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Bahan Baku Proses',
            color: const Color(0xFF0D47A1),
            pallets: _palletsProses,
            selectedSupplierId: _prosesSupplierId,
            onSupplierChanged: (id) => setState(() => _prosesSupplierId = id),
            noPlatCtrl: _prosesNoPlatCtrl,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
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
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required Color color,
    required List<PenerimaanBahanBakuPalletDraft> pallets,
    required int? selectedSupplierId,
    required ValueChanged<int?> onSupplierChanged,
    required TextEditingController noPlatCtrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.category_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SupplierDropdown(
          onChanged: (s) => onSupplierChanged(s?.idSupplier),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: noPlatCtrl,
          decoration: InputDecoration(
            labelText: 'No Plat',
            hintText: 'Opsional',
            prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        if (pallets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Belum ada label', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
              itemCount: pallets.length,
              itemBuilder: (_, i) => _buildPalletTile(pallets, i, color),
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _openPalletDialog(
            kategoriTitle: title,
            accentColor: color,
            pallets: pallets,
          ),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Label'),
        ),
      ],
    );
  }

  Widget _buildPalletTile(
    List<PenerimaanBahanBakuPalletDraft> pallets,
    int index,
    Color color,
  ) {
    final p = pallets[index];
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
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.jenisPlastik.jenis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                if (p.warehouse != null)
                  Text(
                    p.warehouse!.namaWarehouse,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  '${p.jumlahSak} sak · ${_fmtBerat(p.totalBerat)} kg',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removePallet(pallets, index),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: const Color(0xFFDC2626),
            tooltip: 'Hapus Label',
          ),
        ],
      ),
    );
  }
}
