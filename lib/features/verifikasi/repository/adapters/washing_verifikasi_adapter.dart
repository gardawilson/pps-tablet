// lib/features/verifikasi/repository/adapters/washing_verifikasi_adapter.dart

import '../../../production/washing/model/washing_inputs_v2_model.dart';
import '../../../production/washing/model/washing_verification_summary_model.dart';
import '../../../production/washing/repository/washing_production_input_repository.dart';
import '../../../production/washing/repository/washing_production_repository.dart';
import '../../model/verifikasi_models.dart';
import '../../model/verifikasi_operator_summary_model.dart';
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
  bool get hasOperatorVerification => true;

  @override
  bool get hasDepartmentVerification => true;

  @override
  Future<List<VerifikasiItem>> fetchPending() async {
    // verified: false → server hanya kirim yang belum tuntas verifikasi.
    // Client-side where() di bawah tetap dipertahankan sebagai pengaman
    // kalau backend suatu saat mengembalikan item yang ternyata sudah
    // tuntas semua tahap (SC/PC/Kadept).
    final items = await _repo.fetchAllList(
      page: 1,
      pageSize: 100,
      complete: true,
      verified: false,
      includeRendemen: true,
    );
    return items
        .where((p) =>
            !(p.verified && p.verifiedOperator && p.verifiedDepartment))
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
              rendemen: p.rendemen,
              verified: p.verified,
              verifiedByUsername: p.verifiedByUsername,
              verifiedAt: p.verifiedAt,
              verifiedOperator: p.verifiedOperator,
              operatorVerifiedByUsername: p.operatorVerifiedByUsername,
              operatorVerifiedAt: p.operatorVerifiedAt,
              verifiedDepartment: p.verifiedDepartment,
              departmentVerifiedByUsername: p.departmentVerifiedByUsername,
              departmentVerifiedAt: p.departmentVerifiedAt,
            ))
        .toList();
  }

  @override
  Future<ProductionCrossCheckSummary> fetchCrossCheck(String noProduksi) async {
    final inputsV2 = await _inputRepo.fetchInputsV2(noProduksi);
    final outputsV2 = await _inputRepo.fetchOutputsV2(noProduksi);
    return buildWashingCrossCheckSummary(inputsV2, outputsV2);
  }

  @override
  Future<void> verify(String noProduksi, {String? note}) =>
      _repo.verifyProduksi(noProduksi, note: note);

  @override
  Future<void> unverify(String noProduksi, {String? note}) =>
      _repo.unverifyProduksi(noProduksi, note: note);

  @override
  Future<VerifikasiOperatorHeader> fetchOperatorHeader(
    String noProduksi,
  ) async {
    final summary = await _inputRepo.fetchVerificationSummary(noProduksi);
    return _toGenericHeader(summary.header);
  }

  @override
  Future<void> verifyOperator(String noProduksi, {String? note}) =>
      _repo.verifyOperator(noProduksi, note: note);

  @override
  Future<void> verifyDepartment(String noProduksi, {String? note}) =>
      _repo.verifyDepartment(noProduksi, note: note);
}

/// Konversi header washing-specific ke model generik yang dipakai dialog
/// Production Controller & Kadept lintas jenis produksi.
VerifikasiOperatorHeader _toGenericHeader(WashingVerificationHeader h) {
  return VerifikasiOperatorHeader(
    noProduksi: h.noProduksi,
    namaMesin: h.namaMesin,
    operators: h.operators
        .map((o) => VerifikasiOperatorEntry(
              idOperator: o.idOperator,
              namaOperator: o.namaOperator,
            ))
        .toList(),
    namaOperators: h.namaOperators,
    outputJenisNama: h.outputJenisNama,
    tglProduksi: h.tglProduksi,
    jamKerja: h.jamKerja,
    shift: h.shift,
    isComplete: h.isComplete,
    verified: h.verified,
    verifiedAt: h.verifiedAt,
    verifiedOperator: h.verifiedOperator,
    operatorVerifiedAt: h.operatorVerifiedAt,
    verifiedDepartment: h.verifiedDepartment,
    departmentVerifiedAt: h.departmentVerifiedAt,
    jmlhAnggota: h.jmlhAnggota,
    hadir: h.hadir,
    hourMeter: h.hourMeter,
    isBlower: h.isBlower,
    hourStart: h.hourStart,
    hourEnd: h.hourEnd,
    idRegu: h.idRegu,
    namaRegu: h.namaRegu,
  );
}

const _washingCategoryLabels = {
  'washing': 'Washing',
  'bb': 'Bahan Baku',
  'gilingan': 'Gilingan',
};

/// Susun [ProductionCrossCheckSummary] dari inputs/v2 & outputs/v2 washing.
/// Dipakai bersama oleh [WashingVerifikasiAdapter] (dialog "Verifikasi
/// Stock Controller") dan dialog "Verifikasi Production Controller"
/// (endpoint verification-summary membawa inputs/outputs dengan bentuk
/// yang sama).
ProductionCrossCheckSummary buildWashingCrossCheckSummary(
  WashingInputsV2 inputsV2,
  WashingOutputsV2 outputsV2,
) {
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
        categoryLabel: _washingCategoryLabels[entry.key] ?? entry.key,
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
