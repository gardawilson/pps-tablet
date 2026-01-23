// lib/features/production/inject/widgets/inject_production_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/app_date_field.dart';
import '../../../../common/widgets/app_number_field.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/time_formatter.dart';

import '../../../cetakan/model/mst_cetakan_model.dart';
import '../../../cetakan/repository/cetakan_repository.dart';
import '../../../cetakan/view_model/cetakan_view_model.dart';
import '../../../cetakan/widgets/cetakan_dropdown.dart';

import '../../../furniture_material/model/furniture_material_lookup_model.dart';
import '../../../furniture_material/widgets/furniture_material_dropdown.dart';

import '../../../warna/model/warna_model.dart';
import '../../../warna/repository/warna_repository.dart';
import '../../../warna/view_model/warna_view_model.dart';
import '../../../warna/widgets/warna_dropdown.dart';

import '../../../furniture_material/repository/furniture_material_lookup_repository.dart';
import '../../../furniture_material/view_model/furniture_material_lookup_view_model.dart';

import '../../../mesin/widgets/mesin_dropdown.dart';
import '../../../mesin/model/mesin_model.dart';

import '../../../operator/widgets/operator_dropdown.dart';
import '../../../operator/model/operator_model.dart';

import '../../../shared/shift/widgets/shift_dropdown.dart';
import '../../../production/shared/widgets/total_hours_pill.dart';
import '../../../production/shared/widgets/time_form_field.dart';

import '../../../shared/overlap/repository/overlap_repository.dart';
import '../../../shared/overlap/view_model/overlap_view_model.dart';

import '../model/inject_production_model.dart';
import '../view_model/inject_production_view_model.dart';

class InjectProductionFormDialog extends StatefulWidget {
  final InjectProduction? header;
  final Function(InjectProduction)? onSave;

  const InjectProductionFormDialog({
    super.key,
    this.header,
    this.onSave,
  });

  @override
  State<InjectProductionFormDialog> createState() =>
      _InjectProductionFormDialogState();
}

class _InjectProductionFormDialogState
    extends State<InjectProductionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noProduction;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController mesinCtrl;
  late final TextEditingController operatorCtrl;
  late final TextEditingController jamCtrl; // ✅ Jam field
  late final TextEditingController hourMeterCtrl;
  late final TextEditingController beratProdukHasilTimbangCtrl;

  // keep only for payload
  late final TextEditingController idFurnitureMaterialCtrl;

  // State
  MstMesin? _selectedMesin;
  MstOperator? _selectedOperator;
  int? _selectedShift;

  int? _operatorPreselectId;

  DateTime _selectedDate = DateTime.now();

  // --- time controllers ---
  late final TextEditingController hourStartCtrl;
  late final TextEditingController hourEndCtrl;

  // --- time state ---
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool get isEdit => widget.header != null;

  // kind untuk endpoint overlap (dialog ini INJECT)
  static const String _kind = 'inject';

  // dropdown selections
  MstCetakan? _selectedCetakan;
  MstWarna? _selectedWarna;

  FurnitureMaterialLookupResult? _selectedFurnitureMaterial;

  // ✅ placeholder karena model tidak support null id
  static const int _noneFurnitureId = 0;
  static const FurnitureMaterialLookupResult _noneFurnitureMaterial =
  FurnitureMaterialLookupResult(
    idFurnitureMaterial: _noneFurnitureId,
    nama: 'Tidak ada Furniture Material',
    itemCode: null,
    enable: false,
  );

  @override
  void initState() {
    super.initState();
    noProduction = TextEditingController(text: widget.header?.noProduksi ?? '');

    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.tglProduksi) ?? DateTime.now())
        : DateTime.now();

    _selectedDate = seededDate;
    dateCreatedCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    mesinCtrl = TextEditingController(text: widget.header?.namaMesin ?? '');
    operatorCtrl =
        TextEditingController(text: widget.header?.namaOperator ?? '');

    // ✅ Initialize jam field
    jamCtrl = TextEditingController(
      text: widget.header?.jam?.toString() ?? '',
    );

    hourMeterCtrl = TextEditingController(
      text: widget.header?.hourMeter?.toString() ?? '',
    );
    beratProdukHasilTimbangCtrl = TextEditingController(
      text: widget.header?.beratProdukHasilTimbang?.toString() ?? '',
    );

    hourStartCtrl = TextEditingController(text: widget.header?.hourStart ?? '');
    hourEndCtrl = TextEditingController(text: widget.header?.hourEnd ?? '');

    idFurnitureMaterialCtrl = TextEditingController(
      text: widget.header?.idFurnitureMaterial?.toString() ?? '',
    );

    // default placeholder (akan diganti kalau resolve menemukan data)
    _selectedFurnitureMaterial = _noneFurnitureMaterial;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resolveFurnitureMaterialIfReady();
    });
  }

  @override
  void dispose() {
    noProduction.dispose();
    dateCreatedCtrl.dispose();
    mesinCtrl.dispose();
    operatorCtrl.dispose();
    jamCtrl.dispose(); // ✅ Dispose jam controller
    hourMeterCtrl.dispose();
    beratProdukHasilTimbangCtrl.dispose();
    hourStartCtrl.dispose();
    hourEndCtrl.dispose();
    idFurnitureMaterialCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    debugPrint('📝 [INJECT_FORM] _submit() started');

    // cek overlap dulu
    final ovm = context.read<OverlapViewModel>();
    if (ovm.hasOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa simpan, ada overlap jam di mesin ini'),
        ),
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

    final operatorId = _selectedOperator?.idOperator ??
        _operatorPreselectId ??
        widget.header?.idOperator;
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

    // ✅ Parse jam field (can be int or computed from time range)
    int? jamKerja;

    // Try to get jam from direct input first
    if (jamCtrl.text.trim().isNotEmpty) {
      jamKerja = int.tryParse(jamCtrl.text.trim());
    }

    // If not set, calculate from hourStart and hourEnd
    if (jamKerja == null &&
        hourStartCtrl.text.trim().isNotEmpty &&
        hourEndCtrl.text.trim().isNotEmpty) {
      final duration = durationBetweenHHmmWrap(
        hourStartCtrl.text,
        hourEndCtrl.text,
      );
      if (duration != null) {
        jamKerja = duration.inHours;
      }
    }

    // Pastikan jam mulai & selesai terisi
    if (hourStartCtrl.text.trim().isEmpty || hourEndCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam mulai & selesai wajib diisi (HH:mm)'),
        ),
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
    final hourMeter = double.tryParse(hourMeterCtrl.text.trim());
    final beratProduk = double.tryParse(beratProdukHasilTimbangCtrl.text.trim());

    final idCetakan = _selectedCetakan?.idCetakan ?? widget.header?.idCetakan;
    final idWarna = _selectedWarna?.idWarna ?? widget.header?.idWarna;

    if (idCetakan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cetakan wajib dipilih')),
      );
      return;
    }
    if (idWarna == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warna wajib dipilih')),
      );
      return;
    }

    // ✅ convert placeholder -> null for payload
    final pickedId = int.tryParse(idFurnitureMaterialCtrl.text.trim());
    final int? idFurnitureMaterialPayload =
    (pickedId == null || pickedId == _noneFurnitureId) ? null : pickedId;

    // ✅ Read VM from PARENT Screen context
    final prodVm = context.read<InjectProductionViewModel>();
    debugPrint('📝 [INJECT_FORM] Got VM from context: VM hash=${prodVm.hashCode}');
    debugPrint(
      '📝 [INJECT_FORM] Got controller from VM: controller hash=${prodVm.pagingController.hashCode}',
    );

    // show loading
    debugPrint('📝 [INJECT_FORM] Showing loading dialog...');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    InjectProduction? result;

    try {
      if (isEdit) {
        debugPrint('📝 [INJECT_FORM] Calling updateProduksi...');
        result = await prodVm.updateProduksi(
          noProduksi: widget.header!.noProduksi,
          tglProduksi: _selectedDate,
          idMesin: mesinId,
          idOperator: operatorId,
          jam: jamKerja, // ✅ Send jam field
          shift: _selectedShift!,
          hourStart: hourStartSql,
          hourEnd: hourEndSql,
          hourMeter: hourMeter,
          beratProdukHasilTimbang: beratProduk,
          idCetakan: idCetakan,
          idWarna: idWarna,
          idFurnitureMaterial: idFurnitureMaterialPayload,
        );
        debugPrint(
          '📝 [INJECT_FORM] updateProduksi returned: ${result?.noProduksi}',
        );
      } else {
        debugPrint('📝 [INJECT_FORM] Calling createProduksi...');
        result = await prodVm.createProduksi(
          tglProduksi: _selectedDate,
          idMesin: mesinId,
          idOperator: operatorId,
          jam: jamKerja, // ✅ Send jam field
          shift: _selectedShift!,
          hourStart: hourStartSql,
          hourEnd: hourEndSql,
          hourMeter: hourMeter,
          beratProdukHasilTimbang: beratProduk,
          idCetakan: idCetakan,
          idWarna: idWarna,
          idFurnitureMaterial: idFurnitureMaterialPayload,
        );
        debugPrint(
          '📝 [INJECT_FORM] createProduksi returned: ${result?.noProduksi}',
        );
      }
    } catch (e) {
      debugPrint('❌ [INJECT_FORM] Exception during save: $e');
    } finally {
      debugPrint('📝 [INJECT_FORM] Popping loading dialog...');
      if (mounted) {
        Navigator.of(context).pop();
        debugPrint('📝 [INJECT_FORM] Loading dialog popped');
      }
    }

    if (!mounted) {
      debugPrint('📝 [INJECT_FORM] Widget not mounted after save, returning');
      return;
    }

    debugPrint('📝 [INJECT_FORM] Checking result: ${result?.noProduksi}');

    if (result != null) {
      debugPrint('📝 [INJECT_FORM] Success detected: ${result.noProduksi}');

      widget.onSave?.call(result);

      if (isEdit) {
        debugPrint('📝 [INJECT_FORM] Edit mode - closing with InjectProduction result');
        Navigator.of(context).pop(result);
        debugPrint('📝 [INJECT_FORM] Dialog popped with result');
      } else {
        debugPrint('📝 [INJECT_FORM] Create mode - closing with true');
        Navigator.of(context).pop(true);
        debugPrint('📝 [INJECT_FORM] Dialog popped with true');
      }
    } else {
      debugPrint('❌ [INJECT_FORM] Result is null, showing error');
      debugPrint('❌ [INJECT_FORM] Error message: ${prodVm.saveError}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prodVm.saveError ?? 'Gagal menyimpan data'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('❌ [INJECT_FORM] SnackBar shown, keeping dialog open');
    }

    debugPrint('📝 [INJECT_FORM] _submit() completed');
  }

  /// Panggil cek-overlap via ViewModel hanya jika input sudah lengkap
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
      excludeNo: isEdit ? widget.header!.noProduksi : null,
    );
  }

  /// ✅ Auto-calculate jam from time range
  void _updateJamFromTimeRange() {
    final start = hourStartCtrl.text.trim();
    final end = hourEndCtrl.text.trim();

    if (start.isEmpty || end.isEmpty) return;

    final duration = durationBetweenHHmmWrap(start, end);
    if (duration != null) {
      final hours = duration.inHours;
      setState(() {
        jamCtrl.text = hours.toString();
      });
    }
  }

  /// ✅ resolve from cetakan+warna
  /// rules:
  /// - if not ready => placeholder & disable later
  /// - if found null => placeholder (not error)
  Future<void> _resolveFurnitureMaterialIfReady() async {
    final idCetakan = _selectedCetakan?.idCetakan ?? widget.header?.idCetakan;
    final idWarna = _selectedWarna?.idWarna ?? widget.header?.idWarna;

    final lvm = context.read<FurnitureMaterialLookupViewModel>();

    if (idCetakan == null || idWarna == null) {
      lvm.clear();
      if (!mounted) return;
      setState(() => _selectedFurnitureMaterial = _noneFurnitureMaterial);
      idFurnitureMaterialCtrl.text = '';
      return;
    }

    await lvm.resolve(idCetakan: idCetakan, idWarna: idWarna);
    if (!mounted) return;

    // ✅ kalau error, jangan auto set apa-apa (biarkan UI handle error)
    if (lvm.error.isNotEmpty) {
      setState(() => _selectedFurnitureMaterial = _noneFurnitureMaterial);
      idFurnitureMaterialCtrl.text = '';
      return;
    }

    final list = lvm.items; // ✅ LIST

    // ✅ tidak ada mapping => pilih "Tidak ada"
    if (list.isEmpty) {
      setState(() => _selectedFurnitureMaterial = _noneFurnitureMaterial);
      idFurnitureMaterialCtrl.text = '';
      return;
    }

    // =========================================================
    // ✅ strategi pilih (pick)
    // prioritas:
    // 1) kalau sedang edit: header sudah punya idFurnitureMaterial -> cari itu
    // 2) kalau user sudah sempat pilih -> pertahankan kalau masih ada
    // 3) kalau list cuma 1 -> auto pilih
    // 4) fallback -> "Tidak ada"
    // =========================================================
    final headerId = widget.header?.idFurnitureMaterial; // <-- pastikan field ini ada
    final currentId = _selectedFurnitureMaterial?.idFurnitureMaterial;

    FurnitureMaterialLookupResult pick;

    if (headerId != null) {
      pick = list.firstWhere(
            (e) => e.idFurnitureMaterial == headerId,
        orElse: () => list.length == 1 ? list.first : _noneFurnitureMaterial,
      );
    } else if (currentId != null && currentId != _noneFurnitureMaterial.idFurnitureMaterial) {
      pick = list.firstWhere(
            (e) => e.idFurnitureMaterial == currentId,
        orElse: () => list.length == 1 ? list.first : _noneFurnitureMaterial,
      );
    } else if (list.length == 1) {
      pick = list.first;
    } else {
      pick = _noneFurnitureMaterial;
    }

    setState(() => _selectedFurnitureMaterial = pick);

    // ✅ kalau "Tidak ada" => kosongkan controller
    if (pick.idFurnitureMaterial == _noneFurnitureMaterial.idFurnitureMaterial) {
      idFurnitureMaterialCtrl.text = '';
    } else {
      idFurnitureMaterialCtrl.text = pick.idFurnitureMaterial.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📝 [INJECT_FORM] build() called');

    // ✅ Verify we're using the correct VM
    final vm = context.read<InjectProductionViewModel>();
    debugPrint('📝 [INJECT_FORM] VM from context: hash=${vm.hashCode}');
    debugPrint(
      '📝 [INJECT_FORM] Controller from VM: hash=${vm.pagingController.hashCode}',
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => OverlapViewModel(repository: OverlapRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => CetakanViewModel(repository: CetakanRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => WarnaViewModel(repository: WarnaRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => FurnitureMaterialLookupViewModel(
            repository: FurnitureMaterialLookupRepository(),
          ),
        ),
      ],
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
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
          isEdit ? 'Edit Produksi Inject' : 'Tambah Produksi Inject',
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
    final overlapMsg =
        vm.overlapMessage ?? 'Jam ini bentrok dengan dokumen lain';

    final idCetakan = _selectedCetakan?.idCetakan ?? widget.header?.idCetakan;
    final idWarna = _selectedWarna?.idWarna ?? widget.header?.idWarna;

    final fmVm = context.watch<FurnitureMaterialLookupViewModel>();

    final furnitureDropdownEnabled =
        idCetakan != null && idWarna != null && fmVm.items.isNotEmpty && !fmVm.isLoading && fmVm.error.isEmpty;


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
                  Icon(Icons.description,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Header',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // No Produksi (readonly, auto dari backend)
              AppTextField(
                controller: noProduction,
                label: 'No. Inject',
                icon: Icons.label,
                readOnly: true,
                hintText: 'S.XXXXXXXXXX',
              ),

              const SizedBox(height: 16),

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

              // Jenis Mesin
              MesinDropdown(
                idBagianMesin: 4, // ✅ ID bagian untuk INJECT
                preselectId: widget.header?.idMesin,
                label: 'Mesin Inject',
                hint: 'Pilih mesin',
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => v == null ? 'Wajib pilih mesin inject' : null,
                onChanged: (m) async {
                  _selectedMesin = m;
                  _operatorPreselectId = m?.defaultOperatorId;

                  setState(() {});
                  await _checkOverlapIfReadyVM();
                },
              ),

              const SizedBox(height: 16),

              // Operator
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
                        final picked = await pickTime24h(
                          context,
                          initial: _startTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _startTime = picked;
                            hourStartCtrl.text = formatHHmm(picked);
                          });
                          _updateJamFromTimeRange(); // ✅ Auto-update jam
                          await _checkOverlapIfReadyVM();
                        }
                      },
                      validator: (_) {
                        final s = parseHHmm(hourStartCtrl.text);
                        if (s == null) {
                          return 'Wajib isi jam mulai (HH:mm)';
                        }
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
                          context,
                          initial: _endTime ?? _startTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _endTime = picked;
                            hourEndCtrl.text = formatHHmm(picked);
                          });
                          _updateJamFromTimeRange(); // ✅ Auto-update jam
                          await _checkOverlapIfReadyVM();
                        }
                      },
                      validator: (_) {
                        final e = parseHHmm(hourEndCtrl.text);
                        if (e == null) {
                          return 'Wajib isi jam selesai (HH:mm)';
                        }
                        final s = parseHHmm(hourStartCtrl.text);
                        if (s != null) {
                          final diff = durationBetweenHHmmWrap(
                              hourStartCtrl.text, hourEndCtrl.text);
                          if (diff == null) {
                            return 'Durasi tidak boleh 0 menit';
                          }
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
                    child: AppTextField(
                      controller: jamCtrl,
                      label: 'Jam (INT)',
                      icon: Icons.access_time,
                      hintText: 'contoh: 9',
                      validator: (_) {
                        final t = jamCtrl.text.trim();
                        if (t.isEmpty) return null;
                        if (int.tryParse(t) != null) return null;
                        return 'Harus berupa angka';
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppNumberField(
                      controller: hourMeterCtrl,
                      label: 'Hour Meter',
                      icon: Icons.timer_sharp,
                      allowDecimal: true,
                      allowNegative: false,
                      hintText: 'contoh: 3.5',
                      validator: (_) => null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppNumberField(
                      controller: beratProdukHasilTimbangCtrl,
                      label: 'Berat Produk (kg)',
                      icon: Icons.scale,
                      allowDecimal: true,
                      allowNegative: false,
                      hintText: 'contoh: 12.5',
                      validator: (_) => null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CetakanDropdown(
                      key: ValueKey(widget.header?.idCetakan),
                      preselectId: widget.header?.idCetakan,
                      label: 'Cetakan',
                      hint: 'Pilih cetakan',
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => v == null ? 'Wajib pilih cetakan' : null,
                      onChanged: (c) async {
                        _selectedCetakan = c;
                        setState(() {});
                        await _resolveFurnitureMaterialIfReady();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WarnaDropdown(
                      preselectId: widget.header?.idWarna,
                      label: 'Warna',
                      hint: 'Pilih warna',
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => v == null ? 'Wajib pilih warna' : null,
                      onChanged: (w) async {
                        _selectedWarna = w;
                        setState(() {});
                        await _resolveFurnitureMaterialIfReady();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: FurnitureMaterialDropdown(
                      idCetakan: idCetakan,
                      idWarna: idWarna,
                      preselectId: widget.header?.idFurnitureMaterial,
                      label: 'Furniture Material',
                      hint: 'Pilih furniture material',
                      enabled: furnitureDropdownEnabled,
                      autovalidateMode: AutovalidateMode.onUserInteraction,

                      // ✅ tidak wajib (boleh kosong)
                      validator: (_) => null,

                      onChanged: (val) {
                        if (val == null) {
                          setState(() =>
                          _selectedFurnitureMaterial = _noneFurnitureMaterial);
                          idFurnitureMaterialCtrl.text = '';
                          return;
                        }
                        setState(() => _selectedFurnitureMaterial = val);
                        idFurnitureMaterialCtrl.text =
                        (val.idFurnitureMaterial == _noneFurnitureId)
                            ? ''
                            : val.idFurnitureMaterial.toString();
                      },
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
    final ovm = context.watch<OverlapViewModel>();
    final hasOverlap = ovm.hasOverlap;

    // ✅ Watch VM from PARENT Screen context for isSaving state
    final prodVm = context.watch<InjectProductionViewModel>();
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
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 14,
            ),
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