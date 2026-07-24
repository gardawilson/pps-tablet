// lib/features/verifikasi/repository/adapters/washing_verifikasi_adapter.dart

import '../../../production/washing/repository/washing_production_input_repository.dart';
import '../../../production/washing/repository/washing_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../verifikasi_adapter.dart';

class WashingVerifikasiAdapter implements VerifikasiAdapter {
  final WashingProductionRepository _repo;
  final WashingProductionInputRepository _inputRepo;

  WashingVerifikasiAdapter({
    WashingProductionRepository? repo,
    WashingProductionInputRepository? inputRepo,
  })  : _repo = repo ?? WashingProductionRepository(),
        _inputRepo = inputRepo ?? WashingProductionInputRepository();

  @override
  String get jenisKey => 'washing';

  @override
  String get jenisLabel => 'Washing';

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
    final totalInputBerat = inputs.totalBeratBb() +
        inputs.totalBeratWashing() +
        inputs.totalBeratGilingan();
    return ProductionCrossCheckSummary(
      inputCounts: inputs.summary,
      totalInputBerat: totalInputBerat,
      outputs: outputs
          .map((o) => ProductionOutputSummary(
                namaJenis: o.namaJenis,
                totalSak: o.totalSak,
                totalBerat: o.totalBerat,
              ))
          .toList(),
      totalOutputBerat: outputs.fold(0.0, (s, o) => s + o.totalBerat),
    );
  }

  @override
  Future<void> verify(String noProduksi, {String? note}) =>
      _repo.verifyProduksi(noProduksi, note: note);

  @override
  Future<void> unverify(String noProduksi, {String? note}) =>
      _repo.unverifyProduksi(noProduksi, note: note);
}
