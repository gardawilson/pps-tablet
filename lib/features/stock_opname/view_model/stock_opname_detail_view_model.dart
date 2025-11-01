import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/endpoints.dart';
import '../model/stock_opname_label_model.dart';
import 'socket_manager.dart';

class StockOpnameDetailViewModel extends ChangeNotifier {
  String noSO = '';
  String? currentFilter;
  String? currentBlok;       // ✅ pisah blok
  int? currentIdLokasi;      // ✅ pisah id lokasi
  String? searchKeyword;

  List<StockOpnameLabel> labels = [];

  int page = 1;
  int pageSize = 50;
  int totalData = 0;
  int totalSak = 0;
  double totalBerat = 0;

  bool hasMoreData = true;

  bool isInitialLoading = false;
  bool isLoadingMore = false;
  bool hasError = false;
  String errorMessage = '';

  final SocketManager _socketManager = SocketManager();
  late Function(Map<String, dynamic>) _socketCallback;

  StockOpnameDetailViewModel() {
    _socketCallback = _handleSocketData;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void initSocket() {
    _socketManager.initSocket();
    _socketManager.registerLabelInsertedCallback(_socketCallback);
  }

  void _handleSocketData(Map<String, dynamic> labelData) {
    print('📦 Socket data received in StockOpnameDetailViewModel: $labelData');

    // Kalau sedang search, abaikan update socket
    if (searchKeyword != null && searchKeyword!.isNotEmpty) {
      print('⏸️ Ignored socket update (search active)');
      return;
    }

    final receivedNoSO = labelData['noso'];
    final receivedLabelType = labelData['labelTypeCode'];
    final receivedBlok = labelData['blok'];
    final receivedIdLokasi = labelData['idlokasi'];

    print('🔍 Received => NoSO: $receivedNoSO | Blok: $receivedBlok | IdLokasi: $receivedIdLokasi | Type: $receivedLabelType');

    // Filter: NoSO harus cocok
    if (receivedNoSO != noSO) return;

    // Filter by kategori dan lokasi/blok
    final matchKategori = currentFilter == 'all' || currentFilter == receivedLabelType;
    final matchBlok = currentBlok == null || currentBlok == 'all' || currentBlok == receivedBlok;
    final matchIdLokasi = currentIdLokasi == null ||
        currentIdLokasi == 0 ||
        receivedIdLokasi == currentIdLokasi;

    if (matchKategori && matchBlok && matchIdLokasi) {
      try {
        // Hindari duplikasi label
        if (labels.any((l) => l.nomorLabel == labelData['nomorLabel'])) return;

        final newLabel = StockOpnameLabel.fromJson(labelData);
        labels.insert(0, newLabel);
        totalData++;
        notifyListeners();
        print('✅ Label added: ${newLabel.nomorLabel}');
      } catch (e, st) {
        print('❌ Error parsing socket data: $e');
        print(st);
      }
    }
  }

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
    labels.clear();

    _socketManager.clearProcessedLabels();

    isInitialLoading = true;
    notifyListeners();

    await _fetchData();
  }

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
          blok: currentBlok,          // String?
          idLokasi: currentIdLokasi,  // int?
          search: searchKeyword,
        ),
      );

      print('🌐 GET: $url');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> labelData = data['data'];
        final int total = data['totalData'];
        final int sumSak = data['totalSak'];
        final double sumBerat = (data['totalBerat'] as num?)?.toDouble() ?? 0.0;

        final fetched = labelData.map((e) => StockOpnameLabel.fromJson(e)).toList();

        labels.addAll(fetched);
        totalData = total;
        totalSak = sumSak;
        totalBerat = sumBerat;
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
        body: json.encode({'nomorLabel': nomorLabel}),
      );

      if (response.statusCode == 200) {
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
    currentBlok = null;
    currentIdLokasi = null;
    _socketManager.clearProcessedLabels();
    notifyListeners();
  }

  @override
  void dispose() {
    _socketManager.unregisterLabelInsertedCallback(_socketCallback);
    super.dispose();
  }
}
