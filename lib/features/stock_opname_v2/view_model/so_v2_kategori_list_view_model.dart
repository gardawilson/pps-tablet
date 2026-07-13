import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../model/so_v2_kategori.dart';
import '../repository/so_v2_repository.dart';

class SoV2KategoriListViewModel extends ChangeNotifier {
  final SoV2Repository repository;

  SoV2KategoriListViewModel({SoV2Repository? repository})
      : repository = repository ?? SoV2Repository();

  List<SoV2Kategori> items = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await repository.fetchKategori();
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Return preview message on success, or an error message string.
  Future<({String? message, String? errorMessage})> previewGenerate({
    required int categoryId,
  }) async {
    try {
      final preview = await repository.previewGenerate(categoryId: categoryId);
      return (message: preview.message, errorMessage: null);
    } on ApiException catch (e) {
      return (message: null, errorMessage: apiErrorMessage(e));
    } catch (e) {
      return (message: null, errorMessage: e.toString());
    }
  }

  /// Return null + result map on success, or an error message string.
  Future<({Map<String, dynamic>? result, String? errorMessage})> generate({
    required int categoryId,
  }) async {
    try {
      final result = await repository.generateNoStockOpname(
        categoryId: categoryId,
      );
      return (result: result, errorMessage: null);
    } on ApiException catch (e) {
      return (result: null, errorMessage: apiErrorMessage(e));
    } catch (e) {
      return (result: null, errorMessage: e.toString());
    }
  }

  /// Return null on success, or an error message string.
  Future<String?> deleteStockOpname(String stockOpnameNo) async {
    try {
      await repository.deleteStockOpname(stockOpnameNo);
      return null;
    } on ApiException catch (e) {
      return apiErrorMessage(e);
    } catch (e) {
      return e.toString();
    }
  }
}
