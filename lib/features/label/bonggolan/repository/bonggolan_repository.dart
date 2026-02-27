import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/bonggolan_header_model.dart';

class BonggolanRepository {
  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final token = await TokenStorage.getToken();

    final uri = Uri.parse("${ApiConstants.baseUrl}/api/labels/bonggolan")
        .replace(
          queryParameters: {
            'page': page.toString(),
            'limit': limit.toString(),
            if (search.trim().isNotEmpty) 'search': search.trim(),
          },
        );

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
          .map((e) => BonggolanHeader.fromJson(e as Map<String, dynamic>))
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

  /// POST create Bonggolan
  ///
  /// body example:
  /// {
  ///   "header": {
  ///     "IdBonggolan": 3,
  ///     "IdWarehouse": 5,
  ///     "DateCreate": "2025-10-28",
  ///     "Berat": 12.5,
  ///     "Blok": "A",
  ///     "IdLokasi": "A1"
  ///   },
  ///   "ProcessedCode": "E.00012345" | "S.00012345" | "BG.00012345"
  /// }
  Future<Map<String, dynamic>> createBonggolan(
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse("${ApiConstants.baseUrl}/api/labels/bonggolan");

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

    final Map<String, dynamic> parsed = res.body.isNotEmpty
        ? json.decode(res.body)
        : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return parsed;
    }

    final msg =
        (parsed['message'] ?? parsed['error'] ?? 'Gagal membuat Bonggolan')
            .toString();
    throw Exception('$msg (status: ${res.statusCode})');
  }

  // PUT update Bonggolan
  Future<Map<String, dynamic>> updateBonggolan(
    String noBonggolan,
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/bonggolan/$noBonggolan",
    );

    // Minimal guard: must send at least 1 editable field
    if (body.isEmpty) {
      throw Exception('Tidak ada field yang diubah.');
    }

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

    final Map<String, dynamic> parsed = res.body.isNotEmpty
        ? json.decode(res.body)
        : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return parsed;
    }

    final msg =
        (parsed['message'] ?? parsed['error'] ?? 'Gagal update Bonggolan')
            .toString();
    throw Exception('$msg (status: ${res.statusCode})');
  }

  /// Fetch bonggolan outputs dari Broker NoProduksi
  Future<List<BonggolanOutputItem>> fetchOutputsByBrokerNoProduksi(
    String noProduksi,
  ) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/production/broker/$noProduksi/outputs/bonggolan",
    );
    final resp = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(_timeout);
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      final List<dynamic> data = body['data'] ?? [];
      return data
          .map((e) => BonggolanOutputItem.fromJson(e as Map<String, dynamic>))
          .where((o) => o.noBonggolan.isNotEmpty)
          .toList();
    }
    throw Exception(
      'Failed to fetch bonggolan outputs by broker (status: ${resp.statusCode})',
    );
  }

  /// Fetch bonggolan outputs dari Inject NoProduksi
  Future<List<BonggolanOutputItem>> fetchOutputsByInjectNoProduksi(
    String noProduksi,
  ) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/production/inject/$noProduksi/outputs/bonggolan",
    );
    final resp = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(_timeout);
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      final List<dynamic> data = body['data'] ?? [];
      return data
          .map((e) => BonggolanOutputItem.fromJson(e as Map<String, dynamic>))
          .where((o) => o.noBonggolan.isNotEmpty)
          .toList();
    }
    throw Exception(
      'Failed to fetch bonggolan outputs by inject (status: ${resp.statusCode})',
    );
  }

  /// Fetch bonggolan outputs dari NoBongkarSusun
  Future<List<BonggolanOutputItem>> fetchOutputsByNoBongkarSusun(
    String noBongkarSusun,
  ) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/bongkar-susun/$noBongkarSusun/outputs/bonggolan",
    );
    final resp = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(_timeout);
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      final List<dynamic> data = body['data'] ?? [];
      return data
          .map((e) => BonggolanOutputItem.fromJson(e as Map<String, dynamic>))
          .where((o) => o.noBonggolan.isNotEmpty)
          .toList();
    }
    throw Exception(
      'Failed to fetch bonggolan outputs by bongkar susun (status: ${resp.statusCode})',
    );
  }

  /// Tandai bonggolan sudah dicetak
  Future<void> markAsPrinted(String noBonggolan) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/bonggolan/$noBonggolan/print",
    );
    final resp = await http
        .patch(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_timeout);
    print("🖨️ PATCH Mark As Printed Bonggolan: $uri");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      final Map<String, dynamic> parsed = resp.body.isNotEmpty
          ? json.decode(resp.body)
          : {};
      final msg =
          (parsed['message'] ??
                  parsed['error'] ??
                  'Gagal mark as printed bonggolan (status: ${resp.statusCode})')
              .toString();
      throw Exception(msg);
    }
  }

  // DELETE Bonggolan
  Future<Map<String, dynamic>> deleteBonggolan(String noBonggolan) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/bonggolan/$noBonggolan",
    );

    print("🗑️ DELETE Bonggolan: $uri");

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
      throw Exception('Timeout saat menghapus Bonggolan');
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
        (body['message'] ?? body['error'] ?? 'Gagal menghapus Bonggolan')
            .toString();
    throw Exception('$msg (status: ${resp.statusCode})');
  }
}
