// lib/features/warna/view_model/warna_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/warna_model.dart';
import '../repository/warna_repository.dart';

class WarnaViewModel extends ChangeNotifier {
  final WarnaRepository repository;
  WarnaViewModel({required this.repository});

  List<MstWarna> items = [];
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
