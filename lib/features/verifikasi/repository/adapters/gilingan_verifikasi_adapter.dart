// lib/features/verifikasi/repository/adapters/gilingan_verifikasi_adapter.dart

import '../../../production/gilingan/repository/gilingan_production_input_repository.dart';
import '../../../production/gilingan/repository/gilingan_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../../model/verifikasi_operator_summary_model.dart';
import '../verifikasi_adapter.dart';
import 'production_grouping.dart';

String? _s(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

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
  bool get hasOperatorVerification => false;

  @override
  bool get hasDepartmentVerification => false;

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
              outputJenisNama: p.outputJenisNama,
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
        categoryLabel: 'Bonggolan',
        items: inputs.bonggolan,
        namaJenisOf: (i) => i.namaJenis,
        labelNoOf: (i) => _s(i.noBonggolan) ?? '-',
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
        labelNoOf: (o) => _s(o.noGilingan) ?? '-',
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
        'Gilingan tidak men-support verifikasi Production Controller/Kadept',
      );

  @override
  Future<void> verifyOperator(String noProduksi, {String? note}) =>
      throw UnimplementedError(
        'Gilingan tidak men-support verifikasi Production Controller',
      );

  @override
  Future<void> verifyDepartment(String noProduksi, {String? note}) =>
      throw UnimplementedError('Gilingan tidak men-support verifikasi Kadept');
}
