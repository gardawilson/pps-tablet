// lib/features/bonggolan/view_model/reject_view_model.dart
import 'package:flutter/material.dart';
import '../model/crusher_header_model.dart';
import '../repository/crusher_repository.dart';

// Keep this in the same file or export InputMode from your dialog file
enum InputMode { crusherProduction, bongkarSusun }

class CrusherViewModel extends ChangeNotifier {
  final  CrusherRepository repository;
  CrusherViewModel({required this.repository});

  // === LIST STATE ===
  List<CrusherHeader> items = [];
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
  String? selectedNoCrusher;
  CrusherHeader? get selectedItem {
    final i = items.indexWhere((e) => e.noCrusher == selectedNoCrusher);
    return i == -1 ? null : items[i];
  }

  void setSelected(String? no) {
    if (selectedNoCrusher == no) return;
    selectedNoCrusher = no;
    notifyListeners();
  }

  // === FETCH HEADER (RESET) ===
  Future<void> fetchHeaders({String search = ''}) async {
    _page = 1;
    _search = search;
    items = [];
    errorMessage = '';
    isLoading = true;
    selectedNoCrusher = null;
    notifyListeners();

    try {
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      items = (result['items'] as List<CrusherHeader>);
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
      final more = (result['items'] as List<CrusherHeader>);
      items.addAll(more);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  // === CREATE (POST /api/labels/crusher) ===
  String? lastCreatedNoCrusher;

  /// Validate inputs for create Crusher.
  /// Returns `null` if OK, otherwise the error message.
  String? validateCreate({
    required int? idCrusher,
    required DateTime dateCreate,
    double? berat,
    required InputMode? mode,
    String? noCrusherProduksi, // must start with "G."
    String? noBongkarSusun,    // must start with "BG."
  }) {
    if (idCrusher == null) return 'Pilih jenis crusher terlebih dahulu.';
    if (berat != null && berat <= 0) return 'Berat harus angka > 0.';

    if (mode != null) {
      switch (mode) {
        case InputMode.crusherProduction:
          if (noCrusherProduksi == null || noCrusherProduksi.trim().isEmpty) {
            return 'Nomor produksi Crusher belum diisi.';
          }
          if (!noCrusherProduksi.startsWith('G.')) {
            return 'Format nomor produksi Crusher harus diawali "G."';
          }
          break;
        case InputMode.bongkarSusun:
          if (noBongkarSusun == null || noBongkarSusun.trim().isEmpty) {
            return 'Nomor Bongkar Susun belum diisi.';
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
    required int idCrusher,
    required int idWarehouse,
    required String dateCreateYmd, // use toDbDateString
    double? berat,
    InputMode? mode,
    String? noCrusherProduksi, // "G.****"
    String? noBongkarSusun,    // "BG.****"
    String? blok,
    String? idLokasi,
    int? idStatus,
  }) {
    // Decide ProcessedCode based on selected mode
    String? processedCode;
    switch (mode) {
      case InputMode.crusherProduction:
        processedCode = noCrusherProduksi?.trim();
        break;
      case InputMode.bongkarSusun:
        processedCode = noBongkarSusun?.trim();
        break;
      default:
        processedCode = null;
    }

    return <String, dynamic>{
      "header": {
        "IdCrusher": idCrusher,
        "IdWarehouse": idWarehouse,
        "DateCreate": dateCreateYmd,
        if (berat != null) "Berat": berat,
        if (blok != null && blok.isNotEmpty) "Blok": blok,
        if (idLokasi != null && idLokasi.isNotEmpty) "IdLokasi": idLokasi,
        if (idStatus != null) "IdStatus": idStatus,
      },
      if (processedCode != null && processedCode.isNotEmpty)
        "ProcessedCode": processedCode,
    };
  }

  /// End-to-end create: validate → build body → POST → refresh list.
  /// Returns the server response map on success, or throws an Exception on error.
  Future<Map<String, dynamic>> createFromForm({
    required int? idCrusher,
    required DateTime dateCreate,
    required int idWarehouse,
    double? berat,
    required InputMode? mode,
    String? noCrusherProduksi, // "G.****"
    String? noBongkarSusun,    // "BG.****"
    String? blok,
    String? idLokasi,
    int? idStatus,
    required String Function(DateTime) toDbDateString, // inject formatter
  }) async {
    // 1) Validate
    final err = validateCreate(
      idCrusher: idCrusher,
      dateCreate: dateCreate,
      berat: berat,
      mode: mode,
      noCrusherProduksi: noCrusherProduksi,
      noBongkarSusun: noBongkarSusun,
    );
    if (err != null) {
      throw Exception(err);
    }

    // 2) Build body
    final body = _buildCreateBody(
      idCrusher: idCrusher!,
      idWarehouse: idWarehouse,
      dateCreateYmd: toDbDateString(dateCreate),
      berat: berat,
      mode: mode,
      noCrusherProduksi: noCrusherProduksi,
      noBongkarSusun: noBongkarSusun,
      blok: blok,
      idLokasi: idLokasi,
      idStatus: idStatus,
    );

    // 3) API call
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.createCrusher(body);

      // server returns PascalCase
      lastCreatedNoCrusher =
          res['data']?['header']?['NoCrusher']?.toString();

      // 4) Refresh list and select the new one
      await fetchHeaders(search: _search);
      if (lastCreatedNoCrusher != null) {
        setSelected(lastCreatedNoCrusher);
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
    int? idCrusher,
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
    if (idCrusher != null) body['IdCrusher'] = idCrusher;
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
    int? idCrusher,
    int? idWarehouse,
    double? berat,
  }) {
    if (berat != null && berat <= 0) return 'Berat harus > 0.';
    // add other rules if needed
    return null;
  }

  /// Full update flow
  Future<Map<String, dynamic>> updateFromForm({
    required String noCrusher,
    DateTime? dateCreate,
    DateTime? dateUsage,
    int? idCrusher,
    int? idWarehouse,
    double? berat,
    int? idStatus,
    String? blok,
    String? idLokasi,
    required String Function(DateTime) toDbDateString,
  }) async {
    final err = validateUpdate(
      idCrusher: idCrusher,
      idWarehouse: idWarehouse,
      berat: berat,
    );
    if (err != null) throw Exception(err);

    final body = _buildUpdateBody(
      dateCreate: dateCreate,
      dateUsage: dateUsage,
      idCrusher: idCrusher,
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

      final res = await repository.updateCrusher(noCrusher, body);

      // Refresh list and keep current selection
      await fetchHeaders(search: _search);
      setSelected(noCrusher);

      return res;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// DELETE Crusher
  Future<void> deleteCrusher(String noCrusher) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await repository.deleteCrusher(noCrusher);

      // Remove from current list
      items.removeWhere((e) => e.noCrusher == noCrusher);

      // Clear selection if deleted one is selected
      if (selectedNoCrusher == noCrusher) {
        selectedNoCrusher = null;
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
    selectedNoCrusher = null;
  }
}
