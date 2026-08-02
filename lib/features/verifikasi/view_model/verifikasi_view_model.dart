// lib/features/verifikasi/view_model/verifikasi_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/verifikasi_models.dart';
import '../model/verifikasi_operator_summary_model.dart';
import '../repository/verifikasi_repository.dart';

class VerifikasiViewModel extends ChangeNotifier {
  final VerifikasiRepository _repo;

  VerifikasiViewModel({VerifikasiRepository? repository})
      : _repo = repository ?? VerifikasiRepository();

  bool isLoading = false;
  String? error;

  /// Semua item pending lintas jenis produksi — digabung jadi satu list
  /// (tidak per-tab) karena volume harian tiap jenis produksi kecil.
  List<VerifikasiItem> items = [];

  /// null = tampilkan semua jenis. Diisi hanya kalau user memilih chip
  /// filter jenis tertentu.
  String? selectedJenis;

  bool isActing = false;
  String? actionError;

  List<String> get availableJenis =>
      _repo.adapters.map((a) => a.jenisKey).toList();

  String jenisLabel(String key) =>
      _repo.adapters.firstWhere((a) => a.jenisKey == key).jenisLabel;

  List<VerifikasiItem> get filteredItems => selectedJenis == null
      ? items
      : items.where((i) => i.jenisKey == selectedJenis).toList();

  int countFor(String jenisKey) =>
      items.where((i) => i.jenisKey == jenisKey).length;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repo.fetchPending();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle filter jenis: pilih chip yang sama lagi untuk kembali ke "Semua".
  void setJenisFilter(String? jenisKey) {
    final next = selectedJenis == jenisKey ? null : jenisKey;
    if (selectedJenis == next) return;
    selectedJenis = next;
    notifyListeners();
  }

  Future<ProductionCrossCheckSummary> fetchCrossCheck(VerifikasiItem item) {
    return _repo.fetchCrossCheck(item.jenisKey, item.noProduksi);
  }

  /// True kalau jenis produksi ini punya tahap verifikasi Production
  /// Controller — independen dari Stock Controller, bisa diisi kapan pun.
  bool hasOperatorStep(String jenisKey) =>
      _repo.hasOperatorVerification(jenisKey);

  /// True kalau jenis produksi ini punya tahap verifikasi Kadept — baru
  /// bisa dilakukan setelah Stock Controller & Production Controller
  /// tuntas.
  bool hasDepartmentStep(String jenisKey) =>
      _repo.hasDepartmentVerification(jenisKey);

  Future<bool> verify(VerifikasiItem item, {String? note}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      await _repo.verify(item.jenisKey, item.noProduksi, note: note);
      _applyVerified(item, verified: true);
      return true;
    } catch (e) {
      actionError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isActing = false;
      notifyListeners();
    }
  }

  /// Ambil header verifikasi (penugasan, kehadiran, status SC/PC/Kadept)
  /// untuk dialog Production Controller & Kadept.
  Future<VerifikasiOperatorHeader> fetchOperatorHeader(VerifikasiItem item) {
    return _repo.fetchOperatorHeader(item.jenisKey, item.noProduksi);
  }

  Future<bool> verifyOperatorStage(VerifikasiItem item, {String? note}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      await _repo.verifyOperator(item.jenisKey, item.noProduksi, note: note);
      _applyVerified(item, verifiedOperator: true);
      return true;
    } catch (e) {
      actionError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isActing = false;
      notifyListeners();
    }
  }

  Future<bool> verifyDepartmentStage(VerifikasiItem item, {String? note}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      await _repo.verifyDepartment(item.jenisKey, item.noProduksi, note: note);
      _applyVerified(item, verifiedDepartment: true);
      return true;
    } catch (e) {
      actionError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isActing = false;
      notifyListeners();
    }
  }


  /// Update state item di [items] setelah satu tahap verifikasi berhasil.
  /// Item dibuang dari list hanya kalau semua tahap yang berlaku untuk
  /// jenis produksinya sudah tuntas (Stock Controller, Production
  /// Controller kalau ada, dan Kadept kalau ada).
  void _applyVerified(
    VerifikasiItem item, {
    bool? verified,
    bool? verifiedOperator,
    bool? verifiedDepartment,
  }) {
    final idx = items.indexWhere(
      (x) => x.noProduksi == item.noProduksi && x.jenisKey == item.jenisKey,
    );
    if (idx == -1) return;

    final updated = items[idx].copyWith(
      verified: verified,
      verifiedOperator: verifiedOperator,
      verifiedDepartment: verifiedDepartment,
    );
    final needsOperatorStep = hasOperatorStep(updated.jenisKey);
    final needsDepartmentStep = hasDepartmentStep(updated.jenisKey);
    final fullyVerified = updated.verified &&
        (!needsOperatorStep || updated.verifiedOperator) &&
        (!needsDepartmentStep || updated.verifiedDepartment);

    if (fullyVerified) {
      items.removeAt(idx);
    } else {
      items[idx] = updated;
    }
  }
}
