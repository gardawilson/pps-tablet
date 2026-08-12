import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../cetakan/model/mst_cetakan_model.dart';
import '../../../cetakan/repository/cetakan_repository.dart';
import '../../../furniture_material/model/furniture_material_lookup_model.dart';
import '../../../jenis_bonggolan/model/jenis_bonggolan_model.dart';
import '../../../jenis_bonggolan/view_model/jenis_bonggolan_view_model.dart';
import '../../../reject_type/model/reject_type_model.dart';
import '../../../reject_type/view_model/reject_type_view_model.dart';
import '../../../warna/model/warna_model.dart';
import '../model/inject_batch_model.dart' show InjectBatchSubmitResult;
import '../model/inject_production_model.dart' show InjectOutputJenis;
import '../repository/inject_production_repository.dart';
import 'cetakan_warna_material_picker.dart';
import 'counter_picker_dialog.dart';

class InjectSplitTimeDialogV3 extends StatefulWidget {
  const InjectSplitTimeDialogV3({
    super.key,
    required this.idMesin,
    required this.tglProduksi,
    this.currentHourEnd,
    this.currentCetakan,
    this.currentWarna,
    this.currentMaterial,
    this.lockedIdCetakan,
    this.lockedNamaCetakan,
    this.carryOverIn = 0,
    this.pcsPerLabel = 100,
    this.counterCurrent,
    this.outputJenisList = const [],
    this.noProduksi,
    this.lastBucketHourStart,
  });

  final int idMesin;
  final DateTime tglProduksi;
  final String? currentHourEnd;
  final String? currentCetakan;
  final String? currentWarna;
  final String? currentMaterial;
  final int? lockedIdCetakan;
  final String? lockedNamaCetakan;
  final int carryOverIn;
  final int pcsPerLabel;
  final int? counterCurrent;
  final List<InjectOutputJenis> outputJenisList;
  final String? noProduksi;
  final String? lastBucketHourStart;

  @override
  State<InjectSplitTimeDialogV3> createState() => _InjectSplitTimeDialogV3State();
}

class _InjectSplitTimeDialogV3State extends State<InjectSplitTimeDialogV3> {
  final _hourCtrl = TextEditingController();
  final _pcsCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _cycleCtrl = TextEditingController();
  final _beratBonggolanCtrl = TextEditingController();
  final _beratRejectCtrl = TextEditingController();

  int? _counterValue;
  InjectOutputJenis? _pickedJenis;

  MstCetakan? _cetakan;
  MstWarna? _warna;
  FurnitureMaterialLookupResult? _material;
  bool _loadingCetakan = false;

  JenisBonggolan? _bonggolanJenis;
  RejectType? _rejectJenis;

  bool _isSaving = false;
  String? _error;
  bool _timeManuallyChanged = false;  // ignore: prefer_final_fields
  Timer? _clockTimer;

  String _nowHHmm() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _hourCtrl.text = _nowHHmm();
    _pcsCtrl.addListener(() { if (mounted) setState(() {}); });
    if (widget.lockedIdCetakan != null) _prefetchLockedCetakan();
    _startClock();
  }

  void _startClock() {
    final now = DateTime.now();
    final secondsUntilNextMinute = 60 - now.second;
    Future.delayed(Duration(seconds: secondsUntilNextMinute), () {
      if (!mounted || _timeManuallyChanged) return;
      setState(() => _hourCtrl.text = _nowHHmm());
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted || _timeManuallyChanged) {
          _clockTimer?.cancel();
          return;
        }
        setState(() => _hourCtrl.text = _nowHHmm());
      });
    });
  }

  Future<void> _prefetchLockedCetakan() async {
    setState(() => _loadingCetakan = true);
    try {
      final all = await CetakanRepository().fetchAll();
      if (!mounted) return;
      final match = all.where((c) => c.idCetakan == widget.lockedIdCetakan).firstOrNull;
      if (match != null) setState(() => _cetakan = match);
    } catch (_) {}
    if (mounted) setState(() => _loadingCetakan = false);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _hourCtrl.dispose();
    _pcsCtrl.dispose();
    _beratCtrl.dispose();
    _cycleCtrl.dispose();
    _beratBonggolanCtrl.dispose();
    _beratRejectCtrl.dispose();
    super.dispose();
  }

  Future<JenisBonggolan?> _showBonggolanPicker() async {
    final vm = context.read<JenisBonggolanViewModel>();
    await vm.ensureLoaded();
    if (!mounted) return null;
    return showDialog<JenisBonggolan>(
      context: context,
      builder: (ctx) => _JenisListDialog<JenisBonggolan>(
        title: 'Jenis Bonggolan',
        icon: Icons.recycling_outlined,
        items: vm.list,
        labelOf: (e) => e.namaBonggolan,
        subtitleOf: (_) => null,
      ),
    );
  }

  Future<RejectType?> _showRejectPicker() async {
    final vm = context.read<RejectTypeViewModel>();
    await vm.ensureLoaded();
    if (!mounted) return null;
    return showDialog<RejectType>(
      context: context,
      builder: (ctx) => _JenisListDialog<RejectType>(
        title: 'Jenis Reject',
        icon: Icons.recycling_outlined,
        items: vm.list,
        labelOf: (e) => e.namaReject,
        subtitleOf: (e) => (e.itemCode ?? '').trim().isEmpty ? null : e.itemCode,
      ),
    );
  }

  bool get _canSave =>
      _hourCtrl.text.trim().isNotEmpty && _cetakan != null && _warna != null;

  Future<void> _pickCetakan() async {
    setState(() => _loadingCetakan = true);

    List<MstCetakan>? overrideList;
    if (widget.lockedIdCetakan != null) {
      try {
        final all = await CetakanRepository().fetchAll();
        overrideList = all.where((c) => c.idCetakan == widget.lockedIdCetakan).toList();
        if (!mounted) return;
        if (_cetakan == null && overrideList.isNotEmpty) {
          setState(() => _cetakan = overrideList!.first);
        }
      } catch (_) {}
    }

    final result = await showCetakanWarnaMaterialPicker(
      context,
      initialCetakan: _cetakan,
      initialWarna: _warna,
      initialMaterial: _material,
      overrideCetakanList: overrideList,
    );
    if (!mounted) return;
    setState(() {
      _loadingCetakan = false;
      if (result != null) {
        _cetakan = result.cetakan;
        _warna = result.warna;
        _material = result.material;
      }
    });
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    setState(() {
      _hourCtrl.text = '$hh:$mm';
      _timeManuallyChanged = true;
      _clockTimer?.cancel();
    });
  }

  Widget _buildCounterField() {
    const accent = Color(0xFF0F766E);
    final hasValue = _counterValue != null;
    final minCounter = widget.counterCurrent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          minCounter != null ? 'Counter · min $minCounter' : 'Counter',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 3),
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (_) => CounterPickerDialog(
                initialValue: _counterValue ?? (minCounter ?? 0),
                minValue: minCounter,
              ),
            );
            if (picked != null && mounted) setState(() => _counterValue = picked);
          },
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasValue ? accent : accent.withValues(alpha: 0.30),
                width: hasValue ? 1.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasValue)
                  Text('$_counterValue', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent))
                else
                  Text('Pilih', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 14, color: hasValue ? accent : Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _readonlyChip({required String label, required String value, bool muted = false}) {
    const accent = Color(0xFF0277BD);
    const mutedAccent = Color(0xFF64748B);
    final color = muted ? mutedAccent : accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 3),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final timeText = _hourCtrl.text.trim();
    if (timeText.isEmpty || _cetakan == null || _warna == null) return;

    final pcsInput = int.tryParse(_pcsCtrl.text.trim());
    final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
    final cycleTime = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
    final beratBonggolan = double.tryParse(_beratBonggolanCtrl.text.replaceAll(',', '.'));
    final beratReject = double.tryParse(_beratRejectCtrl.text.replaceAll(',', '.'));

    // Pick jenis output if needed
    InjectOutputJenis? jenis = _pickedJenis;
    final outputs = widget.outputJenisList;
    if (pcsInput != null && pcsInput >= 0 && jenis == null && outputs.isNotEmpty) {
      final totalPcs = widget.carryOverIn + pcsInput;
      final needPick = totalPcs > 0;
      if (needPick) {
        if (outputs.length == 1) {
          jenis = outputs.first;
        } else {
          jenis = await showDialog<InjectOutputJenis>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _OutputJenisPickerDialog(options: outputs),
          );
          if (!mounted) return;
          if (jenis == null) return;
        }
        setState(() => _pickedJenis = jenis);
      }
    }

    // Require jenis bonggolan/reject if berat diisi
    if (beratBonggolan != null && beratBonggolan > 0 && _bonggolanJenis == null) {
      final picked = await _showBonggolanPicker();
      if (!mounted) return;
      if (picked == null) return;
      setState(() => _bonggolanJenis = picked);
    }
    if (beratReject != null && beratReject > 0 && _rejectJenis == null) {
      final picked = await _showRejectPicker();
      if (!mounted) return;
      if (picked == null) return;
      setState(() => _rejectJenis = picked);
    }

    setState(() { _isSaving = true; _error = null; });

    try {
      final repo = InjectProductionRepository();
      final newHourStart = timeText.length == 5 ? '$timeText:00' : timeText;

      // Build batch sub-object — embedded in splitTime body
      Map<String, dynamic>? batchPayload;
      final lastHourStart = widget.lastBucketHourStart;
      if (lastHourStart != null) {
        final lastHourStartFull = lastHourStart.length == 5 ? '$lastHourStart:00' : lastHourStart;
        final ppl = widget.pcsPerLabel.clamp(1, 999999);
        final carryOverOut = (widget.carryOverIn + (pcsInput ?? 0)) % ppl;
        final item = <String, dynamic>{
          'carryOverIn': widget.carryOverIn,
          'pcsInput': pcsInput ?? 0,
          'carryOverOut': carryOverOut,
          if (jenis != null && jenis.idJenis > 0) 'idJenis': jenis.idJenis,
        };
        batchPayload = <String, dynamic>{
          'hourStart': lastHourStartFull,
          'outputCategory': jenis?.outputCategory ?? 'furnitureWip',
          'items': [item],
          if (berat != null) 'berat': berat,
          if (cycleTime != null) 'cycleTime': cycleTime,
          if (_counterValue != null) 'counter': _counterValue,
          if (_bonggolanJenis != null && beratBonggolan != null && beratBonggolan > 0)
            'bonggolan': {
              'idBonggolan': _bonggolanJenis!.idBonggolan,
              'berat': beratBonggolan,
            },
          if (_rejectJenis != null && beratReject != null && beratReject > 0)
            'reject': {
              'idReject': _rejectJenis!.idReject,
              'berat': beratReject,
            },
        };
      }

      final raw = await repo.splitTime(
        idMesin: widget.idMesin,
        tglProduksi: widget.tglProduksi,
        hourStart: newHourStart,
        idCetakan: _cetakan!.idCetakan,
        idWarna: _warna!.idWarna,
        idFurnitureMaterial: _material?.idFurnitureMaterial,
        batch: batchPayload,
      );
      if (!mounted) return;
      Navigator.of(context).pop(InjectBatchSubmitResult.fromJson(raw));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F766E);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 860,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ganti Produksi (Split Time)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(null),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body: two-column layout ──────────────────────────────────
            Flexible(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── LEFT: Produksi Saat Ini ────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF64748B).withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.history_rounded, size: 13, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'PRODUKSI SAAT INI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Chips cetakan/warna/material
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: (widget.currentCetakan ?? '').isNotEmpty ||
                                      (widget.currentWarna ?? '').isNotEmpty ||
                                      (widget.currentMaterial ?? '').isNotEmpty
                                  ? Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if ((widget.currentCetakan ?? '').isNotEmpty)
                                          _CurrentInfoChip(icon: Icons.view_in_ar_rounded, label: widget.currentCetakan!),
                                        if ((widget.currentWarna ?? '').isNotEmpty)
                                          _CurrentInfoChip(icon: Icons.palette_outlined, label: widget.currentWarna!),
                                        if ((widget.currentMaterial ?? '').isNotEmpty)
                                          _CurrentInfoChip(icon: Icons.category_outlined, label: widget.currentMaterial!),
                                      ],
                                    )
                                  : const Text(
                                      'Tidak ada informasi produksi',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                    ),
                            ),

                            const SizedBox(height: 14),
                            const _SubSectionLabel(label: 'INPUT JAM AKHIR'),
                            const SizedBox(height: 8),

                            // Carry masuk + pcs input + carry sesudah
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _readonlyChip(
                                    label: 'Carry Masuk',
                                    value: '${widget.carryOverIn} / ${widget.pcsPerLabel}',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _BeratField(
                                    label: 'Item Bagus (pcs)',
                                    ctrl: _pcsCtrl,
                                    hint: '0',
                                    decimal: false,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Builder(builder: (_) {
                                    final ppl = widget.pcsPerLabel.clamp(1, 999999);
                                    final pcsTyped = int.tryParse(_pcsCtrl.text.trim()) ?? 0;
                                    final carryOut = (widget.carryOverIn + pcsTyped) % ppl;
                                    return _readonlyChip(
                                      label: 'Carry Sesudah',
                                      value: '$carryOut pcs',
                                      muted: true,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Berat + Cycle + Counter
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _BeratField(
                                    label: 'Berat (gr)',
                                    ctrl: _beratCtrl,
                                    hint: '0.0',
                                    decimal: true,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _BeratField(
                                    label: 'Cycle Time (sec)',
                                    ctrl: _cycleCtrl,
                                    hint: '0.0',
                                    decimal: true,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(child: _buildCounterField()),
                              ],
                            ),

                            const SizedBox(height: 14),
                            const _SubSectionLabel(label: 'SISA AKHIR SHIFT (OPSIONAL)'),
                            const SizedBox(height: 8),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _JenisPicker(
                                    label: 'Jenis Bonggolan',
                                    selectedName: _bonggolanJenis?.namaBonggolan,
                                    onTap: () async {
                                      final picked = await _showBonggolanPicker();
                                      if (picked != null && mounted) setState(() => _bonggolanJenis = picked);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: _BeratField(
                                    label: 'Berat (kg)',
                                    ctrl: _beratBonggolanCtrl,
                                    enabled: _bonggolanJenis != null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _JenisPicker(
                                    label: 'Jenis Reject',
                                    selectedName: _rejectJenis?.namaReject,
                                    onTap: () async {
                                      final picked = await _showRejectPicker();
                                      if (picked != null && mounted) setState(() => _rejectJenis = picked);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: _BeratField(
                                    label: 'Berat (kg)',
                                    ctrl: _beratRejectCtrl,
                                    enabled: _rejectJenis != null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Vertical divider with arrow ────────────────────────
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 1,
                          height: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 60),
                          color: const Color(0xFFE5E7EB),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withValues(alpha: 0.20)),
                          ),
                          child: Icon(Icons.arrow_forward_rounded, size: 14, color: accent.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 1,
                          height: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 60),
                          color: const Color(0xFFE5E7EB),
                        ),
                      ],
                    ),

                    // ── RIGHT: Produksi Baru ──────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.fiber_new_rounded, size: 13, color: accent),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PRODUKSI BARU',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Jam mulai
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: accent.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.access_time_rounded, size: 16, color: accent),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Jam Mulai',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: accent.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _pickTime,
                                          child: Text(
                                            _hourCtrl.text.isNotEmpty ? _hourCtrl.text : '--:--',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: _hourCtrl.text.isNotEmpty ? accent : const Color(0xFFD1D5DB),
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _pickTime,
                                    icon: const Icon(Icons.edit_outlined, size: 13),
                                    label: const Text('Ubah', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(foregroundColor: accent),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),
                            const _SubSectionLabel(label: 'CETAKAN, WARNA & MATERIAL'),
                            const SizedBox(height: 4),
                            Text(
                              widget.lockedIdCetakan != null
                                  ? 'Cetakan terkunci — pilih warna & material'
                                  : 'Pilih cetakan untuk produksi baru',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                            ),
                            const SizedBox(height: 8),
                            CetakanWarnaMaterialPickerField(
                              selectedCetakan: _cetakan,
                              selectedWarna: _warna,
                              selectedMaterial: _material,
                              isLoading: _loadingCetakan,
                              onTap: _pickCetakan,
                            ),

                            // Error
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(null),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: (_canSave && !_isSaving) ? _submit : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Ganti Produksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _SubSectionLabel extends StatelessWidget {
  const _SubSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: Color(0xFF6B7280),
        letterSpacing: 1.0,
      ),
    );
  }
}

class _JenisPicker extends StatelessWidget {
  const _JenisPicker({
    required this.label,
    required this.selectedName,
    required this.onTap,
  });

  final String label;
  final String? selectedName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF92400E);
    final hasValue = selectedName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 3),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasValue ? accent : accent.withValues(alpha: 0.30),
                width: hasValue ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? selectedName! : 'Pilih...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue ? accent : Colors.grey.shade400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 14,
                  color: hasValue ? accent : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BeratField extends StatelessWidget {
  const _BeratField({
    required this.label,
    required this.ctrl,
    this.enabled = true,
    this.hint = '0.0',
    this.decimal = true,
  });

  final String label;
  final TextEditingController ctrl;
  final bool enabled;
  final String hint;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F766E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 32,
          child: TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.30)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.30)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: accent),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimpleCounterDialog extends StatefulWidget {
  const _SimpleCounterDialog({required this.initial});
  final int initial;

  @override
  State<_SimpleCounterDialog> createState() => _SimpleCounterDialogState();
}

class _SimpleCounterDialogState extends State<_SimpleCounterDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial == 0 ? '' : '${widget.initial}');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Counter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: 'Masukkan counter...', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(int.tryParse(_ctrl.text.trim()) ?? widget.initial),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _OutputJenisPickerDialog extends StatelessWidget {
  const _OutputJenisPickerDialog({required this.options});
  final List<InjectOutputJenis> options;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F766E);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.label_outline, size: 16, color: accent),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Pilih Jenis Output', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E6EA)),
            ...options.asMap().entries.map((e) {
              final i = e.key; final o = e.value;
              return Column(mainAxisSize: MainAxisSize.min, children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(o),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Container(
                        width: 26, height: 26, alignment: Alignment.center,
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(o.namaJenis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)))),
                      const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
                    ]),
                  ),
                ),
                if (i < options.length - 1) const Divider(height: 1, color: Color(0xFFE2E6EA), indent: 16, endIndent: 16),
              ]);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _JenisListDialog<T> extends StatelessWidget {
  const _JenisListDialog({
    required this.title,
    required this.icon,
    required this.items,
    required this.labelOf,
    required this.subtitleOf,
  });

  final String title;
  final IconData icon;
  final List<T> items;
  final String Function(T) labelOf;
  final String? Function(T) subtitleOf;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF92400E);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E6EA)),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Tidak ada data',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFE2E6EA),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final sub = subtitleOf(item);
                    return InkWell(
                      onTap: () => Navigator.of(ctx).pop(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    labelOf(item),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  if (sub != null && sub.isNotEmpty)
                                    Text(
                                      sub,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CurrentInfoChip extends StatelessWidget {
  const _CurrentInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF0F766E)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }
}
