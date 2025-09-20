import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../constants/api_constants.dart';
import '../model/stock_opname_family_model.dart';

class StockOpnameFamilyViewModel extends ChangeNotifier {
  List<StockOpnameFamily> families = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchFamilies(String noSO) async {
    isLoading = true;
    hasError = false;
    errorMessage = '';
    notifyListeners();

    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/no-stock-opname/$noSO/families',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        families = data.map((e) => StockOpnameFamily.fromJson(e)).toList();
      } else {
        hasError = true;
        errorMessage =
        'Gagal mengambil data families (status: ${response.statusCode})';
      }
    } catch (e) {
      hasError = true;
      errorMessage = 'Kesalahan jaringan: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    families.clear();
    isLoading = false;
    hasError = false;
    errorMessage = '';
    notifyListeners();
  }
}
