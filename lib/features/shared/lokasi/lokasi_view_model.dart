import 'package:flutter/material.dart';
import 'lokasi_model.dart';
import 'lokasi_repository.dart';

class LokasiViewModel extends ChangeNotifier {
  final LokasiRepository repository;
  LokasiViewModel({required this.repository});

  List<Lokasi> lokasiList = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchLokasiList() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      lokasiList = await repository.fetchLokasiList();
    } catch (e, st) {
      errorMessage = e.toString();
      lokasiList = [];
      debugPrint('LokasiViewModel ERROR → $errorMessage');
      debugPrint('StackTrace: $st');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
