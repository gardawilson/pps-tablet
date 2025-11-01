import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/crusher_header_model.dart';

class CrusherRepository {
  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final token = await TokenStorage.getToken();

    final uri = Uri.parse("${ApiConstants.baseUrl}/api/labels/crusher")
        .replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });

    // ignore: avoid_print
    print("➡️ GET Bonggolan Headers: $uri");

    http.Response resp;
    try {
      resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout saat mengambil data Bonggolan');
    }

    // ignore: avoid_print
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    Map<String, dynamic> body;
    try {
      body = (resp.body.isNotEmpty) ? json.decode(resp.body) : {};
    } catch (_) {
      throw Exception('Response tidak valid (bukan JSON)');
    }

    if (resp.statusCode == 200) {
      final List<dynamic> raw = body['data'] ?? [];
      final items = raw
          .map((e) => CrusherHeader.fromJson(e as Map<String, dynamic>))
          .toList();

      final meta = (body['meta'] as Map<String, dynamic>?) ?? const {};
      return {
        'items': items,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'total': meta['total'] ?? items.length,
        'totalPages': meta['totalPages'] ?? 1,
      };
    }

    final msg = (body['message'] ?? body['error'] ?? 'Gagal fetch Bonggolan')
        .toString();
    throw Exception('$msg (status: ${resp.statusCode})');
  }

  /// POST create Crusher
  ///
  /// Body example:
  /// {
  ///   "header": {
  ///     "IdCrusher": 2,
  ///     "IdWarehouse": 5,
  ///     "DateCreate": "2025-10-30",
  ///     "Berat": 12.5,
  ///     "Blok": "B",
  ///     "IdLokasi": "B12"
  ///   },
  ///   "ProcessedCode": "G.20251030.0005" | "BG.00004567"   // optional
  /// }
  Future<Map<String, dynamic>> createCrusher(Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse("${ApiConstants.baseUrl}/api/labels/crusher");

    final res = await http
        .post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(body),
    )
        .timeout(_timeout);

    final Map<String, dynamic> parsed =
    res.body.isNotEmpty ? json.decode(res.body) : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return parsed;
    }

    final msg =
    (parsed['message'] ?? parsed['error'] ?? 'Gagal membuat Crusher')
        .toString();
    throw Exception('$msg (status: ${res.statusCode})');
  }


  // PUT update Crusher
  Future<Map<String, dynamic>> updateCrusher(
      String noCrusher,
      Map<String, dynamic> body,
      ) async {
    final token = await TokenStorage.getToken();

    if (body.isEmpty) {
      throw Exception('Tidak ada field yang diubah.');
    }

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/crusher/${Uri.encodeComponent(noCrusher)}",
    );

    final res = await http
        .put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(body),
    )
        .timeout(_timeout);

    final Map<String, dynamic> parsed =
    res.body.isNotEmpty ? json.decode(res.body) : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return parsed;
    }

    final msg =
    (parsed['message'] ?? parsed['error'] ?? 'Gagal update Crusher')
        .toString();
    throw Exception('$msg (status: ${res.statusCode})');
  }

  // DELETE Crusher
  Future<Map<String, dynamic>> deleteCrusher(String noCrusher) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/crusher/${Uri.encodeComponent(noCrusher)}",
    );

    print("🗑️ DELETE Crusher: $uri");

    http.Response resp;
    try {
      resp = await http
          .delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout saat menghapus Crusher');
    }

    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    Map<String, dynamic> body;
    try {
      body = resp.body.isNotEmpty ? json.decode(resp.body) : {};
    } catch (_) {
      throw Exception('Response tidak valid (bukan JSON)');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return body;
    }

    final msg =
    (body['message'] ?? body['error'] ?? 'Gagal menghapus Crusher')
        .toString();
    throw Exception('$msg (status: ${resp.statusCode})');
  }

}




