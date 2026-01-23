// lib/features/label/washing/repository/washing_audit_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/washing_history_model.dart';

class WashingAuditRepository {
  Future<List<WashingHistorySession>> fetchHistory(String noWashing) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/audit/washing/$noWashing/history",
    );

    print("➡️ Fetching Washing History: $url");

    final resp = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode != 200) {
      throw Exception('Gagal fetch history (status: ${resp.statusCode})');
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;

    // optional guard
    final success = body['success'] == true;
    if (!success) {
      final msg = body['message']?.toString() ?? 'Gagal fetch history';
      throw Exception(msg);
    }

    // ✅ ini yang benar: sessions adalah List
    final data = body['data'] as Map<String, dynamic>?;

    final sessionsRaw = data?['sessions'];
    if (sessionsRaw == null) return [];

    if (sessionsRaw is! List) {
      // biar errornya jelas kalau response berubah
      throw Exception("Format history tidak valid: data.sessions bukan List");
    }

    return sessionsRaw
        .map((e) => WashingHistorySession.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
