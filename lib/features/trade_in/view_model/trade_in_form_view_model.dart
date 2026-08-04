import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../model/trade_in_detail.dart';
import '../model/trade_in_salesperson.dart';
import '../repository/trade_in_repository.dart';

class TradeInFormViewModel extends ChangeNotifier {
  /// Null → mode tambah baru. Non-null → mode edit penerimaan tsb.
  final String? noPenerimaan;
  final TradeInRepository repository;

  TradeInFormViewModel({this.noPenerimaan, TradeInRepository? repository})
    : repository = repository ?? TradeInRepository();

  bool get isEditMode => noPenerimaan != null;

  bool isLoading = false;
  String? error;

  List<TradeInSalesPerson> salesPersons = [];

  /// Preview nomor penerimaan berikutnya — hanya terisi di mode tambah.
  String? previewNoPenerimaan;

  /// Data existing — hanya terisi di mode edit, dipakai untuk prefill form.
  TradeInDetail? detail;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        repository.fetchSalesPersons(),
        isEditMode ? repository.fetchDetail(noPenerimaan!) : repository.fetchNextNo(),
      ]);
      salesPersons = results[0] as List<TradeInSalesPerson>;
      if (isEditMode) {
        detail = results[1] as TradeInDetail;
      } else {
        previewNoPenerimaan = results[1] as String;
      }
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Return (noPenerimaan, null) on success, or (null, errorMessage) on
  /// failure — dipakai baik untuk create maupun update.
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
      final String result;
      if (isEditMode) {
        result = await repository.update(
          noPenerimaan!,
          supplier: supplier,
          salesPersonCode: salesPersonCode,
          jenis: jenis,
          tanggal: tanggalStr,
          idReject: idReject,
          berat: berat,
          noReject: detail?.reject?.noReject ?? '',
        );
      } else {
        result = await repository.create(
          supplier: supplier,
          salesPersonCode: salesPersonCode,
          jenis: jenis,
          tanggal: tanggalStr,
          idReject: idReject,
          berat: berat,
        );
      }
      return (noPenerimaan: result, errorMessage: null);
    } on ApiException catch (e) {
      return (noPenerimaan: null, errorMessage: apiErrorMessage(e));
    } catch (e) {
      return (noPenerimaan: null, errorMessage: e.toString());
    }
  }
}
