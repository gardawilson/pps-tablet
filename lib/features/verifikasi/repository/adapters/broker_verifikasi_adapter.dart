// lib/features/verifikasi/repository/adapters/broker_verifikasi_adapter.dart

import '../../../production/broker/repository/broker_production_input_repository.dart';
import '../../../production/broker/repository/broker_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../verifikasi_adapter.dart';

class BrokerVerifikasiAdapter implements VerifikasiAdapter {
  final BrokerProductionRepository _repo;
  final BrokerProductionInputRepository _inputRepo;

  BrokerVerifikasiAdapter({
    BrokerProductionRepository? repo,
    BrokerProductionInputRepository? inputRepo,
  })  : _repo = repo ?? BrokerProductionRepository(),
        _inputRepo = inputRepo ?? BrokerProductionInputRepository();

  @override
  String get jenisKey => 'broker';

  @override
  String get jenisLabel => 'Broker';

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
        inputs.totalBeratBb() +
        inputs.totalBeratWashing() +
        inputs.totalBeratCrusher() +
        inputs.totalBeratGilingan() +
        inputs.totalBeratMixer() +
        inputs.totalBeratReject();
    return ProductionCrossCheckSummary(
      inputCounts: inputs.summary,
      totalInputBerat: totalInputBerat,
      outputs: outputs
          .map((o) => ProductionOutputSummary(
                namaJenis: o.namaJenis ?? '-',
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
