// lib/features/verifikasi/repository/verifikasi_repository.dart

import '../model/verifikasi_models.dart';
import 'adapters/broker_verifikasi_adapter.dart';
import 'adapters/gilingan_verifikasi_adapter.dart';
import 'adapters/inject_verifikasi_adapter.dart';
import 'adapters/washing_verifikasi_adapter.dart';
import 'verifikasi_adapter.dart';

/// Orchestrator lintas jenis produksi. Tidak ada endpoint agregat di
/// backend, jadi setiap jenis produksi punya adapter sendiri dan hasilnya
/// digabung di sini. Menambah jenis produksi baru = tambah satu adapter.
class VerifikasiRepository {
  final List<VerifikasiAdapter> adapters;

  VerifikasiRepository({List<VerifikasiAdapter>? adapters})
      : adapters = adapters ??
            [
              WashingVerifikasiAdapter(),
              BrokerVerifikasiAdapter(),
              GilinganVerifikasiAdapter(),
              InjectVerifikasiAdapter(),
            ];

  VerifikasiAdapter _adapterFor(String jenisKey) =>
      adapters.firstWhere((a) => a.jenisKey == jenisKey);

  Future<List<VerifikasiItem>> fetchPending({String? jenisKey}) async {
    final selected = jenisKey == null
        ? adapters
        : adapters.where((a) => a.jenisKey == jenisKey).toList();

    final results = await Future.wait(
      selected.map(
        (a) async {
          try {
            return await a.fetchPending();
          } catch (_) {
            return <VerifikasiItem>[];
          }
        },
      ),
    );

    final items = results.expand((x) => x).toList();
    items.sort((a, b) {
      final ta = a.tglProduksi ?? DateTime(0);
      final tb = b.tglProduksi ?? DateTime(0);
      return tb.compareTo(ta);
    });
    return items;
  }

  Future<ProductionCrossCheckSummary> fetchCrossCheck(
    String jenisKey,
    String noProduksi,
  ) {
    return _adapterFor(jenisKey).fetchCrossCheck(noProduksi);
  }

  Future<void> verify(String jenisKey, String noProduksi, {String? note}) {
    return _adapterFor(jenisKey).verify(noProduksi, note: note);
  }

  Future<void> unverify(String jenisKey, String noProduksi, {String? note}) {
    return _adapterFor(jenisKey).unverify(noProduksi, note: note);
  }
}
