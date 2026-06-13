import 'package:flutter/foundation.dart';

import '../model/mapping_label_model.dart';
import '../repository/mapping_repository.dart';

class MappingLabelViewModel extends ChangeNotifier {
  final MappingRepository repository;

  MappingLabelViewModel({required this.repository});

  MappingLabelResult? result;
  bool isLoading = false;
  String error = '';

  Future<void> load({required String blok, required int idLokasi}) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      result = await repository.fetchLabelByLokasi(blok: blok, idLokasi: idLokasi);
    } catch (e) {
      error = e.toString();
      result = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
