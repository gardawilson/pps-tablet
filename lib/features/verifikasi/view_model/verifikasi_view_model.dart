// lib/features/verifikasi/view_model/verifikasi_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/verifikasi_models.dart';
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

  Future<bool> verify(VerifikasiItem item, {String? note}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      await _repo.verify(item.jenisKey, item.noProduksi, note: note);
      items.removeWhere(
        (x) => x.noProduksi == item.noProduksi && x.jenisKey == item.jenisKey,
      );
      return true;
    } catch (e) {
      actionError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isActing = false;
      notifyListeners();
    }
  }
}
