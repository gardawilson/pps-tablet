// lib/features/broker/view_model/broker_production_view_model.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pps_tablet/features/production/broker/repository/broker_production_input_screen.dart';

import '../model/broker_production_model.dart';
import '../model/broker_inputs_model.dart';

class BrokerProductionInputViewModel extends ChangeNotifier {
  final BrokerProductionInputRepository repository;

  BrokerProductionInputViewModel({required this.repository}) {

  }

  // =========================
  // MODE BY DATE (TETAP)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<BrokerProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE STATE ======
  bool isSaving = false;
  String? saveError;

  // To prevent duplicate per-row inputs fetch
  final Map<String, Future<BrokerInputs>> _inflight = {};

  // =========================
  // MODE PAGED
  // =========================
  late final PagingController<int, BrokerProduction> pagingController;

  // Filters
  int pageSize = 20;

  /// Generic contains-search (backend searches **NoProduksi LIKE**)
  String _search = '';

  /// “Exact” NoProduksi (convenience). Backend still does LIKE; we keep this
  /// so UI can choose an exact flow (e.g., from a suggestion list).
  String? _noProduksi;
  bool _exactNoProduksi = false;

  int? _shift;
  DateTime? _date; // legacy single-day filter (mapped to dateFrom/dateTo in repo)

  String get search => _search;
  String? get noProduksi => _noProduksi;
  bool get exactNoProduksi => _exactNoProduksi;
  int? get shift => _shift;
  DateTime? get date => _date;

  // ======================================================
  // INPUTS PER-ROW (cache, loading & error per NoProduksi)
  // ======================================================
  final Map<String, BrokerInputs> _inputsCache = {};
  final Map<String, bool> _inputsLoading = {};
  final Map<String, String?> _inputsError = {};

  bool isInputsLoading(String noProduksi) => _inputsLoading[noProduksi] == true;
  String? inputsError(String noProduksi) => _inputsError[noProduksi];
  BrokerInputs? inputsOf(String noProduksi) => _inputsCache[noProduksi];
  int inputsCount(String noProduksi, String key) =>
      _inputsCache[noProduksi]?.summary[key] ?? 0;

  Future<BrokerInputs?> loadInputs(String noProduksi, {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noProduksi)) {
      return _inputsCache[noProduksi];
    }
    if (!force && _inflight.containsKey(noProduksi)) {
      try {
        return await _inflight[noProduksi];
      } catch (_) {
        // fall through
      }
    }

    _inputsLoading[noProduksi] = true;
    _inputsError[noProduksi] = null;
    notifyListeners();

    final future = repository.fetchInputs(noProduksi, force: force);
    _inflight[noProduksi] = future;

    try {
      final result = await future;
      _inputsCache[noProduksi] = result;
      return result;
    } catch (e) {
      _inputsError[noProduksi] = e.toString();
      return null;
    } finally {
      _inflight.remove(noProduksi);
      _inputsLoading[noProduksi] = false;
      notifyListeners();
    }
  }

  void clearInputsCache([String? noProduksi]) {
    if (noProduksi == null) {
      _inputsCache.clear();
      _inputsLoading.clear();
      _inputsError.clear();
    } else {
      _inputsCache.remove(noProduksi);
      _inputsLoading.remove(noProduksi);
      _inputsError.remove(noProduksi);
    }
    notifyListeners();
  }



  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }
}
