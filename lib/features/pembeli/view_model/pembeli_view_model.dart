import 'package:flutter/foundation.dart';
import '../model/pembeli_model.dart';
import '../repository/pembeli_repository.dart';

class PembeliViewModel extends ChangeNotifier {
  final PembeliRepository repository;
  PembeliViewModel({required this.repository});

  List<MstPembeli> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadAll({
    bool includeDisabled = false,
    String? q,
    String orderBy = 'NamaPembeli',
    String orderDir = 'ASC',
  }) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchAll(
        includeDisabled: includeDisabled,
        q: q,
        orderBy: orderBy,
        orderDir: orderDir,
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
