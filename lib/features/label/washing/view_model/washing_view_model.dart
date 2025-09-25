import 'package:flutter/material.dart';
import '../model/washing_header_model.dart';
import '../repository/washing_repository.dart';

class WashingViewModel extends ChangeNotifier {
  final WashingRepository repository;

  WashingViewModel({required this.repository});

  List<WashingHeader> items = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchWashingHeaders() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      items = await repository.fetchHeaders();
    } catch (e) {
      errorMessage = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
