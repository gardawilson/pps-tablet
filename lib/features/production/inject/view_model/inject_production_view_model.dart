import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/furniture_wip_by_inject_production_model.dart';
import '../model/packing_by_inject_production_model.dart';
import '../model/inject_production_model.dart';
import '../repository/inject_production_repository.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

class InjectProductionViewModel extends ChangeNotifier {
  final InjectProductionRepository repository;

  InjectProductionViewModel({required this.repository}) {
    debugPrint(
      '🟢 [INJECT_VM] ctor called, repo=$repository, VM hash=$hashCode',
    );
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (opsional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  // ===== BY DATE LIST STATE (existing behavior) =====
  List<InjectProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ===== CREATE / UPDATE / DELETE STATE =====
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE)
  // =========================
  late final PagingController<int, InjectProduction> _pagingController;
  PagingController<int, InjectProduction> get pagingController =>
      _pagingController;

  void _initializePagingController() {
    debugPrint(
      '🟢 [INJECT_VM] _initializePagingController() VM hash=$hashCode',
    );

    _pagingController = PagingController<int, InjectProduction>(
      getNextPageKey: (state) {
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) => _fetchPaged(pageKey),
    );

    debugPrint(
      '🟢 [INJECT_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // Filters
  int pageSize = 20;
  String _search = '';
  String get search => _search;

  // Optional debounce helper (same as HotStamp)
  Timer? _searchDebounce;

  // ---------------------------------------------------------------------------
  // FurnitureWIP by InjectProduksi (NoProduksi) (existing)
  // ---------------------------------------------------------------------------
  FurnitureWipByInjectResult? furnitureWipResult;
  bool isLoadingFurnitureWip = false;
  String furnitureWipError = '';

  double? get furnitureWipBeratProdukHasilTimbang =>
      furnitureWipResult?.beratProdukHasilTimbang;

  List<FurnitureWipByInjectItem> get furnitureWipItems =>
      furnitureWipResult?.items ?? const [];

  // ---------------------------------------------------------------------------
  // Packing (BarangJadi) by InjectProduksi (NoProduksi) (existing)
  // ---------------------------------------------------------------------------
  PackingByInjectResult? packingResult;
  bool isLoadingPacking = false;
  String packingError = '';

  double? get packingBeratProdukHasilTimbang =>
      packingResult?.beratProdukHasilTimbang;

  List<PackingByInjectItem> get packingItems =>
      packingResult?.items ?? const [];

  // ===========================================================================
  // BY DATE (existing) + switch mode
  // ===========================================================================
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [INJECT_VM] fetchByDate($date) VM hash=$hashCode');

    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchByDate(date);
      debugPrint(
        '📅 [INJECT_VM] fetchByDate success items=${items.length} VM hash=$hashCode',
      );
    } catch (e, st) {
      debugPrint('❌ [INJECT_VM] fetchByDate error: $e');
      debugPrint('❌ [INJECT_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint(
      '🔁 [INJECT_VM] exitByDateModeAndRefreshPaged VM hash=$hashCode',
    );
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ===========================================================================
  // PAGED FETCH (table)
  // ===========================================================================
  Future<List<InjectProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
      '📡 [INJECT_VM] _fetchPaged(pageKey=$pageKey) isByDateMode=$_isByDateMode VM hash=$hashCode',
    );

    if (_isByDateMode) {
      return const <InjectProduction>[];
    }

    final s = _search.trim();

    try {
      final list = await repository.fetchPaged(
        page: pageKey,
        pageSize: pageSize,
        search: s,
      );
      debugPrint(
        '📡 [INJECT_VM] _fetchPaged got=${list.length} VM hash=$hashCode',
      );
      return list;
    } catch (e, st) {
      debugPrint('❌ [INJECT_VM] _fetchPaged error: $e');
      debugPrint('❌ [INJECT_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // Filters
  void applyFilters({String? search, int? newPageSize}) {
    debugPrint(
      '🔍 [INJECT_VM] applyFilters(search=$search, newPageSize=$newPageSize) VM hash=$hashCode',
    );

    _isByDateMode = false;

    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;
    if (search != null) _search = search;

    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [INJECT_VM] clearFilters VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [INJECT_VM] refreshPaged VM hash=$hashCode');
    _isByDateMode = false;
    _pagingController.refresh();
  }

  void setSearchDebounced(
    String text, {
    Duration delay = const Duration(milliseconds: 350),
  }) {
    debugPrint(
      '⌛ [INJECT_VM] setSearchDebounced("$text") delay=${delay.inMilliseconds}ms VM hash=$hashCode',
    );
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      applyFilters(search: text);
    });
  }

  // ===========================================================================
  // CREATE / UPDATE / DELETE
  // ===========================================================================
  Future<InjectProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    /// Gunakan idOperators (list) — idOperator (single) dipertahankan untuk
    /// backward compat dari layar lama.
    List<int>? idOperators,
    int? idOperator,
    int? idRegu,
    required int shift,

    dynamic jam,

    int? jmlhAnggota,
    int? hadir,
    int? idCetakan,
    int? idWarna,
    bool? enableOffset,
    int? offsetCurrent,
    int? offsetNext,
    int? idFurnitureMaterial,
    double? hourMeter,
    double? beratProdukHasilTimbang,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
  }) async {
    final opsList = idOperators ?? (idOperator != null ? [idOperator] : <int>[]);
    final jmlh = jmlhAnggota ?? opsList.length;
    final hdrs = hadir ?? opsList.length;

    debugPrint(
      '🆕 [INJECT_VM] createProduksi(tgl=$tglProduksi, idMesin=$idMesin, operators=$opsList, shift=$shift, jam=$jam) VM hash=$hashCode',
    );

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'tglProduksi': toDbDateString(tglProduksi),
        'idMesin': idMesin,
        'idOperators': opsList,
        if (idRegu != null) 'idRegu': idRegu,
        'shift': shift,

        if (jam != null) 'jam': jam,

        'jmlhAnggota': jmlh,
        'hadir': hdrs,
        if (idCetakan != null) 'idCetakan': idCetakan,
        if (idWarna != null) 'idWarna': idWarna,
        if (enableOffset != null) 'enableOffset': enableOffset ? 1 : 0,
        if (offsetCurrent != null) 'offsetCurrent': offsetCurrent,
        if (offsetNext != null) 'offsetNext': offsetNext,
        if (idFurnitureMaterial != null)
          'idFurnitureMaterial': idFurnitureMaterial,
        if (hourMeter != null) 'hourMeter': hourMeter,
        if (beratProdukHasilTimbang != null)
          'beratProdukHasilTimbang': beratProdukHasilTimbang,

        if (hourStart != null) 'hourStart': hourStart,
        if (hourEnd != null) 'hourEnd': hourEnd,

        if (checkBy1 != null) 'checkBy1': checkBy1,
        if (checkBy2 != null) 'checkBy2': checkBy2,
        if (approveBy != null) 'approveBy': approveBy,
      };

      final body = await repository.createProduksi(payload);

      // backend kamu: { success, message, data: {...header...} }
      final data = (body['data'] is Map)
          ? Map<String, dynamic>.from(body['data'])
          : null;
      final created = data == null ? null : InjectProduction.fromJson(data);

      // auto refresh list
      if (_isByDateMode) {
        await fetchByDate(tglProduksi);
      } else {
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [INJECT_VM] createProduksi error: $e');
      debugPrint('❌ [INJECT_VM] createProduksi stack: $st');
      saveError = _normalizeErrorMessage(e);
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<InjectProduction?> updateProduksi({
    required String noProduksi,

    DateTime? tglProduksi,
    int? idMesin,
    List<int>? idOperators,
    int? idOperator,
    int? idRegu,
    int? shift,
    dynamic jam,

    int? jmlhAnggota,
    int? hadir,
    int? idCetakan,
    int? idWarna,
    bool? enableOffset,
    int? offsetCurrent,
    int? offsetNext,
    int? idFurnitureMaterial,
    double? hourMeter,
    double? beratProdukHasilTimbang,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
  }) async {
    final opsList = idOperators ?? (idOperator != null ? [idOperator] : null);

    debugPrint(
      '✏️ [INJECT_VM] updateProduksi(no=$noProduksi, tgl=$tglProduksi, operators=$opsList, jam=$jam) VM hash=$hashCode',
    );

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        if (tglProduksi != null) 'tglProduksi': toDbDateString(tglProduksi),
        if (idMesin != null) 'idMesin': idMesin,
        if (opsList != null) 'idOperators': opsList,
        if (idRegu != null) 'idRegu': idRegu,
        if (shift != null) 'shift': shift,

        if (jam != null) 'jam': jam,

        if (jmlhAnggota != null || opsList != null)
          'jmlhAnggota': jmlhAnggota ?? opsList!.length,
        if (hadir != null || opsList != null) 'hadir': hadir ?? opsList!.length,
        if (idCetakan != null) 'idCetakan': idCetakan,
        if (idWarna != null) 'idWarna': idWarna,
        if (enableOffset != null) 'enableOffset': enableOffset ? 1 : 0,
        if (offsetCurrent != null) 'offsetCurrent': offsetCurrent,
        if (offsetNext != null) 'offsetNext': offsetNext,
        if (idFurnitureMaterial != null)
          'idFurnitureMaterial': idFurnitureMaterial,
        if (hourMeter != null) 'hourMeter': hourMeter,
        if (beratProdukHasilTimbang != null)
          'beratProdukHasilTimbang': beratProdukHasilTimbang,
        if (hourStart != null) 'hourStart': hourStart,
        if (hourEnd != null) 'hourEnd': hourEnd,

        if (checkBy1 != null) 'checkBy1': checkBy1,
        if (checkBy2 != null) 'checkBy2': checkBy2,
        if (approveBy != null) 'approveBy': approveBy,
      };

      final body = await repository.updateProduksi(noProduksi, payload);

      final data = (body['data'] is Map)
          ? Map<String, dynamic>.from(body['data'])
          : null;
      final updated = data == null ? null : InjectProduction.fromJson(data);

      // auto refresh
      if (_isByDateMode) {
        if (tglProduksi != null) {
          await fetchByDate(tglProduksi);
        } else {
          // kalau update tidak ubah tanggal, tetap refresh paged agar aman
          refreshPaged();
        }
      } else {
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [INJECT_VM] updateProduksi error: $e');
      debugPrint('❌ [INJECT_VM] updateProduksi stack: $st');
      saveError = _normalizeErrorMessage(e);
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noProduksi) async {
    debugPrint(
      '🗑 [INJECT_VM] deleteProduksi(no=$noProduksi) VM hash=$hashCode',
    );

    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noProduksi);

      // auto refresh
      if (_isByDateMode) {
        refreshPaged();
      } else {
        refreshPaged();
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ [INJECT_VM] deleteProduksi error: $e');
      debugPrint('❌ [INJECT_VM] deleteProduksi stack: $st');
      saveError = _normalizeErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  String _normalizeErrorMessage(Object e) {
    String msg = e.toString().replaceFirst('Exception: ', '').trim();

    // Kalau error berupa JSON string
    if (msg.startsWith('{') && msg.endsWith('}')) {
      try {
        final decoded = jsonDecode(msg);
        if (decoded is Map && decoded['message'] != null) {
          return decoded['message'].toString();
        }
      } catch (_) {}
    }
    return msg;
  }

  // ===========================================================================
  // Existing: FurnitureWIP
  // ===========================================================================
  Future<void> fetchFurnitureWipByInjectProduction(String noProduksi) async {
    isLoadingFurnitureWip = true;
    furnitureWipError = '';
    furnitureWipResult = null;
    notifyListeners();

    try {
      furnitureWipResult = await repository.fetchFurnitureWipByInjectProduction(
        noProduksi,
      );
    } catch (e) {
      furnitureWipError = e.toString();
      furnitureWipResult = null;
    } finally {
      isLoadingFurnitureWip = false;
      notifyListeners();
    }
  }

  void clearFurnitureWip() {
    furnitureWipResult = null;
    furnitureWipError = '';
    isLoadingFurnitureWip = false;
    notifyListeners();
  }

  // ===========================================================================
  // Existing: Packing
  // ===========================================================================
  Future<void> fetchPackingByInjectProduction(String noProduksi) async {
    isLoadingPacking = true;
    packingError = '';
    packingResult = null;
    notifyListeners();

    try {
      packingResult = await repository.fetchPackingByInjectProduction(
        noProduksi,
      );
    } catch (e) {
      packingError = e.toString();
      packingResult = null;
    } finally {
      isLoadingPacking = false;
      notifyListeners();
    }
  }

  void clearPacking() {
    packingResult = null;
    packingError = '';
    isLoadingPacking = false;
    notifyListeners();
  }

  // ===========================================================================
  // Reset (existing)
  // ===========================================================================
  void clear() {
    // Inject list
    items = [];
    error = '';
    isLoading = false;

    // Saving
    isSaving = false;
    saveError = null;

    // Furniture WIP
    furnitureWipResult = null;
    furnitureWipError = '';
    isLoadingFurnitureWip = false;

    // Packing
    packingResult = null;
    packingError = '';
    isLoadingPacking = false;

    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🔴 [INJECT_VM] dispose() VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
