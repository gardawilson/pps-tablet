// lib/features/production/washing/widgets/washing_production_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/operator/model/operator_model.dart';
import 'package:pps_tablet/features/operator/repository/operator_repository.dart';
import 'package:pps_tablet/features/production/shared/widgets/time_form_field.dart';
import 'package:pps_tablet/features/regu/model/regu_model.dart';
import 'package:pps_tablet/features/regu/repository/regu_repository.dart';
import 'package:pps_tablet/features/washing_type/model/washing_type_model.dart';
import 'package:pps_tablet/features/washing_type/widgets/washing_type_dropdown.dart';

import '../../../../common/widgets/app_number_field.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../mesin/model/mesin_model.dart';
import '../../../shared/overlap/repository/overlap_repository.dart';
import '../../../shared/overlap/view_model/overlap_view_model.dart';
import '../../../shared/shift/widgets/shift_dropdown.dart';
import '../../shared/widgets/total_hours_pill.dart';
import '../model/washing_production_model.dart';
import '../view_model/washing_production_view_model.dart';

class WashingProductionFormDialog extends StatefulWidget {
  final WashingProduction? header;
  final Function(WashingProduction)? onSave;

  // Pre-fill saat create baru dari mesin card
  final MstMesin? initialMesin;
  final DateTime? initialDate;
  final int? initialShift;
  final String? initialHourStart;
  final String? initialHourEnd;

  /// Jika true, field shift + jam mulai + jam selesai di-disable (readonly)
  final bool lockShiftFields;

  const WashingProductionFormDialog({
    super.key,
    this.header,
    this.onSave,
    this.initialMesin,
    this.initialDate,
    this.initialShift,
    this.initialHourStart,
    this.initialHourEnd,
    this.lockShiftFields = false,
  });

  @override
  State<WashingProductionFormDialog> createState() =>
      _WashingProductionFormDialogState();
}

class _WashingProductionFormDialogState
    extends State<WashingProductionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController hourStartCtrl;
  late final TextEditingController hourEndCtrl;
  late final TextEditingController hadirCtrl;

  // State
  MstMesin? _selectedMesin;
  MstRegu? _selectedRegu;
  List<MstOperator> _selectedOperators = [];
  bool _loadingReguOperator = false;
  int? _selectedShift;
  int? _selectedReguId;
  WashingType? _selectedWashingType;
  bool _isBlower = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool get isEdit => widget.header != null;

  static const String _kind = 'washing';

  @override
  void initState() {
    super.initState();

    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.tglProduksi) ?? DateTime.now())
        : (widget.initialDate ?? DateTime.now());
    _selectedDate = seededDate;

    _selectedMesin = widget.initialMesin;
    _selectedShift = widget.header?.shift ?? widget.initialShift;
    _selectedReguId = widget.header?.idRegu;
    _isBlower = widget.header?.isBlower ?? false;

    final initStart = widget.header?.hourStart ?? widget.initialHourStart;
    final initEnd = widget.header?.hourEnd ?? widget.initialHourEnd;
    hourStartCtrl = TextEditingController(text: initStart ?? '');
    hourEndCtrl = TextEditingController(text: initEnd ?? '');

    hadirCtrl = TextEditingController(
      text: widget.header?.hadir?.toString() ?? '',
    );

    // Pre-fill regu & operator dari header (edit mode)
    final h = widget.header;
    if (h != null) {
      if (h.idRegu != null) {
        _selectedRegu = MstRegu(idRegu: h.idRegu!, idBagian: 0, namaRegu: '');
      }
      if (h.idOperators.isNotEmpty) {
        final names = h.namaOperators.split(',').map((s) => s.trim()).toList();
        _selectedOperators = List.generate(h.idOperators.length, (i) {
          return MstOperator(
            idOperator: h.idOperators[i],
            namaOperator: i < names.length ? names[i] : '',
            enable: true,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    hourStartCtrl.dispose();
    hourEndCtrl.dispose();
    hadirCtrl.dispose();
    super.dispose();
  }

  String? _buildJamRange() {
    final start = hourStartCtrl.text.trim();
    final end = hourEndCtrl.text.trim();
    if (start.isEmpty || end.isEmpty) return null;
    return '$start-$end';
  }

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

  Future<void> _openReguOperatorPicker() async {
    if (!mounted) return;
    setState(() => _loadingReguOperator = true);
    List<MstRegu> allRegu = [];
    try {
      allRegu = await ReguRepository().fetchAll();
    } catch (_) {
      allRegu = [];
    } finally {
      if (mounted) setState(() => _loadingReguOperator = false);
    }
    if (!mounted) return;

    final result =
        await showDialog<({MstRegu regu, List<MstOperator> operators})>(
          context: context,
          builder: (_) => _ReguOperatorPickerDialog(
            reguList: allRegu,
            initialRegu: _selectedRegu,
            initialSelected: _selectedOperators,
          ),
        );
    if (result != null && mounted) {
      setState(() {
        _selectedRegu = result.regu;
        _selectedReguId = result.regu.idRegu;
        _selectedOperators
          ..clear()
          ..addAll(result.operators);
      });
    }
  }

  Future<void> _submit() async {
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

    final mesinId = _selectedMesin?.idMesin ?? widget.header?.idMesin;
    if (mesinId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mesin wajib dipilih')));
      return;
    }

    final idOperatorList = _selectedOperators.map((o) => o.idOperator).toList();
    if (idOperatorList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 1 operator wajib dipilih')),
      );
      return;
    }

    if (_selectedShift == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shift wajib dipilih')));
      return;
    }

    final jamRange = _buildJamRange();
    if (jamRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam mulai & selesai wajib diisi')),
      );
      return;
    }

    String toSqlTime(String raw) {
      final t = raw.trim();
      return (t.isNotEmpty && t.length == 5) ? '$t:00' : t;
    }

    final hourStartSql = toSqlTime(hourStartCtrl.text);
    final hourEndSql = toSqlTime(hourEndCtrl.text);
    final hadir = int.tryParse(hadirCtrl.text.trim());

    final prodVm = context.read<WashingProductionViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    WashingProduction? result;

    try {
      if (isEdit) {
        result = await prodVm.updateProduksi(
          noProduksi: widget.header!.noProduksi,
          tglProduksi: _selectedDate,
          idMesin: mesinId,
          idOperator: idOperatorList.first,
          jamKerja: jamRange,
          shift: _selectedShift!,
          isBlower: _isBlower,
          hourStart: hourStartSql,
          hourEnd: hourEndSql,
          hadir: hadir,
          idRegu: _selectedReguId,
        );
      } else {
        result = await prodVm.createProduksi(
          tglProduksi: _selectedDate,
          idMesin: mesinId,
          idOperators: idOperatorList,
          outputJenisId: _selectedWashingType?.idWashing,
          jamKerja: jamRange,
          shift: _selectedShift!,
          isBlower: _isBlower,
          hourStart: hourStartSql,
          hourEnd: hourEndSql,
          hadir: hadir,
          idRegu: _selectedReguId,
        );
      }
    } finally {
      if (mounted) Navigator.of(context).pop();
    }

    if (!mounted) return;

    if (result != null) {
      widget.onSave?.call(result);
      Navigator.of(context).pop(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prodVm.saveError ?? 'Gagal menyimpan data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;

    return ChangeNotifierProvider(
      create: (_) => OverlapViewModel(repository: OverlapRepository()),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: isLandscape
            ? const EdgeInsets.symmetric(horizontal: 72, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLandscape ? 680 : 620,
            maxHeight: (mq.size.height - 24).clamp(
              260,
              isLandscape ? 560 : 680,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: _buildForm(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final vm = context.watch<OverlapViewModel>();
    final dur = durationBetweenHHmmWrap(hourStartCtrl.text, hourEndCtrl.text);
    final startFilled = hourStartCtrl.text.trim().isNotEmpty;
    final endFilled = hourEndCtrl.text.trim().isNotEmpty;
    final hasDurationError = startFilled && endFilled && dur == null;
    final hasOverlap = vm.hasOverlap;
    final overlapMsg =
        vm.overlapMessage ?? 'Jam ini bentrok dengan dokumen lain';

    final mesinName =
        _selectedMesin?.namaMesin ??
        widget.header?.namaMesin ??
        widget.initialMesin?.namaMesin ??
        (isEdit ? 'Edit Produksi' : 'Tambah Produksi');

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Judul ────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEdit ? Colors.orange.shade50 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit : Icons.add,
                  color: isEdit ? Colors.orange.shade700 : Colors.teal.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mesinName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Tanggal (tampilkan, readonly untuk create dari mesin card)
              Text(
                DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Baris 1: Shift + Jam Mulai + Jam Selesai + Total Jam ─────────
          AbsorbPointer(
            absorbing: widget.lockShiftFields,
            child: Opacity(
              opacity: widget.lockShiftFields ? 0.55 : 1.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 190,
                    child: ShiftDropdown(
                      preselectId: widget.header?.shift ?? widget.initialShift,
                      onChangedId: (id) => setState(() => _selectedShift = id),
                      validator: (v) => v == null ? 'Wajib pilih shift' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
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
                          await _checkOverlapIfReadyVM();
                        }
                      },
                      validator: (_) {
                        final s = parseHHmm(hourStartCtrl.text);
                        if (s == null) return 'Wajib isi (HH:mm)';
                        final diff = durationBetweenHHmmWrap(
                          hourStartCtrl.text,
                          hourEndCtrl.text,
                        );
                        if (diff == null &&
                            parseHHmm(hourEndCtrl.text) != null) {
                          return 'Durasi 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
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
                          await _checkOverlapIfReadyVM();
                        }
                      },
                      validator: (_) {
                        final e = parseHHmm(hourEndCtrl.text);
                        if (e == null) return 'Wajib isi (HH:mm)';
                        final s = parseHHmm(hourStartCtrl.text);
                        if (s != null) {
                          final diff = durationBetweenHHmmWrap(
                            hourStartCtrl.text,
                            hourEndCtrl.text,
                          );
                          if (diff == null) return 'Durasi 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TotalHoursPill(
                        duration: dur,
                        isError: hasOverlap || hasDurationError,
                        errorText: hasOverlap
                            ? overlapMsg
                            : 'Durasi tidak boleh 0 menit',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Baris 3: Regu & Operator + Hadir ────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _ReguOperatorPickerField(
                  selectedRegu: _selectedRegu,
                  selectedOperators: _selectedOperators,
                  isLoading: _loadingReguOperator,
                  onTap: _openReguOperatorPicker,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: AppNumberField(
                  controller: hadirCtrl,
                  label: 'Hadir',
                  icon: Icons.people,
                  allowDecimal: false,
                  allowNegative: false,
                  hintText: '0',
                  isDense: true,
                  iconSize: 20,
                  fontSize: 14,
                  labelFontSize: 14,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Baris 4: Tipe Produksi (Washing / Blower) ───────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    value: false,
                    groupValue: _isBlower,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: const Text(
                      'Washing',
                      style: TextStyle(fontSize: 13),
                    ),
                    onChanged: (v) {
                      if (v != null) setState(() => _isBlower = v);
                    },
                  ),
                ),
                Container(width: 1, height: 48, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: RadioListTile<bool>(
                    value: true,
                    groupValue: _isBlower,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: const Text('Blower', style: TextStyle(fontSize: 13)),
                    onChanged: (v) {
                      if (v != null) setState(() => _isBlower = v);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Baris 5: Jenis Washing ───────────────────────────────────────
          WashingTypeDropdown(
            preselectId: widget.header?.outputJenisId,
            onChanged: (wt) => setState(() => _selectedWashingType = wt),
            validator: (v) => v == null ? 'Wajib pilih jenis washing' : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final vm = context.watch<OverlapViewModel>();
    final hasOverlap = vm.hasOverlap;
    final prodVm = context.watch<WashingProductionViewModel>();
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
            backgroundColor: isEdit
                ? const Color(0xFFF57C00)
                : const Color(0xFF00897B),
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

// ─────────────────────────────────────────────────────────────────────────────
// Field: gabungan regu + operator
// ─────────────────────────────────────────────────────────────────────────────
class _ReguOperatorPickerField extends StatelessWidget {
  const _ReguOperatorPickerField({
    required this.selectedRegu,
    required this.selectedOperators,
    required this.isLoading,
    required this.onTap,
  });

  final MstRegu? selectedRegu;
  final List<MstOperator> selectedOperators;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedRegu != null || selectedOperators.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Regu & Operator',
          labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(
                  Icons.groups_outlined,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
        ),
        child: !hasValue
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    size: 15,
                    color: Color(0xFFBEC8D5),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pilih regu & operator',
                    style: TextStyle(fontSize: 13, color: Color(0xFFADB8C4)),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedRegu != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            selectedRegu!.namaRegu,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedOperators.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${selectedOperators.length} Operator',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog: pilih regu lalu operator
// ─────────────────────────────────────────────────────────────────────────────
class _ReguOperatorPickerDialog extends StatefulWidget {
  const _ReguOperatorPickerDialog({
    required this.reguList,
    required this.initialRegu,
    required this.initialSelected,
  });

  final List<MstRegu> reguList;
  final MstRegu? initialRegu;
  final List<MstOperator> initialSelected;

  @override
  State<_ReguOperatorPickerDialog> createState() =>
      _ReguOperatorPickerDialogState();
}

class _ReguOperatorPickerDialogState extends State<_ReguOperatorPickerDialog> {
  MstRegu? _activeRegu;
  List<MstOperator> _operators = [];
  bool _loadingOp = false;
  Set<int> _selected = {};

  final Map<int, Set<int>> _selectionPerRegu = {};
  final Map<int, List<MstOperator>> _operatorsCache = {};

  @override
  void initState() {
    super.initState();
    _activeRegu = widget.initialRegu;
    final initSet = widget.initialSelected.map((o) => o.idOperator).toSet();
    if (widget.initialRegu != null && initSet.isNotEmpty) {
      _selectionPerRegu[widget.initialRegu!.idRegu] = Set.from(initSet);
    }
    _selected = Set.from(initSet);
    if (_activeRegu != null) _fetchOperators(_activeRegu!.idRegu);
  }

  Future<void> _fetchOperators(int idRegu) async {
    if (_operatorsCache.containsKey(idRegu)) {
      setState(() => _operators = _operatorsCache[idRegu]!);
      return;
    }
    setState(() {
      _loadingOp = true;
      _operators = [];
    });
    try {
      final result = await OperatorRepository().fetchByRegu(idRegu);
      _operatorsCache[idRegu] = result;
      if (mounted) setState(() => _operators = result);
    } catch (_) {
      if (mounted) setState(() => _operators = []);
    } finally {
      if (mounted) setState(() => _loadingOp = false);
    }
  }

  bool get _allSelected =>
      _operators.isNotEmpty && _selected.length == _operators.length;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected.addAll(_operators.map((o) => o.idOperator));
      }
    });
  }

  void _confirm() {
    if (_activeRegu == null) {
      Navigator.of(context).pop(null);
      return;
    }
    // Gabungkan semua operator dari semua regu yang pernah dipilih
    // (untuk simplicity: hanya regu aktif)
    final allSelected = _operators
        .where((o) => _selected.contains(o.idOperator))
        .toList();

    Navigator.of(context).pop((regu: _activeRegu!, operators: allSelected));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Container(
        width: 600,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D766E), Color(0xFF00897B)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Pilih Regu & Operator',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(null),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: Row(
                  children: [
                    // Kiri: regu list
                    SizedBox(
                      width: 190,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: const Color(0xFFF8FAFC),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'REGU',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          Expanded(
                            child: widget.reguList.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Tidak ada regu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: widget.reguList.length,
                                    itemBuilder: (_, i) {
                                      final regu = widget.reguList[i];
                                      final isActive =
                                          _activeRegu?.idRegu == regu.idRegu;
                                      return _ReguTile(
                                        regu: regu,
                                        isActive: isActive,
                                        onTap: () {
                                          if (!isActive) {
                                            setState(() {
                                              if (_activeRegu != null) {
                                                _selectionPerRegu[_activeRegu!
                                                    .idRegu] = Set.from(
                                                  _selected,
                                                );
                                              }
                                              _activeRegu = regu;
                                              _selected = Set.from(
                                                _selectionPerRegu[regu
                                                        .idRegu] ??
                                                    {},
                                              );
                                            });
                                            _fetchOperators(regu.idRegu);
                                          }
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),

                    // Kanan: operator list
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: const Color(0xFFF8FAFC),
                            child: Row(
                              children: [
                                const Text(
                                  'OPERATOR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Spacer(),
                                if (_operators.isNotEmpty)
                                  InkWell(
                                    onTap: _toggleAll,
                                    child: Text(
                                      _allSelected
                                          ? 'Batal Semua'
                                          : 'Pilih Semua',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF00897B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          Expanded(
                            child: _activeRegu == null
                                ? const _EmptyHint(
                                    text: 'Pilih regu terlebih dahulu',
                                  )
                                : _loadingOp
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _operators.isEmpty
                                ? const _EmptyHint(text: 'Tidak ada operator')
                                : ListView.builder(
                                    itemCount: _operators.length,
                                    itemBuilder: (_, i) {
                                      final op = _operators[i];
                                      final checked = _selected.contains(
                                        op.idOperator,
                                      );
                                      return _OperatorTile(
                                        operator: op,
                                        checked: checked,
                                        onToggle: () {
                                          setState(() {
                                            if (checked) {
                                              _selected.remove(op.idOperator);
                                            } else {
                                              _selected.add(op.idOperator);
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selected.length} operator dipilih',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _selected.isEmpty ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pilih'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReguTile extends StatelessWidget {
  const _ReguTile({
    required this.regu,
    required this.isActive,
    required this.onTap,
  });

  final MstRegu regu;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE0F2F1) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                regu.namaRegu,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFF00766E)
                      : const Color(0xFF374151),
                ),
              ),
            ),
            if (isActive)
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF00897B),
              ),
          ],
        ),
      ),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  const _OperatorTile({
    required this.operator,
    required this.checked,
    required this.onToggle,
  });

  final MstOperator operator;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF00897B),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                operator.namaOperator,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: checked ? FontWeight.w500 : FontWeight.w400,
                  color: checked
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}
