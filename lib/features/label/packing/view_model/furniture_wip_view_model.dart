// lib/features/furniture_wip/view_model/furniture_wip_view_model.dart

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/furniture_wip_header_model.dart';
import '../model/furniture_wip_partial_model.dart';
import '../repository/furniture_wip_repository.dart';

/// Dari proses mana Furniture WIP ini berasal (label sumber)
/// - hotStamping  -> BH.******
/// - pasangKunci  -> BI.******
/// - bongkarSusun -> BG.******
/// - retur        -> L.******
/// - spanner      -> BJ.******
/// - inject       -> S.******
enum FurnitureWipInputMode {
  hotStamping,
  pasangKunci,
  bongkarSusun,
  retur,
  spanner,
  inject,
}

class FurnitureWipViewModel extends ChangeNotifier {
  final FurnitureWipRepository repository;

  FurnitureWipViewModel({required this.repository}) {
    // === PagingController v5 ===
    pagingController = PagingController<int, FurnitureWipHeader>(
      // pageKey di sini kita treat sebagai "page index" (0,1,2,...)
      fetchPage: _fetchPage,
      // Ditanya: "next page key berapa?" setelah setiap page berhasil di-load
      getNextPageKey: _getNextPageKey,
    );
  }

  static const int _pageSize = 20;

  /// Controller untuk HorizontalPagedTable
  late final PagingController<int, FurnitureWipHeader> pagingController;

  // === LIST STATE LAMA (masih dipakai utk AppBar, dsb) ===
  List<FurnitureWipHeader> items = [];
  bool isLoading = false;
  String errorMessage = '';

  int _total = 0;
  int get totalCount => _total;

  String _search = '';
  String get currentSearch => _search;

  // pakai info dari PagingState
  bool get hasMore => pagingController.value.hasNextPage;

  // === PARTIAL INFO STATE ===
  FurnitureWipPartialInfo? partialInfo;
  String? partialError;
  bool isPartialLoading = false;

  /// Optional: simpan NoFurnitureWIP terpilih (misal untuk popover)
  String? currentNoFurnitureWip;

  // Highlight row
  String? selectedNoFurnitureWip;
  FurnitureWipHeader? get selectedItem {
    final i =
    items.indexWhere((e) => e.noFurnitureWip == selectedNoFurnitureWip);
    return i == -1 ? null : items[i];
  }

  void setSelected(String? no) {
    if (selectedNoFurnitureWip == no) return;
    selectedNoFurnitureWip = no;
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
  ///
  /// Dipanggil saat:
  /// - pertama kali screen muncul
  /// - user ganti search
  ///
  /// Actual load dilakukan oleh `_fetchPage` via PagingController.
  Future<void> fetchHeaders({String search = ''}) async {
    _search = search;
    errorMessage = '';
    _total = 0;
    items = [];
    selectedNoFurnitureWip = null;

    isLoading = true;
    notifyListeners();

    // akan memicu fetchPage(pageKey pertama) lagi
    pagingController.refresh();
  }

  // Quick helpers (masih dipakai di beberapa tempat)
  Future<void> refreshCurrent() => fetchHeaders(search: _search);
  Future<void> applySearch(String search) => fetchHeaders(search: search);

  // ==========================
  // IMPLEMENTASI PAGING v5
  // ==========================

  /// Dipanggil otomatis oleh PagingController ketika butuh page baru.
  ///
  /// `pageKey` (int) kita treat sebagai index mulai 0,
  /// sedangkan API kita butuh "page" mulai 1 → `page = pageKey + 1`.
  Future<List<FurnitureWipHeader>> _fetchPage(int pageKey) async {
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

      final list = (result['items'] as List<FurnitureWipHeader>);
      _total = (result['total'] as int?) ?? list.length;

      errorMessage = '';

      // update cache items lokal (flatten)
      if (pageKey == 0) {
        items = List<FurnitureWipHeader>.from(list);
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

  /// Menentukan key page berikutnya.
  ///
  /// Signature baru: `NextPageKeyCallback<PageKeyType, ItemType>`
  /// = `PageKeyType? Function(PagingState<PageKeyType, ItemType> state)`
  int? _getNextPageKey(
      PagingState<int, FurnitureWipHeader> state,
      ) {
    // Kalau last page kosong → sudah mentok
    if (state.lastPageIsEmpty) return null;

    // Cara paling simple: pakai extension nextIntPageKey
    // (0,1,2,3,...)
    return state.nextIntPageKey;
  }

  // ==========================
// CREATE (POST /labels/furniture-wip)
// ==========================

  String? lastCreatedNoFurnitureWip;

  /// Validasi input create Furniture WIP
  String? validateCreate({
    required int? idFurnitureWip,
    required DateTime dateCreate,
    double? pcs,
    double? berat,
    required FurnitureWipInputMode? mode,
    String? hotStampCode,      // BH.******
    String? pasangKunciCode,   // BI.******
    String? bongkarSusunCode,  // BG.******
    String? returCode,         // L.******
    String? spannerCode,       // BJ.******
    String? injectCode,        // S.******
  }) {
    // Mode wajib
    if (mode == null) {
      return 'Pilih proses sumber (Hot Stamping / Pasang Kunci / dll).';
    }

    final bool isInjectMode = mode == FurnitureWipInputMode.inject;

    // Jenis wajib KECUALI untuk INJECT multi (IdFurnitureWIP boleh null)
    if (!isInjectMode && idFurnitureWip == null) {
      return 'Pilih jenis Furniture WIP terlebih dahulu.';
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
      case FurnitureWipInputMode.hotStamping:
        code = hotStampCode;
        prefix = 'BH.';
        break;
      case FurnitureWipInputMode.pasangKunci:
        code = pasangKunciCode;
        prefix = 'BI.';
        break;
      case FurnitureWipInputMode.bongkarSusun:
        code = bongkarSusunCode;
        prefix = 'BG.';
        break;
      case FurnitureWipInputMode.retur:
        code = returCode;
        prefix = 'L.';
        break;
      case FurnitureWipInputMode.spanner:
        code = spannerCode;
        prefix = 'BJ.';
        break;
      case FurnitureWipInputMode.inject:
        code = injectCode;
        prefix = 'S.';
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
    required int? idFurnitureWip,
    required String dateCreateYmd,
    double? pcs,
    double? berat,
    bool? isPartial,
    int? idWarna,
    String? blok,
    String? idLokasi,
    required FurnitureWipInputMode? mode,
    String? hotStampCode,      // BH.******
    String? pasangKunciCode,   // BI.******
    String? bongkarSusunCode,  // BG.******
    String? returCode,         // L.******
    String? spannerCode,       // BJ.******
    String? injectCode,        // S.******
  }) {
    // Tentukan outputCode berdasarkan mode
    String? outputCode;
    switch (mode) {
      case FurnitureWipInputMode.hotStamping:
        outputCode = hotStampCode?.trim();
        break;
      case FurnitureWipInputMode.pasangKunci:
        outputCode = pasangKunciCode?.trim();
        break;
      case FurnitureWipInputMode.bongkarSusun:
        outputCode = bongkarSusunCode?.trim();
        break;
      case FurnitureWipInputMode.retur:
        outputCode = returCode?.trim();
        break;
      case FurnitureWipInputMode.spanner:
        outputCode = spannerCode?.trim();
        break;
      case FurnitureWipInputMode.inject:
        outputCode = injectCode?.trim();
        break;
      default:
        outputCode = null;
    }

    final header = <String, dynamic>{
      // ⬇️ Untuk INJECT multi, IdFurnitureWIP boleh null → field ini tidak dikirim
      if (idFurnitureWip != null) "IdFurnitureWIP": idFurnitureWip,
      "DateCreate": dateCreateYmd,
      if (pcs != null) "Pcs": pcs,
      if (berat != null) "Berat": berat,
      if (isPartial != null) "IsPartial": isPartial ? 1 : 0,
      if (idWarna != null) "IdWarna": idWarna,
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
    required int? idFurnitureWip,
    required DateTime dateCreate,
    double? pcs,
    double? berat,
    bool? isPartial,
    int? idWarna,
    String? blok,
    String? idLokasi,

    /// mode: Hot Stamping / Pasang Kunci / Bongkar / Retur / Spanner / Inject
    required FurnitureWipInputMode? mode,

    String? hotStampCode,      // BH.******
    String? pasangKunciCode,   // BI.******
    String? bongkarSusunCode,  // BG.******
    String? returCode,         // L.******
    String? spannerCode,       // BJ.******
    String? injectCode,        // S.******

    required String Function(DateTime) toDbDateString, // yyyy-MM-dd
  }) async {
    // 1) Validate
    final err = validateCreate(
      idFurnitureWip: idFurnitureWip,
      dateCreate: dateCreate,
      pcs: pcs,
      berat: berat,
      mode: mode,
      hotStampCode: hotStampCode,
      pasangKunciCode: pasangKunciCode,
      bongkarSusunCode: bongkarSusunCode,
      returCode: returCode,
      spannerCode: spannerCode,
      injectCode: injectCode,
    );
    if (err != null) {
      throw Exception(err);
    }

    // 2) Build body
    final body = _buildCreateBody(
      idFurnitureWip: idFurnitureWip, // ⬅️ boleh null untuk Inject multi
      dateCreateYmd: toDbDateString(dateCreate),
      pcs: pcs,
      berat: berat,
      isPartial: isPartial,
      idWarna: idWarna,
      blok: blok,
      idLokasi: idLokasi,
      mode: mode,
      hotStampCode: hotStampCode,
      pasangKunciCode: pasangKunciCode,
      bongkarSusunCode: bongkarSusunCode,
      returCode: returCode,
      spannerCode: spannerCode,
      injectCode: injectCode,
    );

    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.createFurnitureWip(body);

      // Response baru: data.headers (array), bukan lagi data.header tunggal
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final List headers = data['headers'] as List? ?? [];

      if (headers.isNotEmpty) {
        lastCreatedNoFurnitureWip =
            headers.first['NoFurnitureWIP']?.toString();
      } else {
        // fallback lama (kalau backend masih kirim header tunggal)
        lastCreatedNoFurnitureWip =
            res['data']?['header']?['NoFurnitureWIP']?.toString();
      }

      // Refresh list & biarkan PagingController yang load
      await fetchHeaders(search: _search);
      if (lastCreatedNoFurnitureWip != null) {
        setSelected(lastCreatedNoFurnitureWip);
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
  // UPDATE (PUT /labels/furniture-wip/:noFurnitureWip)
  // ==========================

  Map<String, dynamic> _buildUpdateBody({
    DateTime? dateCreate,
    int? idFurnitureWip,
    double? pcs,
    double? berat,
    bool? isPartial,
    int? idWarna,
    String? blok,
    String? idLokasi,

    /// null  -> mapping tidak disentuh
    /// ""    -> mapping dihapus (backend akan deleteAllMappings)
    /// "BH..." / "BI..." / dst -> mapping diganti
    String? outputCode,
    required String Function(DateTime) toDbDateString,
  }) {
    final header = <String, dynamic>{};

    if (dateCreate != null) header['DateCreate'] = toDbDateString(dateCreate);
    if (idFurnitureWip != null) header['IdFurnitureWIP'] = idFurnitureWip;
    if (pcs != null) header['Pcs'] = pcs;
    if (berat != null) header['Berat'] = berat;
    if (isPartial != null) header['IsPartial'] = isPartial ? 1 : 0;
    if (idWarna != null) header['IdWarna'] = idWarna;
    if (blok != null && blok.trim().isNotEmpty) header['Blok'] = blok.trim();
    if (idLokasi != null && idLokasi.trim().isNotEmpty) {
      header['IdLokasi'] = idLokasi.trim();
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
    required String noFurnitureWip,
    DateTime? dateCreate,
    int? idFurnitureWip,
    double? pcs,
    double? berat,
    bool? isPartial,
    int? idWarna,
    String? blok,
    String? idLokasi,
    String? outputCode,
    required String Function(DateTime) toDbDateString,
  }) async {
    final err = validateUpdate(pcs: pcs, berat: berat);
    if (err != null) throw Exception(err);

    final body = _buildUpdateBody(
      dateCreate: dateCreate,
      idFurnitureWip: idFurnitureWip,
      pcs: pcs,
      berat: berat,
      isPartial: isPartial,
      idWarna: idWarna,
      blok: blok,
      idLokasi: idLokasi,
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

      final res =
      await repository.updateFurnitureWip(noFurnitureWip, body);

      // Refresh list and keep this row selected
      await fetchHeaders(search: _search);
      setSelected(noFurnitureWip);

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
  Future<void> deleteFurnitureWip(String noFurnitureWip) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await repository.deleteFurnitureWip(noFurnitureWip);

      items.removeWhere((e) => e.noFurnitureWip == noFurnitureWip);

      if (selectedNoFurnitureWip == noFurnitureWip) {
        selectedNoFurnitureWip = null;
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
  Future<void> loadPartialInfo({String? noFurnitureWip}) async {
    final nf = noFurnitureWip ?? currentNoFurnitureWip;

    if (nf == null || nf.isEmpty) {
      partialError = "NoFurnitureWIP not selected";
      partialInfo = null;
      notifyListeners();
      return;
    }

    try {
      isPartialLoading = true;
      partialError = null;
      notifyListeners();

      debugPrint("➡️ [FurnitureWipVM] loadPartialInfo noFurnitureWIP=$nf");

      partialInfo = await repository.fetchPartialInfo(
        noFurnitureWip: nf,
      );
    } catch (e) {
      partialError = e.toString();
      partialInfo = null;
      debugPrint("❌ Error loadPartialInfo($nf): $partialError");
    } finally {
      isPartialLoading = false;
      notifyListeners();
    }
  }

  // Screen lifecycle helper
  void resetForScreen() {
    selectedNoFurnitureWip = null;
    currentNoFurnitureWip = null;
    partialInfo = null;
    partialError = null;
  }
}
