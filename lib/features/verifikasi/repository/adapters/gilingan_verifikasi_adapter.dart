// lib/features/verifikasi/repository/adapters/gilingan_verifikasi_adapter.dart

import '../../../production/gilingan/repository/gilingan_production_input_repository.dart';
import '../../../production/gilingan/repository/gilingan_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../verifikasi_adapter.dart';

class GilinganVerifikasiAdapter implements VerifikasiAdapter {
  final GilinganProductionRepository _repo;
  final GilinganProductionInputRepository _inputRepo;

  GilinganVerifikasiAdapter({
    GilinganProductionRepository? repo,
    GilinganProductionInputRepository? inputRepo,
  })  : _repo = repo ?? GilinganProductionRepository(),
        _inputRepo = inputRepo ?? GilinganProductionInputRepository();

  @override
  String get jenisKey => 'gilingan';

  @override
  String get jenisLabel => 'Gilingan';

  @override
  Future<List<VerifikasiItem>> fetchPending() async {
    final items = await _repo.fetchAllList(
      page: 1,
      pageSize: 100,
      complete: true,
      verified: false,
    );
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
    final outputs = await _inputRepo.fetchOutputs(noProduksi);
    final totalInputBerat = inputs.totalBeratBroker() +
        inputs.totalBeratBonggolan() +
        inputs.totalBeratCrusher() +
        inputs.totalBeratReject();

    // GilinganOutput adalah per-label (bukan sudah dikelompokkan), jadi
    // dikelompokkan dulu per namaJenis untuk ringkasan.
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
      totalInputBerat: totalInputBerat,
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
