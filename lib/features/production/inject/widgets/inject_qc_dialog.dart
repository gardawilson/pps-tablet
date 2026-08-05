import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/inject_qc_model.dart';
import '../repository/inject_production_repository.dart';
import 'counter_picker_dialog.dart';

const _accent = Color(0xFF0277BD);
const _green = Color(0xFF15803D);
const _downtimeColor = Color(0xFFB45309);

// Jeda setelah jam akhir bucket sebelum QC bisa diinput (mis. range
// 07:00-08:00 langsung bisa diinput mulai jam 08:00, begitu jamnya
// berakhir). Window bucket berikutnya selalu dimulai tepat saat window
// bucket ini tertutup, jadi tidak pernah ada 2 hour range yang available
// bersamaan — sama seperti layar input produksi
// (inject_production_input_screen_v3.dart).
const _kQcInputOpenDelay = Duration.zero;

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
  // Waktu window QC bucket ini terbuka (endDt + _kQcInputOpenDelay).
  final Map<String, DateTime> _bucketOpensAt = {};
  final Map<String, InjectQcItem?> _submitted = {};
  bool _isLoadingHistory = true;
  int? _counterCurrent;
  bool _isResettingCounter = false;
  Timer? _statusTimer;
  // Tanggal produksi terkini (dari endpoint QC), fallback ke nilai awal dari
  // pemanggil selama data belum dimuat.
  DateTime? _tglProduksi;

  @override
  void initState() {
    super.initState();
    _tglProduksi = widget.tglProduksi;
    _loadHistory();
    // Tick tiap detik supaya countdown buka/tutup window responsif (mm:ss).
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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

      // Jam setelah tengah malam harus ditempatkan pada hari berikutnya.
      // Contoh shift 23:00-07:00:
      // 00:00 => offset 60 menit, bukan -1380 menit (hari sebelumnya).
      var sOffset = s - startMin;
      if (sOffset < 0) sOffset += 24 * 60;
      var eOffset = e - startMin;
      if (eOffset <= sOffset) eOffset += 24 * 60;

      _bucketStartTimes[label] = startDt.add(Duration(minutes: sOffset));
      final endDt = startDt.add(Duration(minutes: eOffset));
      _bucketEndTimes[label] = endDt;
      _bucketOpensAt[label] = endDt.add(_kQcInputOpenDelay);
    }
  }

  // Waktu window bucket ini tertutup = waktu window bucket berikutnya
  // terbuka. Bucket terakhir tidak punya bucket berikutnya, jadi ditutup
  // 1 jam setelah terbuka — durasi yang sama dengan window bucket lain.
  DateTime? _closesAtFor(String label) {
    final idx = _bucketLabels.indexOf(label);
    if (idx == -1) return null;
    if (idx + 1 < _bucketLabels.length) {
      return _bucketOpensAt[_bucketLabels[idx + 1]];
    }
    return _bucketOpensAt[label]?.add(const Duration(hours: 1));
  }

  bool _isWithinInputWindow(String label) {
    final opensAt = _bucketOpensAt[label];
    if (opensAt == null) return false;
    final now = DateTime.now();
    if (now.isBefore(opensAt)) return false;
    final closesAt = _closesAtFor(label);
    if (closesAt != null && !now.isBefore(closesAt)) return false;
    return true;
  }

  _QcBucketStatus _statusFor(String label) {
    if (_submitted[label] != null) return _QcBucketStatus.submitted;
    final opensAt = _bucketOpensAt[label];
    if (opensAt == null) return _QcBucketStatus.locked;
    if (_isWithinInputWindow(label)) return _QcBucketStatus.available;
    final now = DateTime.now();
    if (now.isBefore(opensAt)) return _QcBucketStatus.locked;
    return _QcBucketStatus.expired;
  }

  // Edit hanya boleh selama window input bucket ini masih terbuka.
  bool _canEditBucket(String label) => _isWithinInputWindow(label);

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      // Ambil odometer/counter mesin sebagai default & batas minimum counter QC.
      if (widget.idMesin != null) {
        try {
          _counterCurrent = await _repo.fetchQcCounter(widget.idMesin!);
        } catch (_) {}
      }
      final detail = await _repo.fetchQcDetail(widget.noProduksi);
      if (!mounted) return;
      _tglProduksi = detail.header.tglProduksi ?? widget.tglProduksi;
      // createdAt mencerminkan tanggal kalender sebenarnya saat bucket jam
      // ini berjalan (tidak seperti tglProduksi yang tetap di tanggal awal
      // shift), jadi dipakai sebagai acuan anchor tanggal bucket.
      final anchor = detail.header.createdAt ?? _tglProduksi;
      _bucketLabels = _computeBuckets(widget.hourStart, widget.hourEnd, anchor);
      _populateBucketTimes(widget.hourStart, anchor);
      final map = <String, InjectQcItem?>{};
      for (final label in _bucketLabels) {
        final bucketHour = label.split(' - ').first.trim();
        map[label] = detail.items
            .where((i) => i.hourStart == bucketHour)
            .firstOrNull;
      }
      setState(() => _submitted.addAll(map));
    } catch (_) {
      // Fallback: tetap tampilkan bucket dari data awal bila endpoint gagal.
      _bucketLabels = _computeBuckets(
        widget.hourStart,
        widget.hourEnd,
        widget.tglProduksi,
      );
      _populateBucketTimes(widget.hourStart, widget.tglProduksi);
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _onSubmitted(String label, InjectQcItem item) {
    setState(() => _submitted[label] = item);
  }

  Future<void> _confirmResetCounter() async {
    final idMesin = widget.idMesin;
    if (idMesin == null || _isResettingCounter) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Counter Mesin'),
        content: Text(
          'Counter mesin${(widget.namaMesin ?? '').trim().isNotEmpty ? ' "${widget.namaMesin}"' : ''} '
          'saat ini ${_counterCurrent != null ? "adalah $_counterCurrent dan " : ""}'
          'akan direset ke 0. Tindakan ini tidak dapat dibatalkan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _downtimeColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isResettingCounter = true);
    try {
      final newCounter = await _repo.resetQcCounter(idMesin);
      if (!mounted) return;
      setState(() => _counterCurrent = newCounter);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Counter mesin berhasil direset')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isResettingCounter = false);
    }
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
            _buildMetaStrip(),
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
                          windowOpensAt: _bucketOpensAt[label],
                          windowClosesAt: _closesAtFor(label),
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

  // Header: judul + data berlabel (Tanggal · Shift · Jam) dalam panel accent.
  Widget _buildHeader() {
    final machineName = (widget.namaMesin ?? '').trim();
    final tgl = _tglProduksi;
    final tglStr = tgl != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(tgl)
        : '-';

    return Container(
      decoration: const BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Judul ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'INPUT QC',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            machineName.isNotEmpty
                                ? machineName
                                : 'Quality Control',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (widget.idMesin != null) ...[
                          const SizedBox(width: 8),
                          _buildResetCounterButton(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _headerCloseButton(),
            ],
          ),
          const SizedBox(height: 10),
          // ── Chip data: ikon sebagai label (tanggal · shift · jam) ─
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _headerChip(Icons.calendar_today_outlined, tglStr),
              _headerChip(
                Icons.groups_outlined,
                'Shift ${widget.shift ?? '-'}',
              ),
              _headerChip(
                Icons.access_time_rounded,
                '${widget.hourStart}–${widget.hourEnd}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Chip translucent putih: ikon sebagai label, nilai di sampingnya.
  Widget _headerChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Sub-header: hanya jenis output, dengan label yang jelas.
  Widget _buildMetaStrip() {
    final outputJenis = widget.outputJenisList
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .join(', ');

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, size: 14, color: _accent),
          const SizedBox(width: 8),
          const Text(
            'OUTPUT',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              outputJenis.isNotEmpty ? outputJenis : '-',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tombol reset counter/odometer mesin, ditaruh sejajar dengan nama mesin
  // di header karena aksi ini terikat langsung ke mesin tsb, bukan ke jam
  // atau produk yang sedang di-QC.
  Widget _buildResetCounterButton() {
    return Tooltip(
      message: _counterCurrent != null
          ? 'Counter mesin saat ini: $_counterCurrent. Ketuk untuk reset ke 0.'
          : 'Reset counter mesin ke 0',
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _isResettingCounter ? null : _confirmResetCounter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isResettingCounter
                    ? const SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.restart_alt_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                const SizedBox(width: 4),
                Text(
                  _counterCurrent != null
                      ? 'Counter: $_counterCurrent'
                      : 'Reset Counter',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCloseButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close, size: 18, color: Colors.white),
        ),
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
    this.windowOpensAt,
    this.windowClosesAt,
  });

  final String label;
  final String hourStart;
  final String noProduksi;
  final _QcBucketStatus status;
  final bool canEdit;
  final InjectQcItem? submittedItem;
  final int? counterCurrent;
  // Waktu window bucket ini terbuka — dipakai untuk countdown saat locked.
  final DateTime? windowOpensAt;
  // Waktu window bucket ini tertutup — dipakai untuk countdown saat available.
  final DateTime? windowClosesAt;
  final ValueChanged<InjectQcItem> onSubmitted;

  @override
  State<_QcBucketRow> createState() => _QcBucketRowState();
}

class _QcBucketRowState extends State<_QcBucketRow> {
  final _repo = InjectProductionRepository();
  final _jumlahBsCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _cycleCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  int _counterValue = 0;
  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isDowntime = false;
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
    _keteranganCtrl.dispose();
    super.dispose();
  }

  void _startEditing(InjectQcItem item) {
    _jumlahBsCtrl.text = item.jumlahBS.toString();
    _beratCtrl.text = item.berat?.toString() ?? '';
    _cycleCtrl.text = item.cycleTime?.toString() ?? '';
    _counterValue = item.counter ?? 0;
    _keteranganCtrl.text = item.keterangan ?? '';
    setState(() {
      _isEditing = true;
      _isDowntime = item.isDowntime;
      _error = null;
    });
  }

  Map<String, dynamic>? _buildDowntimePayload() {
    final keterangan = _keteranganCtrl.text.trim();
    if (keterangan.isEmpty) {
      setState(() => _error = 'Keterangan wajib diisi untuk downtime');
      return null;
    }
    return <String, dynamic>{
      'noProduksi': widget.noProduksi,
      'hourStart': widget.hourStart,
      'isDowntime': true,
      'keterangan': keterangan,
    };
  }

  Future<void> _submit() async {
    final Map<String, dynamic> payload;
    if (_isDowntime) {
      final downtimePayload = _buildDowntimePayload();
      if (downtimePayload == null) return;
      payload = downtimePayload;
    } else {
      final jumlahBsText = _jumlahBsCtrl.text.trim();
      final jumlahBS = jumlahBsText.isEmpty ? 0 : int.tryParse(jumlahBsText);
      if (jumlahBS == null || jumlahBS < 0) {
        setState(() => _error = 'Jumlah BS tidak valid');
        return;
      }
      final minCounter = widget.counterCurrent;
      if (minCounter != null && _counterValue < minCounter) {
        setState(() => _error = 'Counter minimal $minCounter');
        return;
      }
      payload = <String, dynamic>{
        'noProduksi': widget.noProduksi,
        'hourStart': widget.hourStart,
        'jumlahBS': jumlahBS,
        'counter': _counterValue,
        'isDowntime': false,
      };
      final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
      final cycle = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
      if (berat != null) payload['berat'] = berat;
      if (cycle != null) payload['cycleTime'] = cycle;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
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
    final Map<String, dynamic> payload;
    if (_isDowntime) {
      final downtimePayload = _buildDowntimePayload();
      if (downtimePayload == null) return;
      payload = downtimePayload;
    } else {
      final jumlahBsText = _jumlahBsCtrl.text.trim();
      final jumlahBS = jumlahBsText.isEmpty ? 0 : int.tryParse(jumlahBsText);
      if (jumlahBS == null || jumlahBS < 0) {
        setState(() => _error = 'Jumlah BS tidak valid');
        return;
      }
      payload = <String, dynamic>{
        'noProduksi': widget.noProduksi,
        'hourStart': widget.hourStart,
        'jumlahBS': jumlahBS,
        'counter': _counterValue,
        'isDowntime': false,
        'keterangan': null,
      };
      final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
      final cycle = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
      payload['berat'] = berat;
      payload['cycleTime'] = cycle;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result = await _repo.updateQc(id, payload);
      if (!mounted) return;
      setState(() => _isEditing = false);
      widget.onSubmitted(result);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted = widget.submittedItem;
    final status = widget.status;
    final isSubmitted = status == _QcBucketStatus.submitted;
    final isSubmittedDowntime = isSubmitted && submitted?.isDowntime == true;
    final isExpired = status == _QcBucketStatus.expired;
    final isLocked = status == _QcBucketStatus.locked;

    // Warna berdasarkan status
    final Color bgColor;
    final Color borderColor;
    final Color labelColor;
    if (isSubmittedDowntime) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = _downtimeColor.withValues(alpha: 0.30);
      labelColor = _downtimeColor;
    } else if (isSubmitted) {
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

    // Badge status ditaruh sebaris dengan label jam (bukan bertumpuk).
    Widget? statusBadge;
    if (isSubmittedDowntime) {
      statusBadge = _statusChip(
        Icons.playlist_remove_rounded,
        'Downtime',
        _downtimeColor,
      );
    } else if (isSubmitted) {
      statusBadge = _statusChip(
        Icons.check_circle_outline,
        'Tersimpan',
        _green,
      );
    } else if (isExpired) {
      statusBadge = _statusChip(Icons.cancel_outlined, 'Terlewat', labelColor);
    } else if (isLocked) {
      statusBadge = _statusChip(Icons.lock_outline, 'Terkunci', labelColor);
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
          // ── Status + jam label (satu baris, badge di kiri) ────
          if (statusBadge != null) ...[statusBadge, const SizedBox(width: 6)],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
            // Downtime + Simpan sejajar; Batal tetap terpisah di mode edit.
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDowntimeAction(),
                    const SizedBox(width: 5),
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
                ),
              ],
            )
          else if (!isLocked && !isExpired)
            // New submit button — hanya saat available
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDowntimeAction(),
                const SizedBox(width: 6),
                _actionBtn(
                  icon: Icons.save_outlined,
                  label: 'Simpan',
                  color: _accent,
                  onTap: _isSubmitting ? null : _submit,
                  isLoading: _isSubmitting,
                ),
              ],
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Belum waktunya input untuk jam ini',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
          if (widget.windowOpensAt != null) ...[
            const SizedBox(height: 6),
            _QcWindowCountdown(
              targetTime: widget.windowOpensAt!,
              label: 'Terbuka dalam',
              icon: Icons.hourglass_bottom_rounded,
              color: const Color(0xFF64748B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDowntimeAction() {
    final active = _isDowntime;
    final label = active ? 'Batalkan downtime' : 'Catat downtime QC';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        toggled: active,
        label: label,
        child: SizedBox(
          height: 30,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _isDowntime = !active;
              _error = null;
            }),
            style: OutlinedButton.styleFrom(
              backgroundColor: active
                  ? _downtimeColor.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.75),
              foregroundColor: active ? _downtimeColor : Colors.grey.shade600,
              side: BorderSide(
                color: active
                    ? _downtimeColor.withValues(alpha: 0.50)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: Icon(
              active ? Icons.undo_rounded : Icons.playlist_remove_rounded,
              size: 15,
            ),
            label: Text(active ? 'Batalkan' : 'Downtime'),
          ),
        ),
      ),
    );
  }

  Widget _buildDowntimeKeteranganField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Keterangan (wajib)',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: _keteranganCtrl,
          maxLength: 500,
          maxLines: 2,
          minLines: 1,
          autofocus: true,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            hintText: 'Alasan downtime, mis. listrik padam...',
            hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            isDense: true,
            counterStyle: const TextStyle(fontSize: 9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 7,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: _downtimeColor.withValues(alpha: 0.35),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: _downtimeColor.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _downtimeColor, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittedDowntime(InjectQcItem submitted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _downtimeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _downtimeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.playlist_remove_rounded,
                size: 13,
                color: _downtimeColor,
              ),
              SizedBox(width: 5),
              Text(
                'Downtime',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _downtimeColor,
                ),
              ),
            ],
          ),
          if ((submitted.keterangan ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              submitted.keterangan!.trim(),
              style: const TextStyle(fontSize: 10, color: Color(0xFF374151)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFields(InjectQcItem? submitted) {
    final isReadOnly = submitted != null;
    if (submitted?.isDowntime == true) {
      return _buildSubmittedDowntime(submitted!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isDowntime && !isReadOnly)
          _buildDowntimeKeteranganField()
        else
          Row(
            children: [
              Expanded(
                child: _field(
                  'Jumlah BS (pcs)',
                  _jumlahBsCtrl,
                  '0',
                  false,
                  readOnly: isReadOnly,
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
                  readOnly: isReadOnly,
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
                  readOnly: isReadOnly,
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
        if (widget.status == _QcBucketStatus.available &&
            widget.windowClosesAt != null) ...[
          const SizedBox(height: 4),
          _QcWindowCountdown(
            targetTime: widget.windowClosesAt!,
            label: 'Tertutup dalam',
            icon: Icons.timer_outlined,
            color: const Color(0xFFB45309),
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
      width: 44,
      height: 44,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : Tooltip(
                  message: label,
                  child: Center(
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
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
                  if (picked != null && mounted) {
                    setState(() => _counterValue = picked);
                  }
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

// ── Window countdown ───────────────────────────────────────────────────────

/// Hitung mundur generik menuju [targetTime] (buka/tutup window QC).
/// Rebuild tiap detik dibawa oleh `_statusTimer` di parent dialog — widget
/// ini hanya membaca `DateTime.now()` di tiap build agar HH:MM:SS responsif.
class _QcWindowCountdown extends StatelessWidget {
  const _QcWindowCountdown({
    required this.targetTime,
    required this.label,
    required this.icon,
    required this.color,
  });

  final DateTime targetTime;
  final String label;
  final IconData icon;
  final Color color;

  String _formatRemaining(Duration d) {
    final clamped = d.isNegative ? Duration.zero : d;
    final hours = clamped.inHours;
    final minutes = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = targetTime.difference(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '$label ${_formatRemaining(remaining)}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
