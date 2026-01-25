// lib/features/audit/repository/audit_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import '../model/audit_session_model.dart';
import '../model/audit_config.dart';

class AuditRepository {
  /// Fetch audit history for specific document
  Future<List<AuditSession>> fetchHistory({
    required String module,
    required String documentNo,
    AuditModuleConfig? config,
  }) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/audit/$module/$documentNo/history",
    );

    print("➡️ [AuditRepo] Fetching $module history: $url");

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
    final sessionsRaw = data?['sessions'];

    if (sessionsRaw == null || sessionsRaw is! List) {
      return [];
    }

    return sessionsRaw.map((e) {
      return AuditSession.fromJson(
        e as Map<String, dynamic>,
        fieldConfigs: config?.fields,
      );
    }).toList();
  }
}