import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../common/widgets/info_box.dart';
import '../../../../core/utils/rawbt_print_service.dart';

typedef GenerateSameCallback = Future<List<dynamic>> Function();

class RawBTAutoPrintDialog extends StatefulWidget {
  final List<dynamic> headers;

  /// total label berhasil dibuat (create)
  final int count;

  final String reportName;
  final String baseUrl;
  final GenerateSameCallback onGenerateSame;

  const RawBTAutoPrintDialog({
    super.key,
    required this.headers,
    required this.count,
    required this.reportName,
    required this.baseUrl,
    required this.onGenerateSame,
  });

  @override
  State<RawBTAutoPrintDialog> createState() => _RawBTAutoPrintDialogState();
}

class _RawBTAutoPrintDialogState extends State<RawBTAutoPrintDialog> {
  int _currentIndex = 0;

  bool _busy = false;
  bool _lastOpenSuccess = false;

  String _status = 'Cetak ulang atau buat label baru dengan detail yang sama.';
  String? _error;

  late final RawBTPrintService _rawBTService;

  late List<dynamic> _headers;

  /// ✅ total label created (bukan printed)
  late int _count;

  @override
  void initState() {
    super.initState();
    _rawBTService = RawBTPrintService(
      baseUrl: widget.baseUrl,
      defaultSystem: 'pps',
    );

    _headers = List<dynamic>.from(widget.headers);

    // sumber utama: count dari backend (create)
    _count = widget.count > 0 ? widget.count : _headers.length;

    // safety: kalau headers > count, tetap tampil count sebagai headers length agar tidak "aneh"
    if (_headers.length > _count) _count = _headers.length;
  }

  @override
  void dispose() {
    _rawBTService.dispose();
    super.dispose();
  }

  String get _currentNoBJ {
    if (_headers.isEmpty || _currentIndex >= _headers.length) return '-';
    return _headers[_currentIndex]['NoBJ']?.toString() ?? '-';
  }

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex < _headers.length - 1;

  /// ✅ 1-based position for UI: "10/10"
  int get _pos => (_headers.isEmpty) ? 0 : (_currentIndex + 1);

  Color _toneColor() {
    if (_error != null) return Colors.red.shade700;
    if (_lastOpenSuccess) return Colors.green.shade700;
    return Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneColor();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== Title =====
              Row(
                children: [
                  Icon(Icons.print, color: tone),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cetak Label (Auto)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Tutup',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ===== Current label =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ posisi "10/10" (berubah saat prev/next)
                          Text(
                            '${_pos}/${_count}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentNoBJ,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy NoBJ',
                      onPressed: (_currentNoBJ == '-' || _busy)
                          ? null
                          : () async {
                        await Clipboard.setData(ClipboardData(text: _currentNoBJ));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tersalin: $_currentNoBJ'),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ===== Status / Error (fixed height + loader inside) =====
              InfoBox(
                height: 78,
                busy: _busy,
                isError: _error != null,
                icon: _error != null
                    ? Icons.error_outline
                    : (_lastOpenSuccess ? Icons.check_circle_outline : Icons.info_outline),
                iconColor: _error != null ? Colors.red.shade700 : tone,
                text: _error ?? _status,
              ),

              const SizedBox(height: 14),

              // ===== Main button =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _openRawBT,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'PRINT',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ===== Secondary buttons =====
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : (_hasPrev ? _prev : null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SEBELUMNYA'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : (_hasNext ? _next : null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('BERIKUTNYA'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ===== Generate new label (same data) =====
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _generateNewLabelSameData,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'BUAT LABEL BARU (DATA SAMA)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Pastikan RawBT sudah terinstall & printer terhubung.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _prev() {
    if (!_hasPrev) return;
    setState(() {
      _currentIndex--;
      _error = null;
      _lastOpenSuccess = false;
      _status = 'Cetak ulang atau buat label baru dengan detail yang sama.';
    });
  }

  void _next() {
    if (!_hasNext) return;
    setState(() {
      _currentIndex++;
      _error = null;
      _lastOpenSuccess = false;
      _status = 'Cetak ulang atau buat label baru dengan detail yang sama.';
    });
  }

  Future<void> _openRawBT() async {
    if (!mounted) return;
    if (_headers.isEmpty || _currentIndex >= _headers.length) return;

    setState(() {
      _busy = true;
      _error = null;
      _lastOpenSuccess = false;
      _status = 'Membuka label di RawBT...';
    });

    final noBJ = _currentNoBJ;

    try {
      final ok = await _rawBTService.printLabelViaRawBT(
        reportName: widget.reportName,
        query: {'NoBJ': noBJ},
        onStatus: (s) {
          if (mounted) setState(() => _status = s);
        },
        onError: (e) {
          if (mounted) setState(() => _error = e);
        },
      );

      if (!mounted) return;

      setState(() => _busy = false);

      if (ok) {
        setState(() {
          _lastOpenSuccess = true;
          _status = 'Label $noBJ terbuka di RawBT.';
          _error = null;
        });

        // auto advance kalau masih ada
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;

        if (_hasNext) {
          setState(() {
            _currentIndex++;
            _lastOpenSuccess = false;
            _status = 'Siap untuk label berikutnya.';
          });
        } else {
          setState(() {
            _status = 'Berhasil membuat label baru.';
          });
        }
      } else {
        setState(() {
          _error ??= 'Gagal membuka RawBT. Pastikan RawBT terinstall.';
          _status = 'Gagal. Coba lagi.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Error: ${e.toString()}';
        _status = 'Terjadi kesalahan.';
      });
    }
  }

  Future<void> _generateNewLabelSameData() async {
    if (!mounted) return;

    setState(() {
      _busy = true;
      _error = null;
      _lastOpenSuccess = false;
      _status = 'Membuat label baru (data sama)...';
    });

    try {
      final newHeaders = await widget.onGenerateSame();

      if (!mounted) return;

      if (newHeaders.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'Gagal membuat label baru.';
          _status = 'Coba lagi.';
        });
        return;
      }

      setState(() {
        _headers.addAll(newHeaders);

        // ✅ total create bertambah sesuai jumlah label yang di-create pada aksi ini
        _count += newHeaders.length;

        // arahkan ke label terbaru
        _currentIndex = _headers.length - 1;

        _busy = false;
        _status = 'Label baru dibuat. Membuka RawBT...';
      });

      await _openRawBT();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Error: ${e.toString()}';
        _status = 'Terjadi kesalahan.';
      });
    }
  }
}