import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/inject_qc_model.dart';
import '../repository/inject_production_repository.dart';
import 'counter_picker_dialog.dart';

const _accent = Color(0xFF0277BD);
const _green = Color(0xFF15803D);

class InjectQcDialog extends StatefulWidget {
  const InjectQcDialog({
    super.key,
    required this.noProduksi,
    required this.hourStart,
    required this.hourEnd,
    this.shift,
    this.namaMesin,
    this.idMesin,
    this.outputJenisList = const [],
    this.tglProduksi,
  });

  final String noProduksi;
  final String hourStart;
  final String hourEnd;
  final int? shift;
  final String? namaMesin;
  final int? idMesin;
  final List<String> outputJenisList;
  final DateTime? tglProduksi;

  @override
  State<InjectQcDialog> createState() => _InjectQcDialogState();
}

enum _QcBucketStatus { locked, available, expired, submitted }

class _InjectQcDialogState extends State<InjectQcDialog> {
  final _repo = InjectProductionRepository();

  List<String> _bucketLabels = [];
  final Map<String, DateTime> _bucketStartTimes = {};
  final Map<String, DateTime> _bucketEndTimes = {};
  final Map<String, InjectQcItem?> _submitted = {};
  bool _isLoadingHistory = true;
  int? _counterCurrent;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _bucketLabels = _computeBuckets(
      widget.hourStart,
      widget.hourEnd,
      widget.tglProduksi,
    );
    _populateBucketTimes(widget.hourStart, widget.tglProduksi);
    _loadHistory();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  static List<String> _computeBuckets(
    String hourStart,
    String hourEnd,
    DateTime? tgl,
  ) {
    final startMin = _parseMinutes(hourStart);
    final endMin = _parseMinutes(hourEnd);
    if (startMin == null || endMin == null) return [];
    var duration = endMin - startMin;
    if (duration <= 0) duration += 24 * 60;
    if (duration <= 0) return [];
    final anchor = tgl != null
        ? DateTime(tgl.year, tgl.month, tgl.day)
        : DateTime.now();
    final startDt = anchor.add(Duration(minutes: startMin));
    final labels = <String>[];
    final startRem = startMin % 60;
    final firstStep = startRem == 0 ? 60 : (60 - startRem);
    var offset = 0;
    while (offset < duration) {
      final step = (offset == 0 && startRem != 0) ? firstStep : 60;
      final nextOffset = (offset + step) > duration ? duration : offset + step;
      final s = startDt.add(Duration(minutes: offset));
      final e = startDt.add(Duration(minutes: nextOffset));
      labels.add('${_fmt(s)} - ${_fmt(e)}');
      offset = nextOffset;
    }
    return labels;
  }

  static int? _parseMinutes(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _fmt(DateTime v) =>
      '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';

  void _populateBucketTimes(String hourStart, DateTime? tgl) {
    final startMin = _parseMinutes(hourStart);
    if (startMin == null) return;
    final anchor = tgl != null
        ? DateTime(tgl.year, tgl.month, tgl.day)
        : DateTime.now();
    final startDt = anchor.add(Duration(minutes: startMin));
    for (final label in _bucketLabels) {
      final parts = label.split(' - ');
      if (parts.length < 2) continue;
      final s = _parseMinutes(parts[0].trim());
      final e = _parseMinutes(parts[1].trim());
      if (s == null || e == null) continue;
      final sOffset = s - startMin;
      final eOffset = e > s ? e - startMin : e - startMin + 24 * 60;
      _bucketStartTimes[label] = startDt.add(Duration(minutes: sOffset));
      _bucketEndTimes[label] = startDt.add(Duration(minutes: eOffset));
    }
  }

  _QcBucketStatus _statusFor(String label) {
    if (_submitted[label] != null) return _QcBucketStatus.submitted;
    final startDt = _bucketStartTimes[label];
    final endDt = _bucketEndTimes[label];
    if (startDt == null || endDt == null) return _QcBucketStatus.locked;
    final now = DateTime.now();
    if (now.isBefore(startDt)) return _QcBucketStatus.locked;
    if (!now.isBefore(endDt)) return _QcBucketStatus.expired;
    return _QcBucketStatus.available;
  }

  // Edit hanya boleh selama waktu sekarang masih di dalam rentang bucket
  bool _canEditBucket(String label) {
    final startDt = _bucketStartTimes[label];
    final endDt = _bucketEndTimes[label];
    if (startDt == null || endDt == null) return false;
    final now = DateTime.now();
    return !now.isBefore(startDt) && now.isBefore(endDt);
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      // Ambil odometer/counter mesin sebagai default & batas minimum counter QC.
      if (widget.idMesin != null) {
        try {
          _counterCurrent = await _repo.fetchQcCounter(widget.idMesin!);
        } catch (_) {}
      }
      final items = await _repo.fetchQc(widget.noProduksi);
      if (!mounted) return;
      final map = <String, InjectQcItem?>{};
      for (final label in _bucketLabels) {
        final bucketHour = label.split(' - ').first.trim();
        map[label] = items.where((i) => i.hourStart == bucketHour).firstOrNull;
      }
      setState(() => _submitted.addAll(map));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _onSubmitted(String label, InjectQcItem item) {
    setState(() => _submitted[label] = item);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: Color(0xFFE2E6EA)),
            Flexible(
              child: _isLoadingHistory
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _bucketLabels.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Tidak ada range jam produksi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _bucketLabels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final label = _bucketLabels[i];
                        final hourStart = label.split(' - ').first.trim();
                        return _QcBucketRow(
                          label: label,
                          hourStart: hourStart,
                          noProduksi: widget.noProduksi,
                          submittedItem: _submitted[label],
                          status: _statusFor(label),
                          canEdit: _canEditBucket(label),
                          counterCurrent: _counterCurrent,
                          onSubmitted: (item) => _onSubmitted(label, item),
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

  Widget _buildHeader() {
    final tgl = widget.tglProduksi;
    final tglStr = tgl != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(tgl)
        : null;
    final dialogTitle = (widget.namaMesin ?? '').trim().isNotEmpty
        ? widget.namaMesin!.trim()
        : 'Input QC';
    final outputJenisList = widget.outputJenisList
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    final metaParts = <String>[
      if (tglStr != null) tglStr,
      if (widget.shift != null) 'Shift ${widget.shift}',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.checklist_outlined,
              size: 16,
              color: _accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dialogTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (outputJenisList.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: outputJenisList
                        .map(
                          (jenis) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              jenis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metaParts.join('\n'),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Bucket row ─────────────────────────────────────────────────────────────────

class _QcBucketRow extends StatefulWidget {
  const _QcBucketRow({
    required this.label,
    required this.hourStart,
    required this.noProduksi,
    required this.status,
    required this.canEdit,
    required this.onSubmitted,
    this.submittedItem,
    this.counterCurrent,
  });

  final String label;
  final String hourStart;
  final String noProduksi;
  final _QcBucketStatus status;
  final bool canEdit;
  final InjectQcItem? submittedItem;
  final int? counterCurrent;
  final ValueChanged<InjectQcItem> onSubmitted;

  @override
  State<_QcBucketRow> createState() => _QcBucketRowState();
}

class _QcBucketRowState extends State<_QcBucketRow> {
  final _repo = InjectProductionRepository();
  final _jumlahBsCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _cycleCtrl = TextEditingController();
  int _counterValue = 0;
  bool _isSubmitting = false;
  bool _isEditing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default counter mengikuti odometer mesin saat ini (batas minimum wajib).
    _counterValue = widget.counterCurrent ?? 0;
  }

  @override
  void dispose() {
    _jumlahBsCtrl.dispose();
    _beratCtrl.dispose();
    _cycleCtrl.dispose();
    super.dispose();
  }

  void _startEditing(InjectQcItem item) {
    _jumlahBsCtrl.text = item.jumlahBS.toString();
    _beratCtrl.text = item.berat?.toString() ?? '';
    _cycleCtrl.text = item.cycleTime?.toString() ?? '';
    _counterValue = item.counter ?? 0;
    setState(() {
      _isEditing = true;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final jumlahBS = int.tryParse(_jumlahBsCtrl.text.trim());
    if (jumlahBS == null || jumlahBS <= 0) {
      setState(() => _error = 'Jumlah BS wajib diisi');
      return;
    }
    final minCounter = widget.counterCurrent;
    if (minCounter != null && _counterValue < minCounter) {
      setState(() => _error = 'Counter minimal $minCounter');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{
        'noProduksi': widget.noProduksi,
        'hourStart': widget.hourStart,
        'jumlahBS': jumlahBS,
        'counter': _counterValue,
      };
      final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
      final cycle = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
      if (berat != null) payload['berat'] = berat;
      if (cycle != null) payload['cycleTime'] = cycle;

      final result = await _repo.submitQc(payload);
      if (!mounted) return;
      widget.onSubmitted(result);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEdit(int id) async {
    final jumlahBS = int.tryParse(_jumlahBsCtrl.text.trim());
    if (jumlahBS == null || jumlahBS <= 0) {
      setState(() => _error = 'Jumlah BS wajib diisi');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{
        'jumlahBS': jumlahBS,
        'counter': _counterValue,
      };
      final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
      final cycle = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
      if (berat != null) payload['berat'] = berat;
      if (cycle != null) payload['cycleTime'] = cycle;

      final result = await _repo.updateQc(id, payload);
      if (!mounted) return;
      setState(() => _isEditing = false);
      widget.onSubmitted(result);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted = widget.submittedItem;
    final status = widget.status;
    final isSubmitted = status == _QcBucketStatus.submitted;
    final isExpired = status == _QcBucketStatus.expired;
    final isLocked = status == _QcBucketStatus.locked;

    // Warna berdasarkan status
    final Color bgColor;
    final Color borderColor;
    final Color labelColor;
    if (isSubmitted) {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = _green.withValues(alpha: 0.30);
      labelColor = _green;
    } else if (isExpired) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5);
      labelColor = const Color(0xFFDC2626);
    } else if (isLocked) {
      bgColor = const Color(0xFFF9FAFB);
      borderColor = const Color(0xFFE5E7EB);
      labelColor = const Color(0xFF9CA3AF);
    } else {
      bgColor = const Color(0xFFF8FAFF);
      borderColor = _accent.withValues(alpha: 0.20);
      labelColor = _accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Jam label ─────────────────────────────────────────
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: labelColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (isSubmitted)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 11,
                        color: _green,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Tersimpan',
                        style: TextStyle(
                          fontSize: 9,
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else if (isExpired)
                  Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 11, color: labelColor),
                      const SizedBox(width: 3),
                      Text(
                        'Terlewat',
                        style: TextStyle(
                          fontSize: 9,
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else if (isLocked)
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 11, color: labelColor),
                      const SizedBox(width: 3),
                      Text(
                        'Terkunci',
                        style: TextStyle(
                          fontSize: 9,
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Fields / status info ──────────────────────────────
          Expanded(
            child: (isLocked || isExpired) && !isSubmitted
                ? _buildStatusInfo(isExpired)
                : _buildFields(isSubmitted && !_isEditing ? submitted : null),
          ),

          // ── Action buttons ────────────────────────────────────
          const SizedBox(width: 8),
          if (isSubmitted && !_isEditing)
            // Edit hanya tersedia selama masih dalam rentang waktu bucket
            widget.canEdit
                ? _actionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: const Color(0xFFF59E0B),
                    onTap: () => _startEditing(submitted!),
                  )
                : const SizedBox(width: 52)
          else if (isSubmitted && _isEditing)
            // Cancel + Save (edit mode)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionBtn(
                  icon: Icons.close,
                  label: 'Batal',
                  color: const Color(0xFF6B7280),
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() {
                          _isEditing = false;
                          _error = null;
                        }),
                ),
                const SizedBox(height: 4),
                _actionBtn(
                  icon: Icons.save_outlined,
                  label: 'Simpan',
                  color: _green,
                  onTap: _isSubmitting
                      ? null
                      : () => _submitEdit(submitted!.id),
                  isLoading: _isSubmitting,
                ),
              ],
            )
          else if (!isLocked && !isExpired)
            // New submit button — hanya saat available
            _actionBtn(
              icon: Icons.save_outlined,
              label: 'Simpan',
              color: _accent,
              onTap: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            )
          else
            const SizedBox(width: 52),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(bool isExpired) {
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel_outlined,
              size: 13,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Jam ini sudah lewat dan tidak diinput',
                style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 13, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Selesaikan range jam sebelumnya terlebih dahulu',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(InjectQcItem? submitted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                'Jumlah BS (pcs)',
                _jumlahBsCtrl,
                '0',
                false,
                readOnly: submitted != null,
                readOnlyValue: submitted?.jumlahBS.toString(),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _field(
                'Berat (gr)',
                _beratCtrl,
                '0.0',
                true,
                readOnly: submitted != null,
                readOnlyValue: submitted?.berat?.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _field(
                'Cycle (s)',
                _cycleCtrl,
                '0.0',
                true,
                readOnly: submitted != null,
                readOnlyValue: submitted?.cycleTime?.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildCounterField(readOnlyValue: submitted?.counter),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(
            _error!,
            style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626)),
          ),
        ],
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint,
    bool decimal, {
    bool readOnly = false,
    String? readOnlyValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 30,
          child: TextField(
            controller: ctrl
              ..text = readOnly ? (readOnlyValue ?? '-') : ctrl.text,
            readOnly: readOnly,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: readOnly ? _green : const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: (readOnly ? _green : _accent).withValues(alpha: 0.25),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: (readOnly ? _green : _accent).withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? _green : _accent,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF0FDF4) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: color,
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCounterField({int? readOnlyValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Counter',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: readOnlyValue != null
              ? null
              : () async {
                  final picked = await showDialog<int>(
                    context: context,
                    builder: (_) => CounterPickerDialog(
                      initialValue: _counterValue,
                      minValue: widget.counterCurrent,
                    ),
                  );
                  if (picked != null && mounted)
                    setState(() => _counterValue = picked);
                },
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: readOnlyValue != null
                  ? const Color(0xFFF0FDF4)
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: readOnlyValue != null
                    ? _green.withValues(alpha: 0.25)
                    : _accent,
                width: readOnlyValue != null ? 1.0 : 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${readOnlyValue ?? _counterValue}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: readOnlyValue != null ? _green : _accent,
                  ),
                ),
                if (readOnlyValue == null) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.expand_more, size: 12, color: _accent),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
