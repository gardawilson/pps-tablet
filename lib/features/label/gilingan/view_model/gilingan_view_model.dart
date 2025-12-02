import 'package:flutter/material.dart';

import '../model/gilingan_header_model.dart';
import '../model/gilingan_partial_model.dart';
import '../repository/gilingan_repository.dart';

/// From which process this Gilingan comes
/// - produksi     -> W.******  (GilinganProduksiOutput)
/// - bongkarSusun -> BG.****** (BongkarSusunOutputGilingan)
enum GilinganInputMode { produksi, bongkarSusun }

class GilinganViewModel extends ChangeNotifier {
  final GilinganRepository repository;
  GilinganViewModel({required this.repository});

  // === LIST STATE ===
  List<GilinganHeader> items = [];
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

  // Field di dalam GilinganViewModel (contoh)
  GilinganPartialInfo? partialInfo;
  String? partialError;
  bool isPartialLoading = false;

  /// Optional: simpan NoGilingan terpilih
  String? currentNoGilingan;


  // Highlight row
  String? selectedNoGilingan;
  GilinganHeader? get selectedItem {
    final i = items.indexWhere((e) => e.noGilingan == selectedNoGilingan);
    return i == -1 ? null : items[i];
  }

  void setSelected(String? no) {
    if (selectedNoGilingan == no) return;
    selectedNoGilingan = no;
    notifyListeners();
  }

  // === FETCH HEADER (RESET) ===
  Future<void> fetchHeaders({String search = ''}) async {
    _page = 1;
    _search = search;
    items = [];
    errorMessage = '';
    isLoading = true;
    selectedNoGilingan = null;
    notifyListeners();

    try {
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      items = (result['items'] as List<GilinganHeader>);
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
      final more = (result['items'] as List<GilinganHeader>);
      items.addAll(more);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  // === CREATE (POST /api/labels/gilingan) ===
  String? lastCreatedNoGilingan;

  /// Validate inputs for create Gilingan
  /// - must choose jenis gilingan
  /// - berat > 0 if filled
  /// - mode (produksi/bongkar) required
  /// - outputCode W.**** or BG.**** required
  String? validateCreate({
    required int? idGilingan,
    required DateTime dateCreate,
    double? berat,
    required GilinganInputMode? mode,
    String? noProduksiOutput, // W.******
    String? noBongkarSusun,   // BG.******
  }) {
    if (idGilingan == null) return 'Pilih jenis gilingan terlebih dahulu.';
    if (berat != null && berat <= 0) return 'Berat harus angka > 0.';

    if (mode == null) {
      return 'Pilih proses sumber (Produksi atau Bongkar Susun).';
    }

    switch (mode) {
      case GilinganInputMode.produksi:
        if (noProduksiOutput == null || noProduksiOutput.trim().isEmpty) {
          return 'Nomor produksi (W...) belum diisi.';
        }
        if (!noProduksiOutput.trim().startsWith('W.')) {
          return 'Nomor produksi harus diawali "W."';
        }
        break;

      case GilinganInputMode.bongkarSusun:
        if (noBongkarSusun == null || noBongkarSusun.trim().isEmpty) {
          return 'Nomor Bongkar Susun (BG...) belum diisi.';
        }
        if (!noBongkarSusun.trim().startsWith('BG.')) {
          return 'Nomor Bongkar Susun harus diawali "BG."';
        }
        break;
    }

    return null;
  }

  Map<String, dynamic> _buildCreateBody({
    required int idGilingan,
    required String dateCreateYmd,
    double? berat,
    bool? isPartial,
    int? idStatus,
    String? blok,
    String? idLokasi,
    required GilinganInputMode? mode,
    String? noProduksiOutput, // W.******
    String? noBongkarSusun,   // BG.******
  }) {
    // Decide outputCode based on mode
    String? outputCode;
    switch (mode) {
      case GilinganInputMode.produksi:
        outputCode = noProduksiOutput?.trim();
        break;
      case GilinganInputMode.bongkarSusun:
        outputCode = noBongkarSusun?.trim();
        break;
      default:
        outputCode = null;
    }

    final header = <String, dynamic>{
      "IdGilingan": idGilingan,
      "DateCreate": dateCreateYmd,
      if (berat != null) "Berat": berat,
      if (isPartial != null) "IsPartial": isPartial ? 1 : 0,
      if (idStatus != null) "IdStatus": idStatus,
      if (blok != null && blok.isNotEmpty) "Blok": blok,
      if (idLokasi != null && idLokasi.isNotEmpty) "IdLokasi": idLokasi,
    };

    return <String, dynamic>{
      "header": header,
      if (outputCode != null && outputCode.isNotEmpty) "outputCode": outputCode,
    };
  }

  /// Full create flow for Gilingan from form
  Future<Map<String, dynamic>> createFromForm({
    required int? idGilingan,
    required DateTime dateCreate,
    double? berat,
    bool? isPartial,
    int? idStatus,
    String? blok,
    String? idLokasi,

    /// mode: Produksi (W.***) atau Bongkar (BG.***)
    required GilinganInputMode? mode,

    /// NoProduksi for W (e.g. "W.0000004133")
    String? noProduksiOutput,

    /// NoBongkarSusun for BG (e.g. "BG.0000004133")
    String? noBongkarSusun,

    required String Function(DateTime) toDbDateString, // yyyy-MM-dd
  }) async {
    // 1) Validate
    final err = validateCreate(
      idGilingan: idGilingan,
      dateCreate: dateCreate,
      berat: berat,
      mode: mode,
      noProduksiOutput: noProduksiOutput,
      noBongkarSusun: noBongkarSusun,
    );
    if (err != null) {
      throw Exception(err);
    }

    // 2) Build body
    final body = _buildCreateBody(
      idGilingan: idGilingan!,
      dateCreateYmd: toDbDateString(dateCreate),
      berat: berat,
      isPartial: isPartial,
      idStatus: idStatus,
      blok: blok,
      idLokasi: idLokasi,
      mode: mode,
      noProduksiOutput: noProduksiOutput,
      noBongkarSusun: noBongkarSusun,
    );

    // 3) API call
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.createGilingan(body);

      lastCreatedNoGilingan =
          res['data']?['header']?['NoGilingan']?.toString();

      // 4) Refresh list & select newly created row
      await fetchHeaders(search: _search);
      if (lastCreatedNoGilingan != null) {
        setSelected(lastCreatedNoGilingan);
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

  // === UPDATE (PUT /api/labels/gilingan/:noGilingan) ===

  Map<String, dynamic> _buildUpdateBody({
    DateTime? dateCreate,
    DateTime? dateUsage,
    int? idGilingan,
    double? berat,
    int? idStatus,
    bool? isPartial,
    String? blok,
    String? idLokasi,
    required String Function(DateTime) toDbDateString,
  }) {
    final header = <String, dynamic>{};

    if (dateCreate != null) header['DateCreate'] = toDbDateString(dateCreate);
    if (dateUsage != null) header['DateUsage'] = toDbDateString(dateUsage);
    if (idGilingan != null) header['IdGilingan'] = idGilingan;
    if (berat != null) header['Berat'] = berat;
    if (idStatus != null) header['IdStatus'] = idStatus;
    if (isPartial != null) header['IsPartial'] = isPartial ? 1 : 0;
    if (blok != null && blok.trim().isNotEmpty) header['Blok'] = blok.trim();
    if (idLokasi != null && idLokasi.trim().isNotEmpty) {
      header['IdLokasi'] = idLokasi.trim();
    }

    return {"header": header};
  }

  String? validateUpdate({
    double? berat,
  }) {
    if (berat != null && berat <= 0) return 'Berat harus > 0.';
    return null;
  }

  Future<Map<String, dynamic>> updateFromForm({
    required String noGilingan,
    DateTime? dateCreate,
    DateTime? dateUsage,
    int? idGilingan,
    double? berat,
    int? idStatus,
    bool? isPartial,
    String? blok,
    String? idLokasi,
    required String Function(DateTime) toDbDateString,
  }) async {
    final err = validateUpdate(berat: berat);
    if (err != null) throw Exception(err);

    final body = _buildUpdateBody(
      dateCreate: dateCreate,
      dateUsage: dateUsage,
      idGilingan: idGilingan,
      berat: berat,
      idStatus: idStatus,
      isPartial: isPartial,
      blok: blok,
      idLokasi: idLokasi,
      toDbDateString: toDbDateString,
    );

    if ((body['header'] as Map).isEmpty) {
      throw Exception('Tidak ada perubahan yang dikirim.');
    }

    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.updateGilingan(noGilingan, body);

      // Refresh list and keep this row selected
      await fetchHeaders(search: _search);
      setSelected(noGilingan);

      return res;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // === DELETE ===
  Future<void> deleteGilingan(String noGilingan) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await repository.deleteGilingan(noGilingan);

      items.removeWhere((e) => e.noGilingan == noGilingan);

      if (selectedNoGilingan == noGilingan) {
        selectedNoGilingan = null;
      }

      await refreshCurrent();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }





  // =============================
//  LOAD PARTIAL INFO (GILINGAN)
// =============================
  Future<void> loadPartialInfo({String? noGilingan}) async {
    // pakai parameter kalau ada, kalau tidak pakai currentNoGilingan di VM
    final ng = noGilingan ?? currentNoGilingan;

    if (ng == null || ng.isEmpty) {
      partialError = "NoGilingan not selected";
      partialInfo = null;
      notifyListeners();
      return;
    }

    try {
      isPartialLoading = true;
      partialError = null;
      notifyListeners();

      debugPrint("➡️ [GilinganVM] loadPartialInfo noGilingan=$ng");

      partialInfo = await repository.fetchPartialInfo(
        noGilingan: ng,
      );
    } catch (e) {
      partialError = e.toString();
      partialInfo = null;
      debugPrint("❌ Error loadPartialInfo($ng): $partialError");
    } finally {
      isPartialLoading = false;
      notifyListeners();
    }
  }


  // Screen lifecycle helper
  void resetForScreen() {
    selectedNoGilingan = null;
  }
}
