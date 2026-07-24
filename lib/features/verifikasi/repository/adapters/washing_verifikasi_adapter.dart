// lib/features/verifikasi/repository/adapters/washing_verifikasi_adapter.dart

import '../../../production/washing/repository/washing_production_input_repository.dart';
import '../../../production/washing/repository/washing_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../verifikasi_adapter.dart';
import 'production_grouping.dart';

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
              hourStart: p.hourStart,
              hourEnd: p.hourEnd,
              verified: p.verified,
              verifiedByUsername: p.verifiedByUsername,
              verifiedAt: p.verifiedAt,
            ))
        .toList();
  }

  static const _categoryLabels = {
    'washing': 'Washing',
    'bb': 'Bahan Baku',
    'gilingan': 'Gilingan',
  };

  @override
  Future<ProductionCrossCheckSummary> fetchCrossCheck(String noProduksi) async {
    final inputsV2 = await _inputRepo.fetchInputsV2(noProduksi);
    final outputsV2 = await _inputRepo.fetchOutputsV2(noProduksi);

    final inputGroups = [
      buildCategoryGroupFromLabelRows(
        categoryLabel: 'Bahan Baku',
        items: inputsV2.bb,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => i.labelNo,
        sakCountOf: (i) => i.totalSak,
        beratOf: (i) => i.totalBerat,
      ),
      buildCategoryGroupFromLabelRows(
        categoryLabel: 'Washing',
        items: inputsV2.washing,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => i.labelNo,
        sakCountOf: (i) => i.totalSak,
        beratOf: (i) => i.totalBerat,
      ),
      buildCategoryGroupFromLabelRows(
        categoryLabel: 'Gilingan',
        items: inputsV2.gilingan,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => i.labelNo,
        sakCountOf: (i) => i.totalSak,
        beratOf: (i) => i.totalBerat,
      ),
    ];

    final outputGroups = [
      for (final entry in outputsV2.categories.entries)
        buildCategoryGroupFromLabelRows(
          categoryLabel: _categoryLabels[entry.key] ?? entry.key,
          items: entry.value,
          namaJenisOf: (i) => i.namaJenis,
          labelNoOf: (i) => i.labelNo,
          sakCountOf: (i) => i.totalSak,
          beratOf: (i) => i.totalBerat,
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
