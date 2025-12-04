// lib/features/furniture_wip/repository/furniture_wip_repository.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/furniture_wip_header_model.dart';
import '../model/furniture_wip_partial_model.dart';

class FurnitureWipRepository {
  static const _timeout = Duration(seconds: 15);

  /// GET /api/labels/furniture-wip?page=&limit=&search=
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final token = await TokenStorage.getToken();

    final uri =
    Uri.parse("${ApiConstants.baseUrl}/api/labels/furniture-wip").replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    // ignore: avoid_print
    print("➡️ GET Furniture WIP Headers: $uri");

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
      throw Exception('Timeout saat mengambil data Furniture WIP');
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
          .map(
            (e) => FurnitureWipHeader.fromJson(e as Map<String, dynamic>),
      )
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

    final msg = (body['message'] ??
        body['error'] ??
        'Gagal fetch Furniture WIP')
        .toString();
    throw Exception('$msg (status: ${resp.statusCode})');
  }

  /// POST /api/labels/furniture-wip
  ///
  /// Body example (outputCode WAJIB, sesuai backend):
  /// {
  ///   "header": {
  ///     "IdFurnitureWIP": 1,
  ///     "Pcs": 10,
  ///     "Berat": 25.5,
  ///     "DateCreate": "2025-12-01",
  ///     "Blok": "A",
  ///     "IdLokasi": "A1",
  ///     "IdWarna": 1,
  ///     "IsPartial": 0
  ///   },
  ///   "outputCode": "BH.0000001234"   // BH/BI/BG/L/BJ/S
  /// }
  Future<Map<String, dynamic>> createFurnitureWip(
      Map<String, dynamic> body,
      ) async {
    final token = await TokenStorage.getToken();
    final uri =
    Uri.parse("${ApiConstants.baseUrl}/api/labels/furniture-wip");

    // Guard: outputCode wajib (backend juga require)
    final oc = (body['outputCode'] ?? '').toString().trim();
    if (oc.isEmpty) {
      throw Exception(
        'outputCode wajib diisi (BH., BI., BG., L., BJ., S.)',
      );
    }

    // 📝 LOG: apa yang akan dikirim ke backend
    if (kDebugMode) {
      final enc = const JsonEncoder.withIndent('  ');
      debugPrint('════════════════════════════════════════');
      debugPrint('▶ POST /api/labels/furniture-wip');
      debugPrint('  URL   : $uri');
      debugPrint('  TOKEN : ${token != null && token.length > 10 ? token.substring(0, 10) + '...' : token}');
      debugPrint('  --- REQUEST BODY ---');
      debugPrint(enc.convert(body));
      debugPrint('════════════════════════════════════════');
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

    // 📝 (Opsional) log response kalau error
    if (kDebugMode && (res.statusCode < 200 || res.statusCode >= 300)) {
      debugPrint('❌ FurnitureWIP API ERROR '
          '(status: ${res.statusCode}) → ${res.body}');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return parsed;
    }

    final msg = (parsed['message'] ??
        parsed['error'] ??
        'Gagal membuat Furniture WIP')
        .toString();
    throw Exception('$msg (status: ${res.statusCode})');
  }


  /// PUT /api/labels/furniture-wip/:noFurnitureWip
  ///
  /// Body (contoh):
  /// {
  ///   "header": { ...field yang mau diubah... },
  ///   "outputCode": "BH.0000..."  // optional
  /// }
  Future<Map<String, dynamic>> updateFurnitureWip(
      String noFurnitureWip,
      Map<String, dynamic> body,
      ) async {
    final token = await TokenStorage.getToken();

    if (body.isEmpty) {
      throw Exception('Tidak ada field yang diubah.');
    }

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/furniture-wip/${Uri.encodeComponent(noFurnitureWip)}",
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

    final msg = (parsed['message'] ??
        parsed['error'] ??
        'Gagal update Furniture WIP')
        .toString();
    throw Exception('$msg (status: ${res.statusCode})');
  }

  /// DELETE /api/labels/furniture-wip/:noFurnitureWip
  Future<Map<String, dynamic>> deleteFurnitureWip(
      String noFurnitureWip,
      ) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/furniture-wip/${Uri.encodeComponent(noFurnitureWip)}",
    );

    print("🗑️ DELETE Furniture WIP: $uri");

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
      throw Exception('Timeout saat menghapus Furniture WIP');
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

    final msg = (body['message'] ??
        body['error'] ??
        'Gagal menghapus Furniture WIP')
        .toString();
    throw Exception('$msg (status: ${resp.statusCode})');
  }

  /// GET /api/labels/furniture-wip/partials/:nofurniturewip
  ///
  /// Mengambil info partial untuk 1 NoFurnitureWIP
  Future<FurnitureWipPartialInfo> fetchPartialInfo({
    required String noFurnitureWip,
  }) async {
    final token = await TokenStorage.getToken();

    final encodedNo = Uri.encodeComponent(noFurnitureWip);
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/furniture-wip/partials/$encodedNo",
    );

    print("➡️ Fetching Furniture WIP Partial Info: $url");

    final resp = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode != 200) {
      throw Exception(
        "Failed to fetch furniture WIP partial info (${resp.statusCode})",
      );
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    return FurnitureWipPartialInfo.fromEnvelope(body);
  }
}
