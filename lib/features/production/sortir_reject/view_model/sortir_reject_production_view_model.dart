// lib/features/shared/sortir_reject_production/sortir_reject_production_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/sortir_reject_production_model.dart';
import '../repository/sortir_reject_production_repository.dart';

class SortirRejectProductionViewModel extends ChangeNotifier {
  final SortirRejectProductionRepository repository;

  SortirRejectProductionViewModel({required this.repository});

  List<SortirRejectProduction> items = [];
  bool isLoading = false;
  String error = '';
  DateTime? currentDate;

  /// Load BJSortirReject_h untuk tanggal tertentu
  /// Backend: GET /api/sortir-reject/:date (YYYY-MM-DD)
  Future<void> fetchByDate(DateTime date) async {
    isLoading = true;
    error = '';
    currentDate = date;
    notifyListeners();

    try {
      items = await repository.fetchByDate(date);
    } catch (e) {
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Opsional: reload data untuk tanggal terakhir yang dipakai
  Future<void> reload() async {
    if (currentDate == null) return;
    await fetchByDate(currentDate!);
  }

  void clear() {
    items = [];
    error = '';
    isLoading = false;
    currentDate = null;
    notifyListeners();
  }
}
