import 'package:flutter/foundation.dart';

import '../model/mixer_production_model.dart';
import '../repository/mixer_production_repository.dart';

class MixerProductionViewModel extends ChangeNotifier {
  final MixerProductionRepository repository;

  MixerProductionViewModel({required this.repository});

  List<MixerProduction> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> fetchByDate(DateTime date) async {
    isLoading = true;
    error = '';
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

  void clear() {
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }
}
