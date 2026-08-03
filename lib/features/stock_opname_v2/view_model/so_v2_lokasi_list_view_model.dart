import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../model/so_v2_lokasi.dart';
import '../repository/so_v2_repository.dart';

class SoV2LokasiListViewModel extends ChangeNotifier {
  final String stockOpnameNo;
  final String blok;
  final SoV2Repository repository;

  SoV2LokasiListViewModel({
    required this.stockOpnameNo,
    required this.blok,
    SoV2Repository? repository,
  }) : repository = repository ?? SoV2Repository();

  List<SoV2Lokasi> items = [];
  bool isLoading = false;
  String? error;
  bool isComplete = false;

  int get totalLabelCount =>
      items.fold(0, (sum, item) => sum + item.labelCount);

  double get totalWeight =>
      items.fold(0.0, (sum, item) => sum + item.totalWeight);

  /// Update optimistik lokal setelah event realtime `stock_opname_hasil_inserted`
  /// — lihat [SoV2BlokListViewModel.applyScan]. Return false kalau
  /// lokasinya belum termuat, supaya caller fallback ke [load] penuh.
  bool applyScan({required int locationId, required double weightDelta}) {
    final index = items.indexWhere((l) => l.locationId == locationId);
    if (index == -1) return false;
    final current = items[index];
    items = [...items]
      ..[index] = current.copyWith(
        scannedCount: current.scannedCount + 1,
        totalWeight: current.totalWeight + weightDelta,
      );
    notifyListeners();
    return true;
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final page = await repository.fetchLokasi(
        stockOpnameNo: stockOpnameNo,
        blok: blok,
      );
      items = page.data;
      isComplete = page.isComplete;
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Return null on success/idempotent-complete, or an error message string.
  Future<String?> markComplete() async {
    try {
      await repository.completeStockOpname(stockOpnameNo);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Sudah complete sebelumnya - idempotent, bukan error fatal.
        return null;
      }
      return apiErrorMessage(e);
    } catch (e) {
      return e.toString();
    }
  }
}
