// lib/features/verifikasi/repository/adapters/inject_verifikasi_adapter.dart

import '../../../production/inject/model/inject_production_model.dart';
import '../../../production/inject/repository/inject_production_input_repository.dart';
import '../../../production/inject/repository/inject_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../../model/verifikasi_operator_summary_model.dart';
import '../verifikasi_adapter.dart';
import 'production_grouping.dart';

String? _s(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

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
  bool get hasOperatorVerification => false;

  @override
  bool get hasDepartmentVerification => false;

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
              hourStart: p.hourStart,
              hourEnd: p.hourEnd,
              outputJenisNama: p.namaJenis,
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

    final inputGroups = [
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Broker',
        items: inputs.broker,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noBrokerPartial) ?? _s(i.noBroker) ?? '-',
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
        categoryLabel: 'Gilingan',
        items: inputs.gilingan,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noGilinganPartial) ?? _s(i.noGilingan) ?? '-',
        beratOf: (i) => i.berat ?? 0.0,
      ),
      buildCategoryGroupFromSakRows(
        categoryLabel: 'Furniture WIP',
        items: inputs.furnitureWip,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) =>
            _s(i.noFurnitureWIPPartial) ?? _s(i.noFurnitureWIP) ?? '-',
        beratOf: (i) => i.berat ?? 0.0,
      ),
    ];

    final outputGroups = [
      buildCategoryGroupFromLabelRows(
        categoryLabel: 'Output',
        items: outputs,
        namaJenisOf: (o) => o.namaJenis,
        labelNoOf: (o) => _s(o.noFurnitureWip) ?? '-',
        sakCountOf: (_) => 1,
        beratOf: (o) => o.berat,
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

  @override
  Future<VerifikasiOperatorHeader> fetchOperatorHeader(String noProduksi) =>
      throw UnimplementedError(
        'Inject tidak men-support verifikasi Production Controller/Kadept',
      );

  @override
  Future<void> verifyOperator(String noProduksi, {String? note}) =>
      throw UnimplementedError(
        'Inject tidak men-support verifikasi Production Controller',
      );

  @override
  Future<void> verifyDepartment(String noProduksi, {String? note}) =>
      throw UnimplementedError('Inject tidak men-support verifikasi Kadept');
}
