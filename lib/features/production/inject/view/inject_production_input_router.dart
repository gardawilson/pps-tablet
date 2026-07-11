import 'package:flutter/material.dart';

import '../model/inject_production_model.dart';
import '../repository/inject_production_repository.dart';
import 'inject_production_input_screen.dart' as standard;
import 'inject_production_input_screen_v3.dart' as realtime;

/// Entry point tunggal untuk layar input produksi Inject.
///
/// Perbedaan nyata antara layar realtime (v3) dan non-realtime (v1) hanya pada
/// section output-nya:
///  - realtime      -> output berbasis batch/bucket per jam
///  - non-realtime  -> output label standar
///
/// Sebelumnya pemanggil harus menebak `isRealtime` sebelum navigasi. Saat
/// membuat produksi baru yang seharusnya realtime (rentang jam mencakup waktu
/// sekarang), response create belum membawa flag realtime yang akurat sehingga
/// bisa salah masuk ke layar non-realtime.
///
/// Router ini memuat header dari server lebih dulu, lalu memilih layar
/// berdasarkan `header.inputMode` (asal pembuatan) yang otoritatif:
///  - "realtime" (dibuat dari kartu mesin) -> v3
///  - "backdate" / null (dibuat dari FAB riwayat, atau data lama) -> v1
/// Pemanggil cukup memberi [noProduksi]; [isRealtimeHint] hanya dipakai sebagai
/// fallback bila header gagal dimuat.
class InjectProductionInputRouter extends StatefulWidget {
  const InjectProductionInputRouter({
    super.key,
    required this.noProduksi,
    this.isRealtimeHint,
  });

  final String noProduksi;

  /// Dugaan realtime dari pemanggil (mis. kartu mesin / baris riwayat).
  /// Hanya menjadi keputusan final bila header gagal dimuat.
  final bool? isRealtimeHint;

  @override
  State<InjectProductionInputRouter> createState() =>
      _InjectProductionInputRouterState();
}

class _InjectProductionInputRouterState
    extends State<InjectProductionInputRouter> {
  final _repo = InjectProductionRepository();

  bool _resolving = true;
  bool? _isRealtime;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    bool? realtime;
    try {
      final InjectProduction header = await _repo.fetchOne(widget.noProduksi);
      // Keputusan berbasis asal pembuatan (InputMode), bukan status waktu.
      realtime = header.isRealtimeInput;
    } catch (_) {
      // Header gagal dimuat -> pakai dugaan pemanggil (default non-realtime).
      realtime = widget.isRealtimeHint ?? false;
    }
    if (!mounted) return;
    setState(() {
      _isRealtime = realtime;
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving || _isRealtime == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isRealtime!
        ? realtime.InjectProductionInputScreen(noProduksi: widget.noProduksi)
        : standard.InjectProductionInputScreen(noProduksi: widget.noProduksi);
  }
}
