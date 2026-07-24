// lib/features/verifikasi/repository/adapters/broker_verifikasi_adapter.dart

import '../../../production/broker/repository/broker_production_input_repository.dart';
import '../../../production/broker/repository/broker_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../verifikasi_adapter.dart';
import 'production_grouping.dart';

String? _s(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

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
              hourStart: p.hourStart,
              hourEnd: p.hourEnd,
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

    final inputGroups = [
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Broker',
        items: inputs.broker,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noBrokerPartial) ?? _s(i.noBroker) ?? '-',
        beratOf: (i) => i.berat ?? 0.0,
      ),
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Bahan Baku',
        items: inputs.bb,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) {
          final partial = _s(i.noBBPartial);
          if (partial != null) return partial;
          final base = _s(i.noBahanBaku) ?? '-';
          final pal = i.noPallet;
          return (pal == null || pal == 0) ? base : '$base-$pal';
        },
        beratOf: (i) => i.berat ?? 0.0,
      ),
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Washing',
        items: inputs.washing,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noWashing) ?? '-',
        beratOf: (i) => i.berat ?? 0.0,
      ),
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Crusher',
        items: inputs.crusher,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noCrusher) ?? '-',
        beratOf: (i) => i.berat ?? 0.0,
      ),
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Gilingan',
        items: inputs.gilingan,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noGilinganPartial) ?? _s(i.noGilingan) ?? '-',
        beratOf: (i) => i.berat ?? 0.0,
      ),
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Mixer',
        items: inputs.mixer,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noMixerPartial) ?? _s(i.noMixer) ?? '-',
        beratOf: (i) => i.berat ?? 0.0,
      ),
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Reject',
        items: inputs.reject,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noRejectPartial) ?? _s(i.noReject) ?? '-',
        beratOf: (i) => i.berat ?? 0.0,
      ),
    ];

    final outputGroups = [
      buildCategoryGroupFromLabelRows(
        categoryLabel: 'Output',
        items: outputs,
        namaJenisOf: (o) => o.namaJenis,
        labelNoOf: (o) => _s(o.noBroker) ?? '-',
        sakCountOf: (o) => o.totalSak,
        beratOf: (o) => o.totalBerat,
      ),
    ];

    return ProductionCrossCheckSummary(
      inputGroups: inputGroups,
      outputGroups: outputGroups,
    );
  }

  @override
  Future<void> verify(String noProduksi, {String? note}) =>
      _repo.verifyProduksi(noProduksi, note: note);

  @override
  Future<void> unverify(String noProduksi, {String? note}) =>
      _repo.unverifyProduksi(noProduksi, note: note);
}
