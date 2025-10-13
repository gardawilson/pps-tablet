import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/label_detail_model.dart';
import '../../../core/network/endpoints.dart';

class LabelDetailViewModel extends ChangeNotifier {
  LabelDetailModel? detail;
  bool isLoading = false;
  String errorMessage = '';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchLabelDetail(String nomorLabel) async {
    if (nomorLabel.isEmpty) return;

    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final token = await _getToken();

      if (token == null) {
        errorMessage = 'Token tidak ditemukan';
        isLoading = false;
        notifyListeners();
        return;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/label/detail/$nomorLabel');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final jsonString = response.body;
        print('🔎 JSON response: $jsonString');

        final jsonData = json.decode(jsonString);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          detail = LabelDetailModel.fromJson(jsonData['data']);
        } else {
          errorMessage = 'Data tidak ditemukan';
          detail = null;
        }
      } else {
        errorMessage = 'Gagal mengambil detail label (Status: ${response.statusCode})';
        detail = null;
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan: $e';
      detail = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    detail = null;
    errorMessage = '';
    notifyListeners();
  }
}
