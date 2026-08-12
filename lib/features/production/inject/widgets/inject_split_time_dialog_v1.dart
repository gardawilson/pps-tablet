import 'dart:async';

import 'package:flutter/material.dart';

import '../../../cetakan/model/mst_cetakan_model.dart';
import '../../../cetakan/repository/cetakan_repository.dart';
import '../../../furniture_material/model/furniture_material_lookup_model.dart';
import '../../../warna/model/warna_model.dart';
import '../model/inject_batch_model.dart' show InjectBatchSubmitResult;
import '../repository/inject_production_repository.dart';
import 'cetakan_warna_material_picker.dart';

/// Versi sederhana dari dialog ganti produksi (split time) — dipakai oleh
/// layar input non-realtime. Tidak ada input jam akhir (carry masuk / item
/// bagus), tidak ada sisa akhir shift (jenis bonggolan & reject). Hanya
/// menampilkan section "Produksi Saat Ini" dan "Produksi Baru".
class InjectSplitTimeDialogV1 extends StatefulWidget {
  const InjectSplitTimeDialogV1({
    super.key,
    required this.idMesin,
    required this.tglProduksi,
    this.currentHourEnd,
    this.currentCetakan,
    this.currentWarna,
    this.currentMaterial,
    this.lockedIdCetakan,
    this.lockedNamaCetakan,
  });

  final int idMesin;
  final DateTime tglProduksi;
  final String? currentHourEnd;
  final String? currentCetakan;
  final String? currentWarna;
  final String? currentMaterial;
  final int? lockedIdCetakan;
  final String? lockedNamaCetakan;

  @override
  State<InjectSplitTimeDialogV1> createState() =>
      _InjectSplitTimeDialogV1State();
}

class _InjectSplitTimeDialogV1State extends State<InjectSplitTimeDialogV1> {
  final _hourCtrl = TextEditingController();

  MstCetakan? _cetakan;
  MstWarna? _warna;
  FurnitureMaterialLookupResult? _material;
  bool _loadingCetakan = false;

  bool _isSaving = false;
  String? _error;
  bool _timeManuallyChanged = false; // ignore: prefer_final_fields
  Timer? _clockTimer;

  String _nowHHmm() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _hourCtrl.text = _nowHHmm();
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
      final match = all
          .where((c) => c.idCetakan == widget.lockedIdCetakan)
          .firstOrNull;
      if (match != null) setState(() => _cetakan = match);
    } catch (_) {}
    if (mounted) setState(() => _loadingCetakan = false);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _hourCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _hourCtrl.text.trim().isNotEmpty && _cetakan != null && _warna != null;

  Future<void> _pickCetakan() async {
    setState(() => _loadingCetakan = true);

    List<MstCetakan>? overrideList;
    if (widget.lockedIdCetakan != null) {
      try {
        final all = await CetakanRepository().fetchAll();
        overrideList = all
            .where((c) => c.idCetakan == widget.lockedIdCetakan)
            .toList();
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

  Future<void> _submit() async {
    final timeText = _hourCtrl.text.trim();
    if (timeText.isEmpty || _cetakan == null || _warna == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repo = InjectProductionRepository();
      final newHourStart = timeText.length == 5 ? '$timeText:00' : timeText;

      final raw = await repo.splitTime(
        idMesin: widget.idMesin,
        tglProduksi: widget.tglProduksi,
        hourStart: newHourStart,
        idCetakan: _cetakan!.idCetakan,
        idWarna: _warna!.idWarna,
        idFurnitureMaterial: _material?.idFurnitureMaterial,
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
                                    color: const Color(
                                      0xFF64748B,
                                    ).withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    size: 13,
                                    color: Color(0xFF64748B),
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child:
                                  (widget.currentCetakan ?? '').isNotEmpty ||
                                      (widget.currentWarna ?? '').isNotEmpty ||
                                      (widget.currentMaterial ?? '').isNotEmpty
                                  ? Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if ((widget.currentCetakan ?? '')
                                            .isNotEmpty)
                                          _CurrentInfoChip(
                                            icon: Icons.view_in_ar_rounded,
                                            label: widget.currentCetakan!,
                                          ),
                                        if ((widget.currentWarna ?? '')
                                            .isNotEmpty)
                                          _CurrentInfoChip(
                                            icon: Icons.palette_outlined,
                                            label: widget.currentWarna!,
                                          ),
                                        if ((widget.currentMaterial ?? '')
                                            .isNotEmpty)
                                          _CurrentInfoChip(
                                            icon: Icons.category_outlined,
                                            label: widget.currentMaterial!,
                                          ),
                                      ],
                                    )
                                  : const Text(
                                      'Tidak ada informasi produksi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
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
                            border: Border.all(
                              color: accent.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: accent.withValues(alpha: 0.6),
                          ),
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
                                  child: Icon(
                                    Icons.fiber_new_rounded,
                                    size: 13,
                                    color: accent,
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.15),
                                ),
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
                                    child: Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Jam Mulai',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: accent.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _pickTime,
                                          child: Text(
                                            _hourCtrl.text.isNotEmpty
                                                ? _hourCtrl.text
                                                : '--:--',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: _hourCtrl.text.isNotEmpty
                                                  ? accent
                                                  : const Color(0xFFD1D5DB),
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _pickTime,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                    ),
                                    label: const Text(
                                      'Ubah',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),
                            const _SubSectionLabel(
                              label: 'CETAKAN, WARNA & MATERIAL',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.lockedIdCetakan != null
                                  ? 'Cetakan terkunci — pilih warna & material'
                                  : 'Pilih cetakan untuk produksi baru',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 14,
                                      color: Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFDC2626),
                                        ),
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
