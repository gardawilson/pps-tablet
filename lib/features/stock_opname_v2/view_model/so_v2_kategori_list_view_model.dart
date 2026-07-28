import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../model/so_v2_generate_preview.dart';
import '../model/so_v2_kategori.dart';
import '../repository/so_v2_repository.dart';

class SoV2KategoriListViewModel extends ChangeNotifier {
  final SoV2Repository repository;

  SoV2KategoriListViewModel({SoV2Repository? repository})
    : repository = repository ?? SoV2Repository();

  List<SoV2Kategori> items = [];
  bool isLoading = false;
  String? error;

  /// Non-null saat sedang menampilkan riwayat periode (year, month).
  ({int year, int month})? riwayatPeriod;
  bool get isRiwayatMode => riwayatPeriod != null;

  Future<void> load() async {
    riwayatPeriod = null;
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

  Future<void> loadRiwayat({required int year, required int month}) async {
    riwayatPeriod = (year: year, month: month);
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await repository.fetchKategori(year: year, month: month);
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Return preview breakdown on success, or an error message string.
  Future<({SoV2GeneratePreview? preview, String? errorMessage})>
      previewGenerate({required int categoryId}) async {
    try {
      final res = await repository.previewGenerate(categoryId: categoryId);
      return (preview: res.preview, errorMessage: null);
    } on ApiException catch (e) {
      return (preview: null, errorMessage: apiErrorMessage(e));
    } catch (e) {
      return (preview: null, errorMessage: e.toString());
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
