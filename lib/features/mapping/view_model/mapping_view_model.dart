import 'package:flutter/foundation.dart';

import '../model/mapping_blok_model.dart';
import '../repository/mapping_repository.dart';

class MappingViewModel extends ChangeNotifier {
  final MappingRepository repository;

  MappingViewModel({required this.repository});

  List<MappingBlok> blokList = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadBlok() async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      blokList = await repository.fetchBlokList();
    } catch (e) {
      error = e.toString();
      blokList = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
