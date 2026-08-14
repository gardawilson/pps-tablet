import 'package:flutter/foundation.dart';

import '../model/good_transfer_header_model.dart';
import '../model/good_transfer_item_model.dart';
import '../repository/good_transfer_repository.dart';

class GoodTransferListViewModel extends ChangeNotifier {
  final GoodTransferRepository repository;

  GoodTransferListViewModel({required this.repository});

  List<GoodTransferHeader> items = [];
  bool isLoading = false;
  String error = '';

  String? selectedNoTransfer;
  GoodTransferDetail? selectedDetail;
  bool isLoadingDetail = false;
  String detailError = '';

  Future<void> load({String? status}) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchAll(status: status);
    } catch (e) {
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  Future<void> selectTransfer(String noTransfer) async {
    selectedNoTransfer = noTransfer;
    isLoadingDetail = true;
    detailError = '';
    notifyListeners();

    try {
      selectedDetail = await repository.fetchDetail(noTransfer);
    } catch (e) {
      detailError = e.toString();
      selectedDetail = null;
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    selectedNoTransfer = null;
    selectedDetail = null;
    detailError = '';
    notifyListeners();
  }

  Future<bool> cancelSelected() async {
    if (selectedNoTransfer == null) return false;
    try {
      await repository.cancelTransfer(selectedNoTransfer!);
      await load();
      await selectTransfer(selectedNoTransfer!);
      return true;
    } catch (e) {
      detailError = e.toString();
      notifyListeners();
      return false;
    }
  }
}
