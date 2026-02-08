// lib/features/audit/repository/audit_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';

class AuditRepository {
  /// Fetch audit history - AUTO-DETECT MODULE from document prefix
  Future<Map<String, dynamic>> fetchHistory({
    required String documentNo,
  }) async {
    final token = await TokenStorage.getToken();

    // 🎯 FIX: URL tanpa parameter module, hanya documentNo
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/audit/$documentNo/history",
    );

    print("➡️ [AuditRepo] Fetching history (auto-detect): $url");

    final resp = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ [AuditRepo] Response [${resp.statusCode}]");

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch audit history (status: ${resp.statusCode})',
      );
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;

    if (body['success'] != true) {
      final msg = body['message']?.toString() ?? 'Failed to fetch history';
      throw Exception(msg);
    }

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response: missing data field');
    }

    // Extract detected module, prefix, documentNo
    final detectedModule = data['module']?.toString() ?? '';
    final prefix = data['prefix']?.toString();
    final docNo = data['documentNo']?.toString() ?? documentNo;
    final sessionsRaw = data['sessions'];

    print("✅ [AuditRepo] Detected module: $detectedModule (prefix: $prefix)");

    if (sessionsRaw == null || sessionsRaw is! List) {
      return {
        'module': detectedModule,
        'prefix': prefix,
        'documentNo': docNo,
        'sessions': <dynamic>[],
      };
    }

    return {
      'module': detectedModule,
      'prefix': prefix,
      'documentNo': docNo,
      'sessions': sessionsRaw,
    };
  }
}
