import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/packing_header_model.dart';
import '../model/packing_partial_model.dart';
import '../repository/packing_repository.dart';

/// Dari proses mana Barang Jadi (Packing) ini berasal (label sumber)
/// - packing       -> BD.******   (PackingProduksiOutputLabelBJ)
/// - inject        -> S.******    (InjectProduksiOutputBarangJadi)
/// - bongkarSusun  -> BG.******   (BongkarSusunOutputBarangjadi)
/// - retur         -> L.******    (BJReturBarangJadi_d)
enum PackingInputMode {
  packing,
  inject,
  bongkarSusun,
  retur,
}

class PackingViewModel extends ChangeNotifier {
  final PackingRepository repository;

  PackingViewModel({required this.repository}) {
    // === PagingController v5 ===
    pagingController = PagingController<int, PackingHeader>(
      // pageKey kita treat sebagai "page index" (0,1,2,...)
      fetchPage: _fetchPage,
      // Ditanya: "next page key berapa?" setelah setiap page berhasil di-load
      getNextPageKey: _getNextPageKey,
    );
  }

  static const int _pageSize = 20;

  /// Controller untuk HorizontalPagedTable
  late final PagingController<int, PackingHeader> pagingController;

  // === LIST STATE (untuk AppBar, dsb) ===
  List<PackingHeader> items = [];
  bool isLoading = false;
  String errorMessage = '';

  int _total = 0;
  int get totalCount => _total;

  String _search = '';
  String get currentSearch => _search;

  // pakai info dari PagingState
  bool get hasMore => pagingController.value.hasNextPage;

  // === PARTIAL INFO STATE ===
  PackingPartialInfo? partialInfo;
  String? partialError;
  bool isPartialLoading = false;

  /// Optional: simpan NoBJ terpilih (misal untuk popover)
  String? currentNoBJ;

  // Highlight row
  String? selectedNoBJ;
  PackingHeader? get selectedItem {
    final i = items.indexWhere((e) => e.noBJ == selectedNoBJ);
    return i == -1 ? null : items[i];
  }

  void setSelected(String? no) {
    if (selectedNoBJ == no) return;
    selectedNoBJ = no;
    notifyListeners();
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }

  // ==========================
  // FETCH HEADER (TRIGGER PAGING)
  // ==========================

  Future<void> fetchHeaders({String search = ''}) async {
    _search = search;
    errorMessage = '';
    _total = 0;
    items = [];
    selectedNoBJ = null;

    isLoading = true;
    notifyListeners();

    // akan memicu _fetchPage(pageKey pertama) lagi
    pagingController.refresh();
  }

  Future<void> refreshCurrent() => fetchHeaders(search: _search);
  Future<void> applySearch(String search) => fetchHeaders(search: search);

  // ==========================
  // IMPLEMENTASI PAGING v5
  // ==========================

  Future<List<PackingHeader>> _fetchPage(int pageKey) async {
    try {
      // first page → set loading true utk AppBar
      if (pageKey == 0) {
        isLoading = true;
        errorMessage = '';
        notifyListeners();
      }

      final apiPage = pageKey;

      final result = await repository.fetchHeaders(
        page: apiPage,
        limit: _pageSize,
        search: _search,
      );

      final list = (result['items'] as List<PackingHeader>);
      _total = (result['total'] as int?) ?? list.length;

      errorMessage = '';

      // update cache items lokal (flatten)
      if (pageKey == 0) {
        items = List<PackingHeader>.from(list);
      } else {
        items = [
          ...items,
          ...list,
        ];
      }

      return list;
    } catch (e) {
      errorMessage = e.toString();
      rethrow; // biar PagingController juga tau kalau error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int? _getNextPageKey(
      PagingState<int, PackingHeader> state,
      ) {
    if (state.lastPageIsEmpty) return null;
    return state.nextIntPageKey;
  }

  // ==========================
  // CREATE (POST /labels/packing)
  // ==========================

  String? lastCreatedNoBJ;

  /// Validasi input create Packing (Barang Jadi)
  String? validateCreate({
    required int? idBJ,
    required DateTime dateCreate,
    double? pcs,
    double? berat,
    required PackingInputMode? mode,
    String? packingCode,      // BD.******
    String? injectCode,       // S.******
    String? bongkarSusunCode, // BG.******
    String? returCode,        // L.******
  }) {
    if (mode == null) {
      return 'Pilih proses sumber (Packing / Inject / Bongkar Susun / Retur).';
    }

    final bool isInjectMode = mode == PackingInputMode.inject;

    // Jenis wajib KECUALI untuk INJECT multi (IdBJ boleh null)
    if (!isInjectMode && idBJ == null) {
      return 'Pilih jenis Barang Jadi terlebih dahulu.';
    }

    if (pcs != null && pcs <= 0) {
      return 'PCS harus > 0.';
    }
    if (berat != null && berat <= 0) {
      return 'Berat harus > 0.';
    }

    String? code;
    String prefix;

    switch (mode) {
      case PackingInputMode.packing:
        code = packingCode;
        prefix = 'BD.';
        break;
      case PackingInputMode.inject:
        code = injectCode;
        prefix = 'S.';
        break;
      case PackingInputMode.bongkarSusun:
        code = bongkarSusunCode;
        prefix = 'BG.';
        break;
      case PackingInputMode.retur:
        code = returCode;
        prefix = 'L.';
        break;
    }

    if (code == null || code.trim().isEmpty) {
      return 'Nomor label sumber ($prefix...) belum diisi.';
    }
    if (!code.trim().startsWith(prefix)) {
      return 'Nomor label sumber harus diawali "$prefix"';
    }

    return null;
  }

  Map<String, dynamic> _buildCreateBody({
    required int? idBJ,
    required String dateCreateYmd,
    String? jam,
    double? pcs,
    double? berat,
    bool? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    required PackingInputMode? mode,
    String? packingCode,      // BD.******
    String? injectCode,       // S.******
    String? bongkarSusunCode, // BG.******
    String? returCode,        // L.******
  }) {
    String? outputCode;
    switch (mode) {
      case PackingInputMode.packing:
        outputCode = packingCode?.trim();
        break;
      case PackingInputMode.inject:
        outputCode = injectCode?.trim();
        break;
      case PackingInputMode.bongkarSusun:
        outputCode = bongkarSusunCode?.trim();
        break;
      case PackingInputMode.retur:
        outputCode = returCode?.trim();
        break;
      default:
        outputCode = null;
    }

    final header = <String, dynamic>{
      // ⬇️ Untuk INJECT multi, IdBJ boleh null → field ini tidak dikirim
      if (idBJ != null) "IdBJ": idBJ,
      "DateCreate": dateCreateYmd,
      if (jam != null && jam.isNotEmpty) "Jam": jam,
      if (pcs != null) "Pcs": pcs,
      if (berat != null) "Berat": berat,
      if (isPartial != null) "IsPartial": isPartial ? 1 : 0,
      if (idWarehouse != null) "IdWarehouse": idWarehouse,
      if (blok != null && blok.isNotEmpty) "Blok": blok,
      if (idLokasi != null && idLokasi.isNotEmpty) "IdLokasi": idLokasi,
    };

    return <String, dynamic>{
      "header": header,
      if (outputCode != null && outputCode.isNotEmpty) "outputCode": outputCode,
    };
  }

  /// Full create flow from form
  Future<Map<String, dynamic>> createFromForm({
    required int? idBJ,
    required DateTime dateCreate,
    double? pcs,
    double? berat,
    bool? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    String? jam,

    /// mode: Packing / Inject / Bongkar Susun / Retur
    required PackingInputMode? mode,

    String? packingCode,      // BD.******
    String? injectCode,       // S.******
    String? bongkarSusunCode, // BG.******
    String? returCode,        // L.******

    required String Function(DateTime) toDbDateString, // yyyy-MM-dd
  }) async {
    // 1) Validate
    final err = validateCreate(
      idBJ: idBJ,
      dateCreate: dateCreate,
      pcs: pcs,
      berat: berat,
      mode: mode,
      packingCode: packingCode,
      injectCode: injectCode,
      bongkarSusunCode: bongkarSusunCode,
      returCode: returCode,
    );
    if (err != null) {
      throw Exception(err);
    }

    // 2) Build body
    final body = _buildCreateBody(
      idBJ: idBJ, // ⬅️ boleh null untuk Inject multi
      dateCreateYmd: toDbDateString(dateCreate),
      jam: jam,
      pcs: pcs,
      berat: berat,
      isPartial: isPartial,
      idWarehouse: idWarehouse,
      blok: blok,
      idLokasi: idLokasi,
      mode: mode,
      packingCode: packingCode,
      injectCode: injectCode,
      bongkarSusunCode: bongkarSusunCode,
      returCode: returCode,
    );

    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.createPacking(body);

      final data = res['data'] as Map<String, dynamic>? ?? {};
      final List headers = data['headers'] as List? ?? [];

      if (headers.isNotEmpty) {
        lastCreatedNoBJ = headers.first['NoBJ']?.toString();
      } else {
        lastCreatedNoBJ = res['data']?['header']?['NoBJ']?.toString();
      }

      await fetchHeaders(search: _search);
      if (lastCreatedNoBJ != null) {
        setSelected(lastCreatedNoBJ);
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

  // ==========================
  // UPDATE (PUT /labels/packing/:noBJ)
  // ==========================

  Map<String, dynamic> _buildUpdateBody({
    DateTime? dateCreate,
    int? idBJ,
    double? pcs,
    double? berat,
    bool? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    String? jam,

    /// null  -> mapping tidak disentuh
    /// ""    -> mapping dihapus
    /// "BD..." / "S..." / "BG..." / "L..." -> mapping diganti
    String? outputCode,
    required String Function(DateTime) toDbDateString,
  }) {
    final header = <String, dynamic>{};

    if (dateCreate != null) header['DateCreate'] = toDbDateString(dateCreate);
    if (idBJ != null) header['IdBJ'] = idBJ;
    if (pcs != null) header['Pcs'] = pcs;
    if (berat != null) header['Berat'] = berat;
    if (isPartial != null) header['IsPartial'] = isPartial ? 1 : 0;
    if (idWarehouse != null) header['IdWarehouse'] = idWarehouse;
    if (blok != null && blok.trim().isNotEmpty) header['Blok'] = blok.trim();
    if (idLokasi != null && idLokasi.trim().isNotEmpty) {
      header['IdLokasi'] = idLokasi.trim();
    }
    if (jam != null && jam.trim().isNotEmpty) {
      header['Jam'] = jam.trim();
    }

    final body = <String, dynamic>{
      "header": header,
    };

    if (outputCode != null) {
      body['outputCode'] = outputCode;
    }

    return body;
  }

  String? validateUpdate({
    double? pcs,
    double? berat,
  }) {
    if (pcs != null && pcs <= 0) return 'PCS harus > 0.';
    if (berat != null && berat <= 0) return 'Berat harus > 0.';
    return null;
  }

  Future<Map<String, dynamic>> updateFromForm({
    required String noBJ,
    DateTime? dateCreate,
    int? idBJ,
    double? pcs,
    double? berat,
    bool? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    String? jam,
    String? outputCode,
    required String Function(DateTime) toDbDateString,
  }) async {
    final err = validateUpdate(pcs: pcs, berat: berat);
    if (err != null) throw Exception(err);

    final body = _buildUpdateBody(
      dateCreate: dateCreate,
      idBJ: idBJ,
      pcs: pcs,
      berat: berat,
      isPartial: isPartial,
      idWarehouse: idWarehouse,
      blok: blok,
      idLokasi: idLokasi,
      jam: jam,
      outputCode: outputCode,
      toDbDateString: toDbDateString,
    );

    if ((body['header'] as Map).isEmpty && !body.containsKey('outputCode')) {
      throw Exception('Tidak ada perubahan yang dikirim.');
    }

    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.updatePacking(noBJ, body);

      await fetchHeaders(search: _search);
      setSelected(noBJ);

      return res;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // DELETE
  // ==========================
  Future<void> deletePacking(String noBJ) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await repository.deletePacking(noBJ);

      items.removeWhere((e) => e.noBJ == noBJ);

      if (selectedNoBJ == noBJ) {
        selectedNoBJ = null;
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

  // ==========================
  // LOAD PARTIAL INFO
  // ==========================
  Future<void> loadPartialInfo({String? noBJ}) async {
    final nbj = noBJ ?? currentNoBJ;

    if (nbj == null || nbj.isEmpty) {
      partialError = "NoBJ not selected";
      partialInfo = null;
      notifyListeners();
      return;
    }

    try {
      isPartialLoading = true;
      partialError = null;
      notifyListeners();

      debugPrint("➡️ [PackingVM] loadPartialInfo NoBJ=$nbj");

      partialInfo = await repository.fetchPartialInfo(
        noBJ: nbj,
      );
    } catch (e) {
      partialError = e.toString();
      partialInfo = null;
      debugPrint("❌ Error loadPartialInfo($nbj): $partialError");
    } finally {
      isPartialLoading = false;
      notifyListeners();
    }
  }

  void resetForScreen() {
    selectedNoBJ = null;
    currentNoBJ = null;
    partialInfo = null;
    partialError = null;
  }
}
