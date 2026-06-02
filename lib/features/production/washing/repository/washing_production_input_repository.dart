// lib/features/production/washing/repository/washing_production_input_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../model/washing_inputs_model.dart';
import '../model/washing_output_model.dart';

class WashingProductionInputRepository {
  static const _timeout = Duration(seconds: 25);

  // cache per noProduksi
  final Map<String, WashingInputs> _inputsCache = {};

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  // -----------------------------
  // Parser untuk isolate (compute)
  // -----------------------------
  static WashingInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Response tidak valid: field data kosong');
    }
    return WashingInputs.fromJson(data);
  }

  // -----------------------------
  // GET /api/production/washing/:noProduksi/inputs
  // -----------------------------
  Future<WashingInputs> fetchInputs(
      String noProduksi, {
        bool force = false,
      }) async {
    final key = noProduksi.trim();
    if (key.isEmpty) {
      throw ArgumentError('noProduksi tidak boleh kosong');
    }

    if (!force && _inputsCache.containsKey(key)) {
      return _inputsCache[key]!;
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/washing/$key/inputs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil washing inputs ($key)');
    } catch (e) {
      print('❌ Request error (washing inputs): $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] (washing inputs) in ${elapsedMs}ms');

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil washing inputs ($key), code ${res.statusCode}',
      );
    }

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response washing inputs bukan JSON valid: $e');
    }

    // parse di isolate biar ringan
    final inputs = await compute(_parseInputs, body);

    _inputsCache[key] = inputs;
    return inputs;
  }

  void invalidateInputs(String noProduksi) =>
      _inputsCache.remove(noProduksi.trim());

  void clearCache() => _inputsCache.clear();

  // -----------------------------
  // GET /api/production/washing/:noProduksi/outputs
  // -----------------------------
  static List<WashingOutput> _parseOutputs(Map<String, dynamic> body) {
    final data = body['data'];
    if (data == null) return [];
    final list = data as List;
    return list
        .map(
          (e) =>
              WashingOutput.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<WashingOutput>> fetchOutputs(String noProduksi) async {
    final key = noProduksi.trim();
    if (key.isEmpty) throw ArgumentError('noProduksi tidak boleh kosong');

    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/washing/$key/outputs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil washing outputs ($key)');
    } catch (e) {
      print('❌ Request error (washing outputs): $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] (washing outputs) in ${elapsedMs}ms');

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil washing outputs ($key), code ${res.statusCode}',
      );
    }

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response washing outputs bukan JSON valid: $e');
    }

    return compute(_parseOutputs, body);
  }



  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) {
      throw ArgumentError('labelCode tidak boleh kosong');
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      '$_base/api/production/washing/validate-label/${Uri.encodeComponent(code)}',
    );

    print('➡️ [GET] $url');
    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout lookup label ($code)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }
    print('⬅️ [${res.statusCode}] validate-label');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response validate-label bukan JSON valid: $e');
    }

    if (res.statusCode == 200) return ProductionLabelLookupResult.success(body);
    if (res.statusCode == 404) return ProductionLabelLookupResult.notFound(body);

    final msg = (body['message'] as String?) ?? 'Gagal lookup label (HTTP ${res.statusCode})';
    throw Exception(msg);
  }


  // -----------------------------
  // NEW: Submit Inputs & Partials
  // -----------------------------
  /// POST /api/production/washing/:noProduksi/inputs
  /// Body: { broker: [...], bb: [...], bbPartialNew: [...], ... }
  Future<Map<String, dynamic>> submitInputsAndPartials(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/washing/$noProduksi/inputs');

    final started = DateTime.now();
    print('➡️ [POST] $url');
    print('📦 Payload: ${json.encode(payload)}');

    http.Response res;
    try {
      res = await http
          .post(
        url,
        headers: {
          ..._headers(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout submit inputs ($noProduksi)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] in ${elapsedMs}ms');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response bukan JSON valid: $e');
    }

    // Log response untuk debugging
    print('📥 Response: ${json.encode(body)}');

    // Handle different status codes
    if (res.statusCode == 200) {
      // Success
      return body;
    } else if (res.statusCode == 422) {
      // Unprocessable Entity - some data invalid
      final message = body['message'] as String? ?? 'Beberapa data tidak valid';
      throw Exception(message);
    } else if (res.statusCode == 400) {
      // Bad Request
      final message = body['message'] as String? ?? 'Request tidak valid';
      throw Exception(message);
    } else {
      // Other errors
      final message = body['message'] as String? ??
          'Gagal submit inputs (HTTP ${res.statusCode})';
      throw Exception(message);
    }
  }



  // -----------------------------
  // NEW: Delete Inputs & Partials
  // -----------------------------
  /// DELETE /api/production/washing/:noProduksi/inputs
  /// Body: { broker: [...], bb: [...], brokerPartial: [...], ... }
  ///
  /// Backend:
  /// - 200 => success (bisa dengan warning kalau ada notFound)
  /// - 404 => tidak ada data yang terhapus, tapi tetap response JSON yang rapi
  /// - 400 => request tidak valid (mis. tidak ada array yang berisi)
  /// - 500 => error server
  Future<Map<String, dynamic>> deleteInputsAndPartials(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/washing/$noProduksi/inputs');

    final started = DateTime.now();
    print('🗑️ [DELETE] $url');
    print('📦 Delete payload: ${json.encode(payload)}');

    http.Response res;
    try {
      res = await http
          .delete(
        url,
        headers: {
          ..._headers(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout delete inputs ($noProduksi)');
    } catch (e) {
      print('❌ Request error (delete inputs): $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] (delete inputs) in ${elapsedMs}ms');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response delete inputs bukan JSON valid: $e');
    }

    // Log response untuk debugging
    print('📥 Delete response: ${json.encode(body)}');

    // Backend design:
    // - 200: success / success + warning (lihat field success & hasWarnings di body)
    // - 404: tidak ada yang terhapus → tetap kita return ke caller (biar bisa tampilkan pesan)
    if (res.statusCode == 200 || res.statusCode == 404) {
      return body;
    } else if (res.statusCode == 400) {
      final message =
          body['message'] as String? ?? 'Request delete inputs tidak valid';
      throw Exception(message);
    } else {
      final message = body['message'] as String? ??
          'Gagal delete inputs (HTTP ${res.statusCode})';
      throw Exception(message);
    }
  }

  // -----------------------------
  // POST: Create Label Washing
  // -----------------------------
  /// POST /api/labels/washing
  /// Body: {
  ///   "header": { "IdJenisPlastik": idJenis, "DateCreate": "YYYY-MM-DD", "IdWarehouse": 2 },
  ///   "details": [{ "NoSak": n, "Berat": b }],
  ///   "NoProduksi": noProduksi
  /// }
  /// Returns: noWashing (String) hasil create
  Future<String> createOutput({
    required String noProduksi,
    required int idJenis,
    required DateTime tglProduksi,
    required List<Map<String, dynamic>> details,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/labels/washing');

    final dateStr =
        '${tglProduksi.year.toString().padLeft(4, '0')}-'
        '${tglProduksi.month.toString().padLeft(2, '0')}-'
        '${tglProduksi.day.toString().padLeft(2, '0')}';

    final payload = <String, dynamic>{
      'header': {
        'IdJenisPlastik': idJenis,
        'DateCreate': dateStr,
        'IdWarehouse': 2,
      },
      'details': details, // sudah pakai key NoSak, Berat (capitalized)
      'NoProduksi': noProduksi,
    };

    debugPrint('➡️ [POST] $url');
    debugPrint('📦 Payload: ${json.encode(payload)}');

    final started = DateTime.now();
    http.Response res;
    try {
      res = await http
          .post(
            url,
            headers: {
              ..._headers(token),
              'Content-Type': 'application/json',
            },
            body: json.encode(payload),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout create label washing ($noProduksi)');
    } catch (e) {
      debugPrint('❌ Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    debugPrint('⬅️ [${res.statusCode}] in ${elapsedMs}ms');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response create label washing bukan JSON valid: $e');
    }
    debugPrint('📥 Response: ${json.encode(body)}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      // Ambil noWashing dari response
      final data = body['data'];
      String noWashing = '';
      if (data is Map<String, dynamic>) {
        noWashing = (data['NoWashing'] as String?) ?? '';
      } else if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) {
          noWashing = (first['NoWashing'] as String?) ?? '';
        }
      }
      return noWashing;
    }
    final msg =
        (body['message'] as String?) ??
        'Gagal membuat label washing (HTTP ${res.statusCode})';
    throw Exception(msg);
  }
}
