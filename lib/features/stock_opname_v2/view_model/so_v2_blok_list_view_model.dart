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

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await repository.fetchBlok(stockOpnameNo: stockOpnameNo);
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
