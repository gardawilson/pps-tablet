import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/mesin/widgets/mesin_dropdown.dart';
import 'package:pps_tablet/features/operator/model/operator_model.dart';
import 'package:pps_tablet/features/production/shared/widgets/total_hours_pill.dart';

import '../../../../common/widgets/app_number_field.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../mesin/model/mesin_model.dart';
import '../../../operator/widgets/operator_dropdown.dart';
import '../../../shared/overlap/repository/overlap_repository.dart';
import '../../../shared/overlap/view_model/overlap_view_model.dart';
import '../../../shared/shift/widgets/shift_dropdown.dart';
import '../../shared/widgets/time_form_field.dart';
import '../model/crusher_production_model.dart';
import '../view_model/crusher_production_view_model.dart';
import 'crusher_text_field.dart'; // TODO: Buat widgets ini (copy dari reject_text_field.dart)
import '../../../../core/utils/date_formatter.dart';
import '../../../../common/widgets/app_date_field.dart';

class CrusherProductionFormDialog extends StatefulWidget {
  final CrusherProduction? header;
  final Function(CrusherProduction)? onSave;

  const CrusherProductionFormDialog({
    super.key,
    this.header,
    this.onSave,
  });

  @override
  State<CrusherProductionFormDialog> createState() => _CrusherProductionFormDialogState();
}

class _CrusherProductionFormDialogState extends State<CrusherProductionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noCrusherProduksiCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController mesinCtrl;
  late final TextEditingController operatorCtrl;
  late final TextEditingController jamKerjaCtrl;
  late final TextEditingController jlhAnggotaCtrl;
  late final TextEditingController hadirCtrl;
  late final TextEditingController hourMeterCtrl;

  // State
  MstMesin? _selectedMesin;
  MstOperator? _selectedOperator;
  int? _selectedShift;

  // hold the preselect id for operator (from mesin.defaultOperatorId)
  int? _operatorPreselectId;

  DateTime _selectedDate = DateTime.now();

  // --- time controllers ---
  late final TextEditingController hourStartCtrl;
  late final TextEditingController hourEndCtrl;

  // --- time state ---
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool get isEdit => widget.header != null;

  // kind untuk endpoint overlap (dialog ini crusher)
  static const String _kind = 'crusher';

  @override
  void initState() {
    super.initState();
    noCrusherProduksiCtrl = TextEditingController(
      text: widget.header?.noCrusherProduksi ?? '',
    );

    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.tanggal) ?? DateTime.now())
        : DateTime.now();

    _selectedDate = seededDate;
    dateCreatedCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    mesinCtrl = TextEditingController(text: widget.header?.namaMesin ?? '');
    operatorCtrl = TextEditingController(text: widget.header?.namaOperator ?? '');
    jamKerjaCtrl = TextEditingController(
      text: widget.header?.jamKerja.toString() ?? '',
    );
    jlhAnggotaCtrl = TextEditingController(
      text: widget.header?.jmlhAnggota?.toString() ?? '',
    );
    hadirCtrl = TextEditingController(
      text: widget.header?.hadir?.toString() ?? '',
    );
    hourMeterCtrl = TextEditingController(
      text: widget.header?.hourMeter?.toString() ?? '',
    );

    hourStartCtrl = TextEditingController(text: widget.header?.hourStart);
    hourEndCtrl = TextEditingController(text: widget.header?.hourEnd);

    // Seed shift saat edit
    if (widget.header != null) {
      _selectedShift = widget.header!.shift;
    }
  }

  @override
  void dispose() {
    noCrusherProduksiCtrl.dispose();
    dateCreatedCtrl.dispose();
    jamKerjaCtrl.dispose();
    hourStartCtrl.dispose();
    hourEndCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // cek overlap dulu
    final ovm = context.read<OverlapViewModel>();
    if (ovm.hasOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa simpan, ada overlap jam di mesin ini')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // pastikan ada mesin & operator & shift
    final mesinId = _selectedMesin?.idMesin ?? widget.header?.idMesin;
    if (mesinId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesin wajib dipilih')),
      );
      return;
    }

    final operatorId = _selectedOperator?.idOperator
        ?? _operatorPreselectId
        ?? widget.header?.idOperator;
    if (operatorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operator wajib dipilih')),
      );
      return;
    }

    if (_selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift wajib dipilih')),
      );
      return;
    }

    // validasi hourStart & hourEnd
    if (hourStartCtrl.text.trim().isEmpty || hourEndCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam mulai & selesai wajib diisi')),
      );
      return;
    }

    // helper HH:mm -> HH:mm:00
    String _toSqlTime(String raw) {
      final t = raw.trim();
      if (t.isEmpty) return t;
      return t.length == 5 ? '$t:00' : t;
    }

    final hourStartSql = _toSqlTime(hourStartCtrl.text);
    final hourEndSql = _toSqlTime(hourEndCtrl.text);

    // parse angka
    final jlhAnggota = int.tryParse(jlhAnggotaCtrl.text.trim());
    final hadir = int.tryParse(hadirCtrl.text.trim());
    final hourMeter = double.tryParse(hourMeterCtrl.text.trim());

    final prodVm = context.read<CrusherProductionViewModel>();

    // show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    CrusherProduction? result;

    try {
      if (isEdit) {
        // 🔁 UPDATE
        result = await prodVm.updateProduksi(
          noCrusherProduksi: widget.header!.noCrusherProduksi,
          tanggal: _selectedDate,
          idMesin: mesinId,
          idOperator: operatorId,
          shift: _selectedShift!,
          hourStart: hourStartSql,
          hourEnd: hourEndSql,
          jmlhAnggota: jlhAnggota,
          hadir: hadir,
          hourMeter: hourMeter,
        );
      } else {
        // 🆕 CREATE
        result = await prodVm.createProduksi(
          tanggal: _selectedDate,
          idMesin: mesinId,
          idOperator: operatorId,
          jamKerja: 0,
          shift: _selectedShift!,
          hourStart: hourStartSql,
          hourEnd: hourEndSql,
          jmlhAnggota: jlhAnggota,
          hadir: hadir,
          hourMeter: hourMeter,
        );
      }
    } finally {
      // pop loading
      Navigator.of(context).pop();
    }

    if (result != null) {
      widget.onSave?.call(result);
      Navigator.of(context).pop(); // tutup dialog form
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prodVm.saveError ?? 'Gagal menyimpan data')),
      );
    }
  }

  /// Panggil cek-overlap via ViewModel hanya jika input sudah lengkap:
  /// - Jam Mulai & Jam Selesai terisi
  /// - IdMesin tersedia
  Future<void> _checkOverlapIfReadyVM() async {
    final vm = context.read<OverlapViewModel>();

    final start = hourStartCtrl.text.trim();
    final end = hourEndCtrl.text.trim();
    final idMesin = _selectedMesin?.idMesin ?? widget.header?.idMesin;

    if (start.isEmpty || end.isEmpty || idMesin == null) {
      vm.clear();
      return;
    }

    await vm.check(
      kind: _kind,
      date: _selectedDate,
      idMesin: idMesin,
      hourStart: start,
      hourEnd: end,
      excludeNo: isEdit ? widget.header!.noCrusherProduksi : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OverlapViewModel(repository: OverlapRepository()),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _buildLeftColumn()),
                  ],
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEdit ? Colors.orange.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isEdit ? Icons.edit : Icons.add,
            color: isEdit ? Colors.orange.shade700 : Colors.green.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEdit ? 'Edit Crusher Produksi' : 'Tambah Crusher Produksi',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    final vm = context.watch<OverlapViewModel>();
    // durasi lokal
    final dur = durationBetweenHHmmWrap(hourStartCtrl.text, hourEndCtrl.text);
    final startFilled = hourStartCtrl.text.trim().isNotEmpty;
    final endFilled = hourEndCtrl.text.trim().isNotEmpty;
    final hasDurationError = startFilled && endFilled && dur == null;

    // overlap dari server
    final hasOverlap = vm.hasOverlap;
    final overlapMsg = vm.overlapMessage ?? 'Jam ini bentrok dengan dokumen lain';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Header',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // No. Crusher Produksi (readonly, auto-generated)
              CrusherTextField(
                controller: noCrusherProduksiCtrl,
                label: 'No. Crusher Produksi',
                icon: Icons.label,
                asText: true, // readonly text (bold)
                placeholderText: 'G.XXXXXXXXXX', // ⬅️ tampil jika kosong
              ),

              const SizedBox(height: 16),

              // Tanggal
              AppDateField(
                controller: dateCreatedCtrl,
                label: 'Tanggal',
                format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
                initialDate: _selectedDate,
                onChanged: (d) async {
                  if (d != null) {
                    setState(() {
                      _selectedDate = d;
                      dateCreatedCtrl.text =
                          DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(d);
                    });
                    await _checkOverlapIfReadyVM();
                  }
                },
              ),

              const SizedBox(height: 16),

              // Mesin (Required)
              MesinDropdown(
                idBagianMesin: 3, // ⬅️ ganti sesuai ID bagian untuk crusher
                preselectId: widget.header?.idMesin,
                label: 'Mesin',
                hint: 'Pilih jenis mesin',
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => v == null ? 'Wajib pilih jenis mesin' : null,
                onChanged: (m) async {
                  _selectedMesin = m;
                  _operatorPreselectId = m?.defaultOperatorId;

                  setState(() {});
                  await _checkOverlapIfReadyVM();
                },
              ),

              const SizedBox(height: 16),

              // Operator (Required)
              OperatorDropdown(
                key: ValueKey(_operatorPreselectId ?? widget.header?.idOperator),
                preselectId: isEdit
                    ? widget.header?.idOperator
                    : _operatorPreselectId,
                label: 'Operator',
                hint: 'Pilih operator',
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => v == null ? 'Wajib pilih operator' : null,
                onChanged: (op) {
                  _selectedOperator = op;
                  setState(() {});
                },
              ),

              const SizedBox(height: 16),

              // Jam Mulai & Jam Selesai
              Row(
                children: [
                  Expanded(
                    child: TimeFormField(
                      controller: hourStartCtrl,
                      label: 'Jam Mulai',
                      hintText: 'HH:mm',
                      onPick: () async {
                        final picked = await pickTime24h(context, initial: _startTime);
                        if (picked != null) {
                          setState(() {
                            _startTime = picked;
                            hourStartCtrl.text = formatHHmm(picked);
                          });
                          await _checkOverlapIfReadyVM();
                        }
                      },
                      validator: (_) {
                        final s = parseHHmm(hourStartCtrl.text);
                        if (s == null) return 'Wajib isi jam mulai (HH:mm)';
                        final diff = durationBetweenHHmmWrap(
                            hourStartCtrl.text, hourEndCtrl.text);
                        if (diff == null && parseHHmm(hourEndCtrl.text) != null) {
                          return 'Durasi tidak boleh 0 menit';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TimeFormField(
                      controller: hourEndCtrl,
                      label: 'Jam Selesai',
                      hintText: 'HH:mm',
                      onPick: () async {
                        final picked = await pickTime24h(
                            context, initial: _endTime ?? _startTime);
                        if (picked != null) {
                          setState(() {
                            _endTime = picked;
                            hourEndCtrl.text = formatHHmm(picked);
                          });
                          await _checkOverlapIfReadyVM();
                        }
                      },
                      validator: (_) {
                        final e = parseHHmm(hourEndCtrl.text);
                        if (e == null) return 'Wajib isi jam selesai (HH:mm)';
                        final s = parseHHmm(hourStartCtrl.text);
                        if (s != null) {
                          final diff = durationBetweenHHmmWrap(
                              hourStartCtrl.text, hourEndCtrl.text);
                          if (diff == null) return 'Durasi tidak boleh 0 menit';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  TotalHoursPill(
                    duration: dur,
                    isError: hasOverlap || hasDurationError,
                    errorText: hasOverlap
                        ? overlapMsg
                        : 'Durasi tidak boleh 0 menit',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Shift, Jam Kerja, Hour Meter
              Row(
                children: [
                  Expanded(
                    child: ShiftDropdown(
                      preselectId: widget.header?.shift,
                      onChangedId: (id) {
                        setState(() {
                          _selectedShift = id;
                        });
                      },
                      validator: (v) => v == null ? 'Wajib pilih shift' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppNumberField(
                      controller: hourMeterCtrl,
                      label: 'Hour Meter',
                      icon: Icons.timer_sharp,
                      allowDecimal: true,
                      allowNegative: false,
                      hintText: '0',
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Jumlah Anggota & Hadir
              Row(
                children: [
                  Expanded(
                    child: AppNumberField(
                      controller: jlhAnggotaCtrl,
                      label: 'Jumlah Anggota',
                      icon: Icons.people,
                      allowDecimal: false,
                      allowNegative: false,
                      hintText: '0',
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppNumberField(
                      controller: hadirCtrl,
                      label: 'Hadir',
                      icon: Icons.people,
                      allowDecimal: false,
                      allowNegative: false,
                      hintText: '0',
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final vm = context.watch<OverlapViewModel>();
    final hasOverlap = vm.hasOverlap;

    final prodVm = context.watch<CrusherProductionViewModel>();
    final isSaving = prodVm.isSaving;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: (hasOverlap || isSaving) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isEdit ? const Color(0xFFF57C00) : const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: Text(
            isSaving ? 'MENYIMPAN...' : 'SIMPAN',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}