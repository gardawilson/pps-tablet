// lib/features/cetakan/view_model/cetakan_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/mst_cetakan_model.dart';
import '../repository/cetakan_repository.dart';

class CetakanViewModel extends ChangeNotifier {
  final CetakanRepository repository;
  CetakanViewModel({required this.repository});

  List<MstCetakan> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadAll({int? idBj}) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchAll(idBj: idBj);
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
