import 'package:flutter/foundation.dart';

import '../model/regu_model.dart';
import '../repository/regu_repository.dart';

class ReguViewModel extends ChangeNotifier {
  final ReguRepository repository;
  ReguViewModel({required this.repository});

  List<MstRegu> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadAll() async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      items = await repository.fetchAll();
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
