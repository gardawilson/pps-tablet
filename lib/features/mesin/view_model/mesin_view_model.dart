import 'package:flutter/foundation.dart';
import '../model/mesin_model.dart';
import '../repository/mesin_repository.dart';

class MesinViewModel extends ChangeNotifier {
  final MesinRepository repository;
  MesinViewModel({required this.repository});

  List<MstMesin> items = [];
  bool isLoading = false;
  String error = '';

  /// ✅ Baru: ambil mesin berdasarkan **IdBagianMesin** (integer).
  Future<void> fetchByIdBagian(
      int idBagianMesin, {
        bool includeDisabled = false,
      }) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchByIdBagian(
        idBagianMesin: idBagianMesin,
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
