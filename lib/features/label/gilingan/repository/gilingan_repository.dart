import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/gilingan_header_model.dart';
import '../model/gilingan_partial_model.dart';

class GilinganRepository {
  static const _timeout = Duration(seconds: 15);

  /// GET /api/labels/gilingan?page=&limit=&search=
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final token = await TokenStorage.getToken();

    final uri = Uri.parse("${ApiConstants.baseUrl}/api/labels/gilingan")
        .replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });

    // ignore: avoid_print
    print("➡️ GET Gilingan Headers: $uri");

    http.Response resp;
    try {
      resp = await http
          .get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout saat mengambil data Gilingan');
    }

    // ignore: avoid_print
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    Map<String, dynamic> body;
    try {
      body = resp.body.isNotEmpty ? json.decode(resp.body) : {};
    } catch (_) {
      throw Exception('Response tidak valid (bukan JSON)');
    }

    if (resp.statusCode == 200) {
      final List<dynamic> raw = body['data'] ?? [];
      final items = raw
          .map((e) => GilinganHeader.fromJson(e as Map<String, dynamic>))
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

    final msg =
    (body['message'] ?? body['error'] ?? 'Gagal fetch Gilingan').toString();
    throw Exception('$msg (status: ${resp.statusCode})');
  }

  /// POST /api/labels/gilingan
  ///
  /// Body example **(outputCode WAJIB)**:
  /// {
  ///   "header": {
  ///     "IdGilingan": 1,
  ///     "DateCreate": "2025-10-30",
  ///     "Berat": 12.5,
  ///     "Blok": "A",
  ///     "IdLokasi": "A1"
  ///   },
  ///   "outputCode": "W.0000004133"   // or "BG.0000004133"
  /// }
  Future<Map<String, dynamic>> createGilingan(
      Map<String, dynamic> body,
      ) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse("${ApiConstants.baseUrl}/api/labels/gilingan");

    // Optional client-side guard to avoid hitting API with invalid data
    final oc = (body['outputCode'] ?? '').toString().trim();
    if (oc.isEmpty) {
      throw Exception('outputCode wajib diisi (W. atau BG.)');
    }

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
    (parsed['message'] ?? parsed['error'] ?? 'Gagal membuat Gilingan')
        .toString();
    throw Exception('$msg (status: ${res.statusCode})');
  }

  /// PUT /api/labels/gilingan/:noGilingan
  ///
  /// Backend menerima:
  /// - { "header": { ...field yang diubah... } }  (yang kamu pakai sekarang), atau
  /// - { ...field yang diubah langsung... }
  Future<Map<String, dynamic>> updateGilingan(
      String noGilingan,
      Map<String, dynamic> body,
      ) async {
    final token = await TokenStorage.getToken();

    if (body.isEmpty) {
      throw Exception('Tidak ada field yang diubah.');
    }

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/gilingan/${Uri.encodeComponent(noGilingan)}",
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
    (parsed['message'] ?? parsed['error'] ?? 'Gagal update Gilingan')
        .toString();
    throw Exception('$msg (status: ${res.statusCode})');
  }

  /// DELETE /api/labels/gilingan/:noGilingan
  Future<Map<String, dynamic>> deleteGilingan(String noGilingan) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/gilingan/${Uri.encodeComponent(noGilingan)}",
    );

    print("🗑️ DELETE Gilingan: $uri");

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
      throw Exception('Timeout saat menghapus Gilingan');
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
    (body['message'] ?? body['error'] ?? 'Gagal menghapus Gilingan')
        .toString();
    throw Exception('$msg (status: ${resp.statusCode})');
  }


  /// Fetch partial info for one Gilingan (per NoGilingan)
  Future<GilinganPartialInfo> fetchPartialInfo({
    required String noGilingan,
  }) async {
    final token = await TokenStorage.getToken();

    final encodedNo = Uri.encodeComponent(noGilingan);
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/gilingan/partials/$encodedNo",
    );

    print("➡️ Fetching Gilingan Partial Info: $url");

    final resp = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode != 200) {
      throw Exception(
        "Failed to fetch gilingan partial info (${resp.statusCode})",
      );
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    return GilinganPartialInfo.fromEnvelope(body);
  }
}
