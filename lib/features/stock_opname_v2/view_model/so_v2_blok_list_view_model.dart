import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../model/so_v2_blok.dart';
import '../repository/so_v2_repository.dart';

class SoV2BlokListViewModel extends ChangeNotifier {
  final SoV2Repository repository;
  final String stockOpnameNo;

  SoV2BlokListViewModel({
    required this.stockOpnameNo,
    SoV2Repository? repository,
  }) : repository = repository ?? SoV2Repository();

  List<SoV2Blok> items = [];
  bool isLoading = false;
  String? error;

  /// Status selesai di level stock opname (bukan per-blok) — dari
  /// `GET .../blok` yang sekarang membawa field ini juga.
  bool isComplete = false;
  DateTime? completedAt;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final page = await repository.fetchBlok(stockOpnameNo: stockOpnameNo);
      items = page.data;
      isComplete = page.isComplete;
      completedAt = page.completedAt;
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
