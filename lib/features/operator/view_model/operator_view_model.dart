import 'package:flutter/foundation.dart';
import '../model/operator_model.dart';
import '../repository/operator_repository.dart';

class OperatorViewModel extends ChangeNotifier {
  final OperatorRepository repository;
  OperatorViewModel({required this.repository});

  List<MstOperator> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadAll({
    bool includeDisabled = false,
    String? q,
    String orderBy = 'NamaOperator',
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
