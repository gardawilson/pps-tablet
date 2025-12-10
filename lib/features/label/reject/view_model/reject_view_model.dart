import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/reject_header_model.dart';
import '../model/reject_partial_model.dart';
import '../repository/reject_repository.dart';

/// Dari proses mana Reject ini berasal (label sumber)
/// - inject       -> S.******
/// - hotStamping  -> BH.******
/// - pasangKunci  -> BI.******
/// - spanner      -> BJ.******
/// - bjSortir     -> J.******
enum RejectInputMode {
  inject,
  hotStamping,
  pasangKunci,
  spanner,
  bjSortir,
}

class RejectViewModel extends ChangeNotifier {
  final RejectRepository repository;

  RejectViewModel({required this.repository}) {
    // === PagingController v5 ===
    pagingController = PagingController<int, RejectHeader>(
      // pageKey kita treat sebagai "page index" (0,1,2,...)
      fetchPage: _fetchPage,
      // Ditanya: "next page key berapa?" setelah setiap page berhasil di-load
      getNextPageKey: _getNextPageKey,
    );
  }

  static const int _pageSize = 20;

  /// Controller untuk HorizontalPagedTable
  late final PagingController<int, RejectHeader> pagingController;

  // === LIST STATE (untuk AppBar, dsb) ===
  List<RejectHeader> items = [];
  bool isLoading = false;
  String errorMessage = '';

  int _total = 0;
  int get totalCount => _total;

  String _search = '';
  String get currentSearch => _search;

  // pakai info dari PagingState
  bool get hasMore => pagingController.value.hasNextPage;

  // === PARTIAL INFO STATE ===
  RejectPartialInfo? partialInfo;
  String? partialError;
  bool isPartialLoading = false;

  /// Optional: simpan NoReject terpilih (misal untuk popover)
  String? currentNoReject;

  // Highlight row
  String? selectedNoReject;
  RejectHeader? get selectedItem {
    final i = items.indexWhere((e) => e.noReject == selectedNoReject);
    return i == -1 ? null : items[i];
  }

  void setSelected(String? no) {
    if (selectedNoReject == no) return;
    selectedNoReject = no;
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
    selectedNoReject = null;

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

  Future<List<RejectHeader>> _fetchPage(int pageKey) async {
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

      final list = (result['items'] as List<RejectHeader>);
      _total = (result['total'] as int?) ?? list.length;

      errorMessage = '';

      // update cache items lokal (flatten)
      if (pageKey == 0) {
        items = List<RejectHeader>.from(list);
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
      PagingState<int, RejectHeader> state,
      ) {
    if (state.lastPageIsEmpty) return null;
    return state.nextIntPageKey;
  }

  // ==========================
  // CREATE (POST /labels/reject)
  // ==========================

  String? lastCreatedNoReject;

  /// Validasi input create Reject
  String? validateCreate({
    required int? idReject,
    required DateTime dateCreate,
    double? berat,
    required RejectInputMode? mode,
    String? injectCode,      // S.******
    String? hotStampCode,    // BH.******
    String? pasangKunciCode, // BI.******
    String? spannerCode,     // BJ.******
    String? bjSortirCode,    // J.******
  }) {
    if (mode == null) {
      return 'Pilih proses sumber (Inject / Hot Stamping / Pasang Kunci / Spanner / BJ Sortir).';
    }

    if (idReject == null) {
      return 'Pilih jenis Reject terlebih dahulu.';
    }

    if (berat != null && berat <= 0) {
      return 'Berat harus > 0.';
    }

    String? code;
    String prefix;

    switch (mode) {
      case RejectInputMode.inject:
        code = injectCode;
        prefix = 'S.';
        break;
      case RejectInputMode.hotStamping:
        code = hotStampCode;
        prefix = 'BH.';
        break;
      case RejectInputMode.pasangKunci:
        code = pasangKunciCode;
        prefix = 'BI.';
        break;
      case RejectInputMode.spanner:
        code = spannerCode;
        prefix = 'BJ.';
        break;
      case RejectInputMode.bjSortir:
        code = bjSortirCode;
        prefix = 'J.';
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
    required int? idReject,
    required String dateCreateYmd,
    String? jam,
    double? berat,
    bool? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    required RejectInputMode? mode,
    String? injectCode,      // S.******
    String? hotStampCode,    // BH.******
    String? pasangKunciCode, // BI.******
    String? spannerCode,     // BJ.******
    String? bjSortirCode,    // J.******
  }) {
    String? outputCode;
    switch (mode) {
      case RejectInputMode.inject:
        outputCode = injectCode?.trim();
        break;
      case RejectInputMode.hotStamping:
        outputCode = hotStampCode?.trim();
        break;
      case RejectInputMode.pasangKunci:
        outputCode = pasangKunciCode?.trim();
        break;
      case RejectInputMode.spanner:
        outputCode = spannerCode?.trim();
        break;
      case RejectInputMode.bjSortir:
        outputCode = bjSortirCode?.trim();
        break;
      default:
        outputCode = null;
    }

    final header = <String, dynamic>{
      if (idReject != null) "IdReject": idReject,
      "DateCreate": dateCreateYmd,
      if (jam != null && jam.isNotEmpty) "Jam": jam,
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
    required int? idReject,
    required DateTime dateCreate,
    double? berat,
    bool? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    String? jam,

    /// mode: Inject / HotStamping / PasangKunci / Spanner / BJ Sortir
    required RejectInputMode? mode,

    String? injectCode,      // S.******
    String? hotStampCode,    // BH.******
    String? pasangKunciCode, // BI.******
    String? spannerCode,     // BJ.******
    String? bjSortirCode,    // J.******

    required String Function(DateTime) toDbDateString, // yyyy-MM-dd
  }) async {
    // 1) Validate
    final err = validateCreate(
      idReject: idReject,
      dateCreate: dateCreate,
      berat: berat,
      mode: mode,
      injectCode: injectCode,
      hotStampCode: hotStampCode,
      pasangKunciCode: pasangKunciCode,
      spannerCode: spannerCode,
      bjSortirCode: bjSortirCode,
    );
    if (err != null) {
      throw Exception(err);
    }

    // 2) Build body
    final body = _buildCreateBody(
      idReject: idReject,
      dateCreateYmd: toDbDateString(dateCreate),
      jam: jam,
      berat: berat,
      isPartial: isPartial,
      idWarehouse: idWarehouse,
      blok: blok,
      idLokasi: idLokasi,
      mode: mode,
      injectCode: injectCode,
      hotStampCode: hotStampCode,
      pasangKunciCode: pasangKunciCode,
      spannerCode: spannerCode,
      bjSortirCode: bjSortirCode,
    );

    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.createReject(body);

      final data = res['data'] as Map<String, dynamic>? ?? {};
      final List headers = data['headers'] as List? ?? [];

      if (headers.isNotEmpty) {
        lastCreatedNoReject = headers.first['NoReject']?.toString();
      } else {
        lastCreatedNoReject = res['data']?['header']?['NoReject']?.toString();
      }

      await fetchHeaders(search: _search);
      if (lastCreatedNoReject != null) {
        setSelected(lastCreatedNoReject);
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
  // UPDATE (PUT /labels/reject/:noReject)
  // ==========================

  Map<String, dynamic> _buildUpdateBody({
    DateTime? dateCreate,
    int? idReject,
    double? berat,
    bool? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    String? jam,

    /// null  -> mapping tidak disentuh
    /// non-empty string -> mapping diganti (S./BH./BI./BJ./J.)
    /// (empty string tidak boleh, backend akan error)
    String? outputCode,
    required String Function(DateTime) toDbDateString,
  }) {
    final header = <String, dynamic>{};

    if (dateCreate != null) header['DateCreate'] = toDbDateString(dateCreate);
    if (idReject != null) header['IdReject'] = idReject;
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
      body['outputCode'] = outputCode; // pastikan di UI tidak kirim ""
    }

    return body;
  }

  String? validateUpdate({
    double? berat,
    String? outputCode,
  }) {
    if (berat != null && berat <= 0) return 'Berat harus > 0.';
    if (outputCode != null && outputCode.trim().isEmpty) {
      return 'outputCode tidak boleh kosong string.';
    }
    return null;
  }

  Future<Map<String, dynamic>> updateFromForm({
    required String noReject,
    DateTime? dateCreate,
    int? idReject,
    double? berat,
    bool? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    String? jam,
    String? outputCode,
    required String Function(DateTime) toDbDateString,
  }) async {
    final err = validateUpdate(
      berat: berat,
      outputCode: outputCode,
    );
    if (err != null) throw Exception(err);

    final body = _buildUpdateBody(
      dateCreate: dateCreate,
      idReject: idReject,
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

      final res = await repository.updateReject(noReject, body);

      await fetchHeaders(search: _search);
      setSelected(noReject);

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
  Future<void> deleteReject(String noReject) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await repository.deleteReject(noReject);

      items.removeWhere((e) => e.noReject == noReject);

      if (selectedNoReject == noReject) {
        selectedNoReject = null;
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
  Future<void> loadPartialInfo({String? noReject}) async {
    final nr = noReject ?? currentNoReject;

    if (nr == null || nr.isEmpty) {
      partialError = "NoReject not selected";
      partialInfo = null;
      notifyListeners();
      return;
    }

    try {
      isPartialLoading = true;
      partialError = null;
      notifyListeners();

      debugPrint("➡️ [RejectVM] loadPartialInfo NoReject=$nr");

      partialInfo = await repository.fetchPartialInfo(
        noReject: nr,
      );
    } catch (e) {
      partialError = e.toString();
      partialInfo = null;
      debugPrint("❌ Error loadPartialInfo($nr): $partialError");
    } finally {
      isPartialLoading = false;
      notifyListeners();
    }
  }

  void resetForScreen() {
    selectedNoReject = null;
    currentNoReject = null;
    partialInfo = null;
    partialError = null;
  }
}
