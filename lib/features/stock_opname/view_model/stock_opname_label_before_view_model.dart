import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/stock_opname_label_before_model.dart';
import '../../../core/network/endpoints.dart';
import 'socket_manager.dart';

class StockOpnameLabelBeforeViewModel extends ChangeNotifier {
  String noSO = '';
  String? currentFilter;
  String? currentBlok;
  int? currentIdLokasi;
  String? searchKeyword;

  List<StockOpnameLabelBeforeModel> items = [];

  int page = 1;
  int pageSize = 50;
  int totalData = 0;
  int totalSak = 0;
  double totalBerat = 0;
  int totalSakGlobal = 0;
  int totalGlobal = 0;
  double totalBeratGlobal = 0;
  bool hasMoreData = true;

  bool isInitialLoading = false;
  bool isLoadingMore = false;
  bool hasError = false;
  String errorMessage = '';

  final SocketManager _socketManager = SocketManager();
  late Function(Map<String, dynamic>) _socketCallback;

  List<StockOpnameLabelBeforeModel> get labels => items;

  StockOpnameLabelBeforeViewModel() {
    _socketCallback = _handleSocketData;
  }

  // === 🔍 SEARCH ===
  Future<void> search(String keyword) async {
    searchKeyword = keyword;
    page = 1;
    hasMoreData = true;
    items.clear();
    isInitialLoading = true;
    notifyListeners();
    await _fetchData();
  }

  void clearSearch() {
    searchKeyword = null;
    page = 1;
    hasMoreData = true;
    items.clear();
    isInitialLoading = true;
    notifyListeners();
    _fetchData();
  }

  // === 🔐 TOKEN ===
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // === 🔌 SOCKET ===
  void initSocket() {
    _socketManager.initSocket();
    _socketManager.registerLabelInsertedCallback(_socketCallback);
  }

  void _handleSocketData(Map<String, dynamic> labelData) {
    print('📦 Socket data (Before): $labelData');
    print('🔍 Current NoSO: $noSO, current filter: $currentFilter, lokasi: $currentIdLokasi');

    if (searchKeyword != null && searchKeyword!.isNotEmpty) {
      print('⏸️ Ignored socket update (search mode)');
      return;
    }

    final receivedNoSO = labelData['noso'];
    final receivedLocation = labelData['idlokasi'];
    final receivedLabelNumber = labelData['nomorLabel'];
    final receivedLabelTypeCode = labelData['labelTypeCode'];

    if (receivedNoSO == noSO) {
      final bool matchFilter = currentFilter == null ||
          currentFilter == 'all' ||
          currentFilter == receivedLabelTypeCode;
      final bool matchLokasi = currentIdLokasi == null ||
          currentIdLokasi == 0 ||
          receivedLocation == currentIdLokasi;

      if (matchFilter && matchLokasi) {
        try {
          final indexToRemove = items.indexWhere(
                  (item) => item.nomorLabel == receivedLabelNumber);
          if (indexToRemove != -1) {
            final removedItem = items.removeAt(indexToRemove);
            print('✅ Label removed (Before): ${removedItem.nomorLabel}');
            totalData = (totalData > 0) ? totalData - 1 : 0;
            notifyListeners();
          } else {
            print('🚫 Label not found (Before): $receivedLabelNumber');
          }
        } catch (e, s) {
          print('❌ Error in socket handler (Before): $e\n$s');
        }
      } else {
        print('🚫 Filtered by lokasi / kategori (Before)');
      }
    } else {
      print('🚫 Filtered by NoSO (Before)');
    }
  }

  // === 📡 FETCH INITIAL ===
  Future<void> fetchInitialData(
      String selectedNoSO, {
        String filterBy = 'all',
        String? blok,
        int? idLokasi,
        String? search,
      }) async {
    noSO = selectedNoSO;
    currentFilter = filterBy;
    currentBlok = blok;
    currentIdLokasi = idLokasi;
    searchKeyword = search;
    page = 1;
    hasMoreData = true;
    items.clear();

    _socketManager.clearProcessedLabels();

    isInitialLoading = true;
    notifyListeners();
    await _fetchData();
  }

  // === 🔄 LOAD MORE ===
  Future<void> loadMoreData() async {
    if (isLoadingMore || !hasMoreData) return;
    page++;
    isLoadingMore = true;
    notifyListeners();
    await _fetchData();
  }

  // === 🚀 FETCH DATA ===
  Future<void> _fetchData() async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          ApiConstants.stockOpnameAcuanList(
            noSO: noSO,
            page: page,
            pageSize: pageSize,
            filterBy: currentFilter,
            blok: currentBlok,          // ✅ now using blok
            idLokasi: currentIdLokasi,  // ✅ now using int
            search: searchKeyword,
          )
      );

      print('🌐 Fetching: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> labelData = data['data'] ?? [];
        final fetched = labelData
            .map((e) => StockOpnameLabelBeforeModel.fromJson(e))
            .toList();

        if (page == 1) {
          items = fetched;
        } else {
          items.addAll(fetched);
        }

        totalData = data['totalData'] ?? 0;
        totalSak = data['totalSak'] ?? 0;
        totalBerat = (data['totalBerat'] as num?)?.toDouble() ?? 0.0;
        totalGlobal = data['totalLabelGlobal'] ?? 0;
        totalSakGlobal = data['totalSakGlobal'] ?? 0;
        totalBeratGlobal =
            (data['totalBeratGlobal'] as num?)?.toDouble() ?? 0.0;

        hasMoreData = items.length < totalData;
        hasError = false;
        errorMessage = '';
      } else {
        hasError = true;
        errorMessage =
        'Gagal mengambil data acuan (status: ${response.statusCode})';
        print('❌ $errorMessage');
      }
    } catch (e) {
      hasError = true;
      errorMessage = 'Kesalahan jaringan: $e';
      print('❌ EXCEPTION: $errorMessage');
    } finally {
      isInitialLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // === ♻️ RESET ===
  void reset() {
    items.clear();
    page = 1;
    totalData = 0;
    hasMoreData = true;
    errorMessage = '';
    currentIdLokasi = null;
    currentBlok = null;
    currentFilter = null;
    noSO = '';
    _socketManager.clearProcessedLabels();
    notifyListeners();
  }

  // === 🔧 HELPERS ===
  void nextPage() {
    if (hasMoreData) loadMoreData();
  }

  bool get isLoading => isInitialLoading || isLoadingMore;
  int get currentPage => page;
  int get totalPages => (totalData / pageSize).ceil();

  @override
  void dispose() {
    _socketManager.unregisterLabelInsertedCallback(_socketCallback);
    super.dispose();
  }
}
