import 'package:flutter/foundation.dart';

import '../model/mapping_label_model.dart';
import '../repository/mapping_repository.dart';

class MappingLabelHistoryViewModel extends ChangeNotifier {
  final MappingRepository repository;

  MappingLabelHistoryViewModel({required this.repository});

  MappingLabelHistoryResult? result;
  bool isLoading = false;
  String error = '';

  Future<void> load(String labelCode) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      result = await repository.fetchLabelHistory(labelCode);
    } catch (e) {
      error = e.toString();
      result = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
