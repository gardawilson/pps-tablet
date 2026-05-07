import 'package:flutter/foundation.dart';

import '../model/mapping_lokasi_model.dart';
import '../repository/mapping_repository.dart';

class MappingLokasiViewModel extends ChangeNotifier {
  final MappingRepository repository;

  MappingLokasiViewModel({required this.repository});

  List<MappingLokasi> lokasiList = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadLokasiByBlok(String blok) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      lokasiList = await repository.fetchLokasiByBlok(blok);
    } catch (e) {
      error = e.toString();
      lokasiList = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
