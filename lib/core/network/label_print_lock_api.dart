import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/token_storage.dart';
import 'endpoints.dart';

class LabelPrintLockApi {
  Future<void> acquire(String documentNo) async {
    final token = await TokenStorage.getToken();
    final encodedNo = Uri.encodeComponent(documentNo);
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/$encodedNo/print-lock",
    );

    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (resp.statusCode != 200 &&
        resp.statusCode != 201 &&
        resp.statusCode != 204) {
      throw Exception(
        _extractApiMessage(resp.body, 'Gagal memperoleh print lock'),
      );
    }
  }

  Future<void> release(String documentNo) async {
    final token = await TokenStorage.getToken();
    final encodedNo = Uri.encodeComponent(documentNo);
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/$encodedNo/print-lock",
    );

    final resp = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (resp.statusCode != 200 &&
        resp.statusCode != 204 &&
        resp.statusCode != 404) {
      throw Exception(
        _extractApiMessage(resp.body, 'Gagal melepas print lock'),
      );
    }
  }

  String _extractApiMessage(String body, String fallback) {
    if (body.trim().isEmpty) return fallback;
    try {
      final parsed = json.decode(body);
      if (parsed is Map<String, dynamic>) {
        final msg = parsed['message']?.toString().trim();
        if (msg != null && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return fallback;
  }
}
