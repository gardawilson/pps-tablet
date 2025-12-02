// lib/features/bonggolan/view_model/gilingan_view_model.dart
import 'package:flutter/material.dart';
import '../model/bonggolan_header_model.dart';
import '../repository/bonggolan_repository.dart';

// Keep this in the same file or export InputMode from your dialog file
enum InputMode { brokerProduction, injectProduction, bongkar }

class BonggolanViewModel extends ChangeNotifier {
  final BonggolanRepository repository;
  BonggolanViewModel({required this.repository});

  // === LIST STATE ===
  List<BonggolanHeader> items = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  String errorMessage = '';

  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  String _search = '';

  int get totalCount => _total;
  String get currentSearch => _search;
  bool get hasMore => _page < _totalPages;

  // Highlight row
  String? selectedNoBonggolan;
  BonggolanHeader? get selectedItem {
    final i = items.indexWhere((e) => e.noBonggolan == selectedNoBonggolan);
    return i == -1 ? null : items[i];
  }

  void setSelected(String? no) {
    if (selectedNoBonggolan == no) return;
    selectedNoBonggolan = no;
    notifyListeners();
  }

  // === FETCH HEADER (RESET) ===
  Future<void> fetchHeaders({String search = ''}) async {
    _page = 1;
    _search = search;
    items = [];
    errorMessage = '';
    isLoading = true;
    selectedNoBonggolan = null;
    notifyListeners();

    try {
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      items = (result['items'] as List<BonggolanHeader>);
      _totalPages = (result['totalPages'] as int?) ?? 1;
      _total = (result['total'] as int?) ?? items.length;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Quick helpers
  Future<void> refreshCurrent() => fetchHeaders(search: _search);
  Future<void> applySearch(String search) => fetchHeaders(search: search);

  // === LOAD MORE (PAGINATION) ===
  Future<void> loadMore() async {
    if (isFetchingMore || !hasMore) return;

    isFetchingMore = true;
    notifyListeners();
    try {
      _page++;
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );
      final more = (result['items'] as List<BonggolanHeader>);
      items.addAll(more);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  // === CREATE (POST /api/labels/bonggolan) ===
  String? lastCreatedNoBonggolan;

  /// Validate the inputs that used to live in the widget.
  /// Returns `null` if OK, otherwise the error message.
  String? validateCreate({
    required int? idBonggolan,
    required DateTime dateCreate,
    double? berat,
    required InputMode? mode,
    String? brokerNoProduksi,
    String? injectNoProduksi,
    String? noBongkarSusun,
  }) {
    if (idBonggolan == null) {
      return 'Pilih jenis bonggolan terlebih dahulu.';
    }

    // optional: berat must be > 0 if provided
    if (berat != null && berat <= 0) {
      return 'Berat harus angka > 0.';
    }

    // If user picked a mode, validate the chosen code + prefix
    if (mode != null) {
      switch (mode) {
        case InputMode.brokerProduction:
          if (brokerNoProduksi == null || brokerNoProduksi.trim().isEmpty) {
            return 'Nomor produksi (Broker) belum diisi.';
          }
          if (!brokerNoProduksi.startsWith('E.')) {
            return 'Format nomor Broker harus diawali "E."';
          }
          break;
        case InputMode.injectProduction:
          if (injectNoProduksi == null || injectNoProduksi.trim().isEmpty) {
            return 'Nomor produksi (Inject) belum diisi.';
          }
          if (!injectNoProduksi.startsWith('S.')) {
            return 'Format nomor Inject harus diawali "S."';
          }
          break;
        case InputMode.bongkar:
          if (noBongkarSusun == null || noBongkarSusun.trim().isEmpty) {
            return 'Nomor bongkar susun belum diisi.';
          }
          if (!noBongkarSusun.startsWith('BG.')) {
            return 'Format nomor Bongkar Susun harus diawali "BG."';
          }
          break;
      }
    }

    return null; // OK
  }

  Map<String, dynamic> _buildCreateBody({
    required int idBonggolan,
    required int idWarehouse,
    required String dateCreateYmd, // use toDbDateString
    double? berat,
    InputMode? mode,
    String? brokerNoProduksi,
    String? injectNoProduksi,
    String? noBongkarSusun,
  }) {
    // Decide ProcessedCode based on selected mode
    String? processedCode;
    switch (mode) {
      case InputMode.brokerProduction:
        processedCode = brokerNoProduksi?.trim();
        break;
      case InputMode.injectProduction:
        processedCode = injectNoProduksi?.trim();
        break;
      case InputMode.bongkar:
        processedCode = noBongkarSusun?.trim();
        break;
      default:
        processedCode = null;
    }

    return <String, dynamic>{
      "header": {
        "IdBonggolan": idBonggolan,
        "IdWarehouse": idWarehouse,
        "DateCreate": dateCreateYmd,
        if (berat != null) "Berat": berat,
      },
      if (processedCode != null && processedCode.isNotEmpty)
        "ProcessedCode": processedCode,
    };
  }

  /// End-to-end create: validate → build body → POST → refresh list.
  /// Returns the server response map on success, or throws an Exception on error.
  Future<Map<String, dynamic>> createFromForm({
    required int? idBonggolan,
    required DateTime dateCreate,
    required int idWarehouse,
    double? berat,
    required InputMode? mode,
    String? brokerNoProduksi,
    String? injectNoProduksi,
    String? noBongkarSusun,
    required String Function(DateTime) toDbDateString, // inject formatter
  }) async {
    // 1) Validate
    final err = validateCreate(
      idBonggolan: idBonggolan,
      dateCreate: dateCreate,
      berat: berat,
      mode: mode,
      brokerNoProduksi: brokerNoProduksi,
      injectNoProduksi: injectNoProduksi,
      noBongkarSusun: noBongkarSusun,
    );
    if (err != null) {
      throw Exception(err);
    }

    // 2) Build body
    final body = _buildCreateBody(
      idBonggolan: idBonggolan!,
      idWarehouse: idWarehouse,
      dateCreateYmd: toDbDateString(dateCreate),
      berat: berat,
      mode: mode,
      brokerNoProduksi: brokerNoProduksi,
      injectNoProduksi: injectNoProduksi,
      noBongkarSusun: noBongkarSusun,
    );

    // 3) API call
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.createBonggolan(body);

      lastCreatedNoBonggolan =
          res['data']?['header']?['NoBonggolan']?.toString();

      // 4) Refresh list and select the new one
      await fetchHeaders(search: _search);
      if (lastCreatedNoBonggolan != null) {
        setSelected(lastCreatedNoBonggolan);
      }

      return res;
    } catch (e) {
      errorMessage = e.toString();
      throw Exception(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  /// Build body for PUT based on non-null inputs only
  Map<String, dynamic> _buildUpdateBody({
    DateTime? dateCreate,
    DateTime? dateUsage,
    int? idBonggolan,
    int? idWarehouse,
    double? berat,
    int? idStatus,
    String? blok,
    String? idLokasi,
    required String Function(DateTime) toDbDateString,
  }) {
    final body = <String, dynamic>{};

    if (dateCreate != null) body['DateCreate'] = toDbDateString(dateCreate);
    if (dateUsage  != null) body['DateUsage']  = toDbDateString(dateUsage);
    if (idBonggolan != null) body['IdBonggolan'] = idBonggolan;
    if (idWarehouse != null) body['IdWarehouse'] = idWarehouse;
    if (berat != null) body['Berat'] = berat;
    if (idStatus != null) body['IdStatus'] = idStatus;
    if (blok != null && blok.trim().isNotEmpty) body['Blok'] = blok.trim();
    if (idLokasi != null && idLokasi.trim().isNotEmpty) {
      body['IdLokasi'] = idLokasi.trim();
    }

    return body;
  }

  /// Optional: lightweight validation for update
  String? validateUpdate({
    int? idBonggolan,
    int? idWarehouse,
    double? berat,
  }) {
    if (berat != null && berat <= 0) return 'Berat harus > 0.';
    // add other rules if needed
    return null;
  }

  /// Full update flow
  Future<Map<String, dynamic>> updateFromForm({
    required String noBonggolan,
    DateTime? dateCreate,
    DateTime? dateUsage,
    int? idBonggolan,
    int? idWarehouse,
    double? berat,
    int? idStatus,
    String? blok,
    String? idLokasi,
    required String Function(DateTime) toDbDateString,
  }) async {
    final err = validateUpdate(
      idBonggolan: idBonggolan,
      idWarehouse: idWarehouse,
      berat: berat,
    );
    if (err != null) throw Exception(err);

    final body = _buildUpdateBody(
      dateCreate: dateCreate,
      dateUsage: dateUsage,
      idBonggolan: idBonggolan,
      idWarehouse: idWarehouse,
      berat: berat,
      idStatus: idStatus,
      blok: blok,
      idLokasi: idLokasi,
      toDbDateString: toDbDateString,
    );

    if (body.isEmpty) {
      throw Exception('Tidak ada perubahan yang dikirim.');
    }

    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.updateBonggolan(noBonggolan, body);

      // Refresh list and keep current selection
      await fetchHeaders(search: _search);
      setSelected(noBonggolan);

      return res;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }



  /// DELETE Bonggolan
  Future<void> deleteBonggolan(String noBonggolan) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await repository.deleteBonggolan(noBonggolan);

      // Remove from current list
      items.removeWhere((e) => e.noBonggolan == noBonggolan);

      // Clear selection if deleted one is selected
      if (selectedNoBonggolan == noBonggolan) {
        selectedNoBonggolan = null;
      }

      // Optional: refresh current list from server
      await refreshCurrent();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  // Screen lifecycle helper
  void resetForScreen() {
    selectedNoBonggolan = null;
  }
}
