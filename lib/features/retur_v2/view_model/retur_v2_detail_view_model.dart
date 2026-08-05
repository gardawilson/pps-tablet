import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../model/retur_v2_output.dart';
import '../repository/retur_v2_repository.dart';

class ReturV2DetailViewModel extends ChangeNotifier {
  final String noRetur;
  final ReturV2Repository repository;

  ReturV2DetailViewModel({
    required this.noRetur,
    ReturV2Repository? repository,
  }) : repository = repository ?? ReturV2Repository();

  bool isLoading = false;
  String? error;
  List<ReturV2Output> furnitureWipItems = [];
  List<ReturV2Output> barangJadiItems = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        repository.fetchFurnitureWipOutputs(noRetur),
        repository.fetchBarangJadiOutputs(noRetur),
      ]);
      furnitureWipItems = results[0];
      barangJadiItems = results[1];
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
