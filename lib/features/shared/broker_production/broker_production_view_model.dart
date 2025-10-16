import 'package:flutter/foundation.dart';
import 'broker_production_repository.dart';
import 'broker_production_model.dart';

class BrokerProductionViewModel extends ChangeNotifier {
  final BrokerProductionRepository repository;
  BrokerProductionViewModel({required this.repository});

  bool isLoading = false;
  String error = '';
  List<BrokerProduction> items = [];


  // Opsional
  Future<void> fetchByDate(DateTime date) async {
    isLoading = true; error = ''; notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      items = data;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }


}
