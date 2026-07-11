import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../repository/so_v2_repository.dart';

class SoV2BlokListViewModel extends ChangeNotifier {
  final SoV2Repository repository;

  SoV2BlokListViewModel({SoV2Repository? repository})
      : repository = repository ?? SoV2Repository();

  List<String> items = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await repository.fetchBlok();
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
