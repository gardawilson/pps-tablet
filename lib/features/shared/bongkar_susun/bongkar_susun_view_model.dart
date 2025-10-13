import 'package:flutter/foundation.dart';
import 'bongkar_susun_repository.dart';
import 'bongkar_susun_model.dart';

class BongkarSusunViewModel extends ChangeNotifier {
  final BongkarSusunRepository repository;
  BongkarSusunViewModel({required this.repository});

  bool isLoading = false;
  String error = '';
  List<BongkarSusun> items = [];

  Future<void> fetchByDate(DateTime date) async {
    isLoading = true; error = ''; notifyListeners();
    try {
      items = await repository.fetchByDate(date);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }
}

