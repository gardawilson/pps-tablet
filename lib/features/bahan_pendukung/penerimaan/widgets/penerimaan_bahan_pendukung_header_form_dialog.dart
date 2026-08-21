// lib/features/bahan_pendukung/penerimaan/widgets/penerimaan_bahan_pendukung_header_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../operator/model/operator_model.dart';
import '../../../production/shared/widgets/operator_picker.dart';
import '../../../shared/shift/widgets/shift_dropdown.dart';
import '../../../shift/repository/shift_repository.dart';
import '../../../production/shared/widgets/time_form_field.dart';
import '../model/tim_penerimaan_model.dart';
import '../repository/penerimaan_bahan_pendukung_repository.dart';

/// Dialog header — format sama seperti dialog header Penerimaan Bahan Baku
/// (`PenerimaanBahanBakuCreateDialog`): judul + form ringkas + baris aksi
/// BATAL/SIMPAN. Menampung field yang melekat pada tim penerimaan: Tanggal,
/// Shift, Jam Mulai, Jam Selesai, serta (multi) Operator. Tim sudah
/// diketahui dari kartu yang di-tap; Regu tidak dipakai (redundan dengan
/// Tim). Tombol SIMPAN langsung hit
/// `PenerimaanBahanPendukungRepository.createHeader` (fase 1) sehingga
/// NoPenerimaan sudah dibuat di database begitu dialog ini ditutup dengan
/// sukses; barang baru ditambahkan belakangan di screen input penuh
/// (fase 2).
class PenerimaanBahanPendukungCreateDialog extends StatefulWidget {
  final TimPenerimaanInfo tim;

  const PenerimaanBahanPendukungCreateDialog({super.key, required this.tim});

  @override
  State<PenerimaanBahanPendukungCreateDialog> createState() =>
      _PenerimaanBahanPendukungCreateDialogState();
}

class _PenerimaanBahanPendukungCreateDialogState
    extends State<PenerimaanBahanPendukungCreateDialog> {
  late final PenerimaanBahanPendukungRepository _repo;

  late final TextEditingController _tanggalCtrl;
  late final TextEditingController _hourStartCtrl;
  late final TextEditingController _hourEndCtrl;
  DateTime _tanggal = DateTime.now();
  int? _selectedShift;
  final List<MstOperator> _selectedOperators = [];
  bool _loadingOperator = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repo = PenerimaanBahanPendukungRepository(api: context.read<ApiClient>());
    _tanggalCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_tanggal),
    );
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
    _tanggalCtrl.dispose();
    _hourStartCtrl.dispose();
    _hourEndCtrl.dispose();
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
    if (picked == null || !mounted) return;
    setState(() {
      _tanggal = picked;
      _tanggalCtrl.text = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(picked);
    });
  }

  Future<void> _openOperatorPicker() async {
    if (!mounted) return;
    setState(() => _loadingOperator = true);
    final result = await showOperatorPicker(
      context,
      initialSelected: _selectedOperators,
    );
    if (mounted) setState(() => _loadingOperator = false);
    if (result != null && mounted) {
      setState(() {
        _selectedOperators
          ..clear()
          ..addAll(result);
      });
    }
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
    if (_selectedOperators.isEmpty) {
      _snack('Minimal 1 operator wajib dipilih');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _repo.createHeader(
        tglPenerimaan: _tanggal,
        idTim: widget.tim.idTim,
        shift: _selectedShift!,
        hourStart: hourStart,
        hourEnd: hourEnd,
        idOperators: _selectedOperators.map((o) => o.idOperator).toList(),
        namaOperators: _selectedOperators.map((o) => o.namaOperator).join(', '),
      );
      if (mounted) Navigator.of(context).pop(result);
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
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: isLandscape
          ? const EdgeInsets.symmetric(horizontal: 72, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 620 : 560,
          maxHeight: (mq.size.height - 24).clamp(260, isLandscape ? 480 : 560),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: _buildForm(),
                ),
              ),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: Colors.teal.shade700, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${widget.tim.namaTim} — Penerimaan Bahan Pendukung',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _tanggalCtrl,
          readOnly: true,
          onTap: _pickTanggal,
          decoration: InputDecoration(
            labelText: 'Tanggal',
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        const SizedBox(height: 16),

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

        const SizedBox(height: 16),

        OperatorPickerField(
          selectedOperators: _selectedOperators,
          isLoading: _loadingOperator,
          onTap: _openOperatorPicker,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: Text(
            _isSaving ? 'MENYIMPAN...' : 'SIMPAN',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
