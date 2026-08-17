// lib/features/production/penerimaan_bahan_baku/view/penerimaan_bahan_baku_create_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../shared/plastic_type/jenis_plastik_dropdown.dart';
import '../../../shared/plastic_type/jenis_plastik_model.dart';
import '../../../shared/shift/widgets/shift_dropdown.dart';
import '../../../shift/repository/shift_repository.dart';
import '../../../supplier/widgets/supplier_dropdown.dart';
import '../../../warehouse/model/warehouse_model.dart';
import '../../../warehouse/widgets/warehouse_dropdown.dart';
import '../../shared/widgets/time_form_field.dart';
import '../model/penerimaan_kategori.dart';
import '../model/tim_penerimaan_bahan_baku_model.dart';
import '../repository/penerimaan_bahan_baku_repository.dart';

/// Layar create — format header sama seperti produksi washing (Tim, Shift,
/// Jam Mulai/Selesai), tapi payload dikirim SATU request atomic (header +
/// semua pallet + semua sak) ke `POST /api/penerimaan-bahan-baku`, mengikuti
/// kontrak backend yang sudah ada (bukan alur bertahap per-pallet/per-sak).
class PenerimaanBahanBakuCreateScreen extends StatefulWidget {
  final TimPenerimaanInfo tim;
  final PenerimaanKategori kategori;

  const PenerimaanBahanBakuCreateScreen({
    super.key,
    required this.tim,
    required this.kategori,
  });

  @override
  State<PenerimaanBahanBakuCreateScreen> createState() =>
      _PenerimaanBahanBakuCreateScreenState();
}

class _SakForm {
  final TextEditingController noSakCtrl;
  final TextEditingController beratCtrl;
  _SakForm({required int noSak})
    : noSakCtrl = TextEditingController(text: '$noSak'),
      beratCtrl = TextEditingController();

  void dispose() {
    noSakCtrl.dispose();
    beratCtrl.dispose();
  }
}

class _PalletForm {
  JenisPlastik? jenisPlastik;
  MstWarehouse? warehouse;
  final TextEditingController keteranganCtrl = TextEditingController();
  final List<_SakForm> saks = [];

  _PalletForm() {
    saks.add(_SakForm(noSak: 1));
  }

  void addSak() => saks.add(_SakForm(noSak: saks.length + 1));

  void dispose() {
    keteranganCtrl.dispose();
    for (final s in saks) {
      s.dispose();
    }
  }
}

class _PenerimaanBahanBakuCreateScreenState
    extends State<PenerimaanBahanBakuCreateScreen> {
  late final PenerimaanBahanBakuRepository _repo;

  final _noPlatCtrl = TextEditingController();
  late final TextEditingController _hourStartCtrl;
  late final TextEditingController _hourEndCtrl;
  DateTime _tanggal = DateTime.now();
  int? _selectedShift;
  int? _selectedSupplierId;
  final List<_PalletForm> _pallets = [_PalletForm()];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repo = PenerimaanBahanBakuRepository(api: context.read<ApiClient>());
    _hourStartCtrl = TextEditingController();
    _hourEndCtrl = TextEditingController();
    _prefillCurrentShift();
  }

  Future<void> _prefillCurrentShift() async {
    final shift = await ShiftRepository.fetchCurrentShift();
    if (!mounted || shift == null) return;
    setState(() {
      _selectedShift = shift.shift;
      _hourStartCtrl.text = shift.hourStart;
      _hourEndCtrl.text = shift.hourEnd;
    });
  }

  @override
  void dispose() {
    _noPlatCtrl.dispose();
    _hourStartCtrl.dispose();
    _hourEndCtrl.dispose();
    for (final p in _pallets) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  void _addPallet() => setState(() => _pallets.add(_PalletForm()));

  void _removePallet(int index) {
    setState(() {
      _pallets[index].dispose();
      _pallets.removeAt(index);
    });
  }

  void _addSak(int palletIndex) => setState(() => _pallets[palletIndex].addSak());

  void _removeSak(int palletIndex, int sakIndex) {
    setState(() {
      _pallets[palletIndex].saks[sakIndex].dispose();
      _pallets[palletIndex].saks.removeAt(sakIndex);
    });
  }

  Future<void> _submit() async {
    if (_selectedShift == null) {
      _snack('Shift wajib dipilih');
      return;
    }
    final hourStart = _hourStartCtrl.text.trim();
    final hourEnd = _hourEndCtrl.text.trim();
    if (parseHHmm(hourStart) == null || parseHHmm(hourEnd) == null) {
      _snack('Jam mulai & selesai wajib diisi (HH:mm)');
      return;
    }
    if (_selectedSupplierId == null) {
      _snack('Supplier wajib dipilih');
      return;
    }
    if (_pallets.isEmpty) {
      _snack('Minimal 1 pallet wajib diisi');
      return;
    }

    final pallets = <PenerimaanPalletInput>[];
    for (var i = 0; i < _pallets.length; i++) {
      final p = _pallets[i];
      if (p.jenisPlastik == null) {
        _snack('Jenis plastik pallet #${i + 1} wajib dipilih');
        return;
      }
      if (p.saks.isEmpty) {
        _snack('Pallet #${i + 1} wajib punya minimal 1 sak');
        return;
      }

      final saks = <PenerimaanSakInput>[];
      for (var j = 0; j < p.saks.length; j++) {
        final s = p.saks[j];
        final noSak = int.tryParse(s.noSakCtrl.text.trim());
        final berat = double.tryParse(s.beratCtrl.text.trim().replaceAll(',', '.'));
        if (noSak == null || noSak <= 0) {
          _snack('No Sak pada pallet #${i + 1} sak #${j + 1} tidak valid');
          return;
        }
        if (berat == null || berat <= 0) {
          _snack('Berat pada pallet #${i + 1} sak #${j + 1} tidak valid');
          return;
        }
        saks.add(PenerimaanSakInput(noSak: noSak, berat: berat));
      }

      pallets.add(
        PenerimaanPalletInput(
          idJenisPlastik: p.jenisPlastik!.idJenisPlastik,
          idWarehouse: p.warehouse?.idWarehouse,
          keterangan: p.keteranganCtrl.text,
          saks: saks,
        ),
      );
    }

    setState(() => _isSaving = true);
    try {
      final noPenerimaan = await _repo.create(
        tglPenerimaan: _tanggal,
        idTim: widget.tim.idTim,
        idSupplier: _selectedSupplierId!,
        noPlat: _noPlatCtrl.text,
        shift: _selectedShift!,
        hourStart: hourStart,
        hourEnd: hourEnd,
        kodeKategori: widget.kategori.kodeKategori,
        pallets: pallets,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Menyimpan',
          message: 'Penerimaan $noPenerimaan berhasil disimpan.',
        ),
      );
      if (mounted) Navigator.of(context).pop(noPenerimaan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorStatusDialog(title: 'Gagal Menyimpan', message: e.toString()),
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${widget.kategori.title} — ${widget.tim.namaTim}'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          for (var i = 0; i < _pallets.length; i++) ...[
            _buildPalletCard(i),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _addPallet,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Pallet'),
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

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DATA PENERIMAAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  onTap: _pickTanggal,
                  controller: TextEditingController(
                    text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_tanggal),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: widget.tim.namaTim,
                  decoration: InputDecoration(
                    labelText: 'Tim',
                    prefixIcon: const Icon(Icons.groups_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: ShiftDropdown(
                  preselectId: _selectedShift,
                  onChangedId: (id) => setState(() => _selectedShift = id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TimeFormField(
                  controller: _hourStartCtrl,
                  label: 'Jam Mulai',
                  hintText: 'HH:mm',
                  onPick: () async {
                    final picked = await pickTime24h(context, initial: parseHHmm(_hourStartCtrl.text));
                    if (picked != null) setState(() => _hourStartCtrl.text = formatHHmm(picked));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TimeFormField(
                  controller: _hourEndCtrl,
                  label: 'Jam Selesai',
                  hintText: 'HH:mm',
                  onPick: () async {
                    final picked = await pickTime24h(context, initial: parseHHmm(_hourEndCtrl.text));
                    if (picked != null) setState(() => _hourEndCtrl.text = formatHHmm(picked));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SupplierDropdown(
            onChanged: (s) => setState(() => _selectedSupplierId = s?.idSupplier),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noPlatCtrl,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.category_outlined, size: 18, color: Color(0xFF00695C)),
                const SizedBox(width: 8),
                Text(
                  'Kategori: ${widget.kategori.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00695C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalletCard(int palletIndex) {
    final p = _pallets[palletIndex];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PALLET #${palletIndex + 1}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (_pallets.length > 1)
                IconButton(
                  onPressed: () => _removePallet(palletIndex),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: const Color(0xFFDC2626),
                  tooltip: 'Hapus Pallet',
                ),
            ],
          ),
          const SizedBox(height: 8),
          JenisPlastikDropdown(
            onChanged: (jp) => setState(() => p.jenisPlastik = jp),
          ),
          const SizedBox(height: 12),
          WarehouseDropdown(
            onChanged: (w) => setState(() => p.warehouse = w),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: p.keteranganCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Keterangan',
              hintText: 'Opsional',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 4),
          const Text('DETAIL SAK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (var j = 0; j < p.saks.length; j++) ...[
            _buildSakRow(palletIndex, j),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addSak(palletIndex),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Sak'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSakRow(int palletIndex, int sakIndex) {
    final s = _pallets[palletIndex].saks[sakIndex];
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: TextFormField(
            controller: s.noSakCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'No Sak',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: s.beratCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: 'Berat (kg)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
        if (_pallets[palletIndex].saks.length > 1)
          IconButton(
            onPressed: () => _removeSak(palletIndex, sakIndex),
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey.shade600,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }
}
