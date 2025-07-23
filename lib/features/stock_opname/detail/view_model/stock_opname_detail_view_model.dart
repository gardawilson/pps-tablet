import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../constants/api_constants.dart';
import '../model/stock_opname_label_model.dart';
import 'socket_manager.dart'; // Import SocketManager

class StockOpnameDetailViewModel extends ChangeNotifier {
  String noSO = '';
  String? currentFilter;
  String? currentIdLokasi;
  String? searchKeyword;


  List<StockOpnameLabel> labels = [];

  int page = 1;
  int pageSize = 50;
  int totalData = 0;
  bool hasMoreData = true;

  bool isInitialLoading = false;
  bool isLoadingMore = false;
  bool hasError = false;
  String errorMessage = '';

  Future<void> search(String keyword) async {
    searchKeyword = keyword;
    page = 1;
    hasMoreData = true;
    labels.clear();
    isInitialLoading = true;
    notifyListeners();

    await _fetchData();
  }

  void clearSearch() {
    searchKeyword = null;
    page = 1;
    hasMoreData = true;
    labels.clear();
    isInitialLoading = true;
    notifyListeners();

    _fetchData();
  }


  // ✅ Use SocketManager instead of direct socket
  final SocketManager _socketManager = SocketManager();
  late Function(Map<String, dynamic>) _socketCallback;

  StockOpnameDetailViewModel() {
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
    print('📦 Processing socket data in StockOpnameDetailViewModel: $labelData');
    print('🔍 Current NoSO: $noSO');
    print('🔍 Current Location Filter: $currentIdLokasi');

    // Debug all available keys
    print('🔑 Available keys: ${labelData.keys.toList()}');

    // 🔐 Jika sedang search, abaikan update socket
    if (searchKeyword != null && searchKeyword!.isNotEmpty) {
      print('⏸️ Ignored socket update because search is active: "$searchKeyword"');
      return;
    }

    // Check filter conditions
    final receivedNoSO = labelData['noso'];
    final receivedLocation = labelData['idlokasi'];
    final receivedLabelTypeCode = labelData['labelTypeCode'];

    print('📋 Received NoSO: $receivedNoSO (match: ${receivedNoSO == noSO})');
    print('📍 Received Location: $receivedLocation (current filter: $currentIdLokasi)');
    print('📍 Received LabelTypeCode: $receivedLabelTypeCode (current filter: $currentFilter)');

    if (receivedNoSO == noSO) {
      if (receivedLabelTypeCode == currentFilter || currentFilter == 'all' && currentIdLokasi == null || receivedLocation == currentIdLokasi || currentIdLokasi == 'all') {
        try {
          // Check if label already exists in current list
          final existingIndex = labels.indexWhere((label) =>
          label.nomorLabel == labelData['nomorLabel']);

          if (existingIndex != -1) {
            print('🚫 Label already exists in list: ${labelData['nomorLabel']}');
            return;
          }

          final newLabel = StockOpnameLabel.fromJson(labelData);
          labels.insert(0, newLabel);
          totalData++;

          print('✅ Label successfully added: ${newLabel.nomorLabel}');
          notifyListeners();
        } catch (e, stackTrace) {
          print('❌ Error parsing label data: $e');
          print('📋 Stack trace: $stackTrace');
          print('📋 Raw data: $labelData');
        }
      } else {
        print('🚫 Label filtered by location');
      }
    } else {
      print('🚫 Label filtered by NoSO');
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
    labels.clear();

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
        ApiConstants.labelSOList(
          selectedNoSO: noSO,
          page: page,
          pageSize: pageSize,
          filterBy: currentFilter,
          idLokasi: currentIdLokasi,
          search: searchKeyword,
        ),
      );

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> labelData = data['data'];
        final int total = data['totalData'];

        final fetched = labelData.map((e) => StockOpnameLabel.fromJson(e)).toList();

        labels.addAll(fetched);
        totalData = total;
        hasMoreData = labels.length < total;
        hasError = false;
        errorMessage = '';
      } else {
        hasError = true;
        errorMessage = 'Gagal mengambil data (status: ${response.statusCode})';
        print('❌ ERROR: $errorMessage');
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

  Future<bool> deleteLabel(String nomorLabel) async {
    try {
      final token = await _getToken();

      final url = Uri.parse('${ApiConstants.baseUrl}/api/no-stock-opname/$noSO/hasil');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nomorLabel': nomorLabel,
        }),
      );

      if (response.statusCode == 200) {
        // Successfully deleted, remove from local list
        labels.removeWhere((label) => label.nomorLabel == nomorLabel);
        totalData--;
        notifyListeners();
        return true;
      } else {
        print('❌ Gagal menghapus label: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception saat menghapus label: $e');
      return false;
    }
  }

  void reset() {
    labels.clear();
    page = 1;
    totalData = 0;
    hasMoreData = true;
    errorMessage = '';
    currentIdLokasi = null;
    _socketManager.clearProcessedLabels();
    notifyListeners();
  }

  @override
  void dispose() {
    // Unregister callback when disposing
    _socketManager.unregisterLabelInsertedCallback(_socketCallback);
    super.dispose();
  }
}