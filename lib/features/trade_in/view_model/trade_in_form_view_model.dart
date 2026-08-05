import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../model/trade_in_salesperson.dart';
import '../repository/trade_in_repository.dart';

/// Form tambah 1 penerimaan trade-in baru (header + 1 label reject
/// terkait) — tidak ada mode edit, penerimaan yang sudah tersimpan hanya
/// bisa dilihat lewat preview.
class TradeInFormViewModel extends ChangeNotifier {
  final TradeInRepository repository;

  TradeInFormViewModel({TradeInRepository? repository})
    : repository = repository ?? TradeInRepository();

  bool isLoading = false;
  String? error;

  List<TradeInSalesPerson> salesPersons = [];

  /// Preview nomor penerimaan berikutnya.
  String? previewNoPenerimaan;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        repository.fetchSalesPersons(),
        repository.fetchNextNo(),
      ]);
      salesPersons = results[0] as List<TradeInSalesPerson>;
      previewNoPenerimaan = results[1] as String;
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Return (noPenerimaan, null) on success, or (null, errorMessage) on
  /// failure.
  Future<({String? noPenerimaan, String? errorMessage})> submit({
    required String supplier,
    required String salesPersonCode,
    required String jenis,
    required DateTime tanggal,
    required int idReject,
    required String berat,
  }) async {
    final tanggalStr =
        '${tanggal.year.toString().padLeft(4, '0')}-'
        '${tanggal.month.toString().padLeft(2, '0')}-'
        '${tanggal.day.toString().padLeft(2, '0')}';
    try {
      final result = await repository.create(
        supplier: supplier,
        salesPersonCode: salesPersonCode,
        jenis: jenis,
        tanggal: tanggalStr,
        idReject: idReject,
        berat: berat,
      );
      return (noPenerimaan: result, errorMessage: null);
    } on ApiException catch (e) {
      return (noPenerimaan: null, errorMessage: apiErrorMessage(e));
    } catch (e) {
      return (noPenerimaan: null, errorMessage: e.toString());
    }
  }
}
