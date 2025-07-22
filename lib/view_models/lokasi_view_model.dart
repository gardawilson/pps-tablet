import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/lokasi_model.dart';
import '../constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LokasiViewModel extends ChangeNotifier {
  List<LokasiModel> lokasiList = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchLokasi() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final token = await _getToken();
      final uri = Uri.parse(ApiConstants.mstLokasi); // pastikan ada getter di ApiConstants

      final response = await http.get(
        uri,
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];
        lokasiList = data.map((e) => LokasiModel.fromJson(e)).toList();
      } else {
        errorMessage = 'Gagal mengambil data lokasi';
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
