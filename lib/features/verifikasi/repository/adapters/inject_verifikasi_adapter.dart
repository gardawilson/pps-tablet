// lib/features/verifikasi/repository/adapters/inject_verifikasi_adapter.dart

import '../../../production/inject/model/inject_production_model.dart';
import '../../../production/inject/repository/inject_production_input_repository.dart';
import '../../../production/inject/repository/inject_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../verifikasi_adapter.dart';

class InjectVerifikasiAdapter implements VerifikasiAdapter {
  final InjectProductionRepository _repo;
  final InjectProductionInputRepository _inputRepo;

  InjectVerifikasiAdapter({
    InjectProductionRepository? repo,
    InjectProductionInputRepository? inputRepo,
  })  : _repo = repo ?? InjectProductionRepository(),
        _inputRepo = inputRepo ?? InjectProductionInputRepository();

  @override
  String get jenisKey => 'inject';

  @override
  String get jenisLabel => 'Inject';

  @override
  Future<List<VerifikasiItem>> fetchPending() async {
    final result = await _repo.fetchAll(
      page: 1,
      pageSize: 100,
      complete: true,
      verified: false,
    );
    final items = result['items'] as List<InjectProduction>;
    return items
        .map((p) => VerifikasiItem(
              noProduksi: p.noProduksi,
              jenisKey: jenisKey,
              jenisLabel: jenisLabel,
              tglProduksi: p.tglProduksi,
              namaMesin: p.namaMesin,
              shift: p.shift,
              verified: p.verified,
              verifiedByUsername: p.verifiedByUsername,
              verifiedAt: p.verifiedAt,
            ))
        .toList();
  }

  @override
  Future<ProductionCrossCheckSummary> fetchCrossCheck(String noProduksi) async {
    final inputs = await _inputRepo.fetchInputs(noProduksi, force: true);
    final outputs = await _inputRepo.fetchOutputs(noProduksi, force: true);

    // InjectOutputItem adalah per-label, dikelompokkan per namaJenis.
    final grouped = <String, List<double>>{};
    for (final o in outputs) {
      grouped.putIfAbsent(o.namaJenis, () => []).add(o.berat);
    }
    final outputSummaries = grouped.entries
        .map((e) => ProductionOutputSummary(
              namaJenis: e.key,
              totalSak: e.value.length,
              totalBerat: e.value.fold(0.0, (s, b) => s + b),
            ))
        .toList();

    return ProductionCrossCheckSummary(
      inputCounts: inputs.summary,
      totalInputBerat: inputs.totalBerat(),
      outputs: outputSummaries,
      totalOutputBerat: outputSummaries.fold(0.0, (s, o) => s + o.totalBerat),
    );
  }

  @override
  Future<void> verify(String noProduksi, {String? note}) =>
      _repo.verifyProduksi(noProduksi, note: note);

  @override
  Future<void> unverify(String noProduksi, {String? note}) =>
      _repo.unverifyProduksi(noProduksi, note: note);
}
