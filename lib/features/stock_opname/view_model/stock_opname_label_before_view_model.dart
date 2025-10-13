import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/stock_opname_label_before_model.dart';
import '../../../core/network/endpoints.dart';
import 'socket_manager.dart'; // Import SocketManager

class StockOpnameLabelBeforeViewModel extends ChangeNotifier {
  String noSO = '';
  String? currentFilter;
  String? currentIdLokasi;
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

  // ✅ Use SocketManager instead of direct socket
  final SocketManager _socketManager = SocketManager();
  late Function(Map<String, dynamic>) _socketCallback;

  List<StockOpnameLabelBeforeModel> get labels => items;

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


  StockOpnameLabelBeforeViewModel() {
    // Initialize socket callback
    _socketCallback = _handleSocketData;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void initSocket() {
    // Initialize socket manager
    _socketManager.initSocket();

    // Register our callback
    _socketManager.registerLabelInsertedCallback(_socketCallback);
  }

  void _handleSocketData(Map<String, dynamic> labelData) {
    print('📦 Processing socket data in StockOpnameLabelBeforeViewModel: $labelData');
    print('🔍 Current NoSO (Before): $noSO');
    print('🔍 Current Location Filter (Before): $currentIdLokasi');

    // Debug available keys
    print('🔑 Available keys (Before): ${labelData.keys.toList()}');

    // 🔐 Jika sedang search, abaikan update socket
    if (searchKeyword != null && searchKeyword!.isNotEmpty) {
      print('⏸️ Ignored socket update because search is active: "$searchKeyword"');
      return;
    }

    // Check filter conditions
    final receivedNoSO = labelData['noso'];
    final receivedLocation = labelData['idlokasi'];
    final receivedLabelNumber = labelData['nomorLabel'];
    final receivedLabelTypeCode = labelData['labelTypeCode'];

    print('📋 Received NoSO (Before): $receivedNoSO (match: ${receivedNoSO == noSO})');
    print('📍 Received Location (Before): $receivedLocation (current filter: $currentIdLokasi)');
    print('🏷️ Received Label Number (Before): $receivedLabelNumber');

    if (receivedNoSO == noSO) {
      if (currentFilter == null || receivedLabelTypeCode == currentFilter || currentFilter == 'all' && currentIdLokasi == null || receivedLocation == currentIdLokasi || currentIdLokasi == 'all') {
        try {
          // Find and remove the label from items list
          final indexToRemove = items.indexWhere((item) =>
          item.nomorLabel == receivedLabelNumber);

          if (indexToRemove != -1) {
            final removedItem = items.removeAt(indexToRemove);
            print('✅ Label removed from before list: ${removedItem.nomorLabel}');
          } else {
            print('🚫 Label not found in before list: $receivedLabelNumber');
          }

          // Turunkan totalData dalam semua kasus socket valid
          totalData = totalData > 0 ? totalData - 1 : 0;
          notifyListeners();

        } catch (e, stackTrace) {
          print('❌ Error processing label removal (Before): $e');
          print('📋 Stack trace (Before): $stackTrace');
          print('📋 Raw data (Before): $labelData');
        }
      } else {
        print('🚫 Label filtered by location (Before)');
      }
    } else {
      print('🚫 Label filtered by NoSO (Before)');
    }
  }

  Future<void> fetchInitialData(
      String selectedNoSO, {
        String filterBy = 'all',
        String? idLokasi,
        String? search,
      }) async {
    noSO = selectedNoSO;
    currentFilter = filterBy;
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

  Future<void> loadMoreData() async {
    if (isLoadingMore || !hasMoreData) return;
    page++;
    isLoadingMore = true;
    notifyListeners();

    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final token = await _getToken();

      final url = Uri.parse(
        ApiConstants.stockOpnameAcuanList(
          noSO: noSO,
          page: page,
          pageSize: pageSize,
          filterBy: currentFilter,
          idLokasi: currentIdLokasi,
          search: searchKeyword, // 👈 Tambahkan ini
        ),
      );

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
        final int total = data['totalData'] ?? 0;
        final int sumSak = data['totalSak'] ?? 0;
        final double sumBerat = (data['totalBerat'] as num?)?.toDouble() ?? 0.0;
        final int sumTotalGlobal = data['totalLabelGlobal'] ?? 0;
        final int sumSakGlobal = data['totalSakGlobal'] ?? 0;
        final double sumBeratGlobal = (data['totalBeratGlobal'] as num?)?.toDouble() ?? 0.0;

        final fetched = labelData.map((e) => StockOpnameLabelBeforeModel.fromJson(e)).toList();

        if (page == 1) {
          items = fetched; // Replace data if first page
        } else {
          items.addAll(fetched); // Add data if next page
        }

        totalData = total;
        totalSak = sumSak;
        totalBerat = sumBerat;

        totalGlobal = sumTotalGlobal;
        totalSakGlobal = sumSakGlobal;
        totalBeratGlobal = sumBeratGlobal;

        hasMoreData = items.length < total;
        hasError = false;
        errorMessage = '';
      } else {
        hasError = true;
        errorMessage = 'Gagal mengambil data acuan (status: ${response.statusCode})';
        print('❌ ERROR: $errorMessage');
        print('❌ Response: ${response.body}');
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

  void reset() {
    items.clear();
    page = 1;
    totalData = 0;
    hasMoreData = true;
    errorMessage = '';
    currentIdLokasi = null;
    currentFilter = null;
    noSO = '';
    _socketManager.clearProcessedLabels();
    notifyListeners();
  }

  // Helper methods for compatibility
  void nextPage() {
    if (hasMoreData) {
      loadMoreData();
    }
  }

  bool get isLoading => isInitialLoading || isLoadingMore;
  int get currentPage => page;
  int get totalPages => (totalData / pageSize).ceil();

  @override
  void dispose() {
    // Unregister callback when disposing
    _socketManager.unregisterLabelInsertedCallback(_socketCallback);
    super.dispose();
  }
}