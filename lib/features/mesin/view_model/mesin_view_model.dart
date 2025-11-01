import 'package:flutter/foundation.dart';
import '../model/mesin_model.dart';
import '../repository/mesin_repository.dart';

class MesinViewModel extends ChangeNotifier {
  final MesinRepository repository;
  MesinViewModel({required this.repository});

  List<MstMesin> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> fetchByBagian(String bagian, {bool includeDisabled = false}) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchByBagian(
        bagian: bagian,
        includeDisabled: includeDisabled,
      );
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
