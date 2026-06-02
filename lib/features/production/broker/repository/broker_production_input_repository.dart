// lib/features/production/broker/repository/washing_production_input_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../../stock_opname/model/label_validation_result.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../model/broker_inputs_model.dart';
import '../model/broker_production_model.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

// ⬇️ model hasil validasi (shared)

class BrokerProductionInputRepository {
  static const _timeout = Duration(seconds: 25);

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  // -----------------------------
  // EXISTING: fetchInputs
  // -----------------------------
  static BrokerInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return BrokerInputs.fromJson(data);
  }

  static List<BrokerOutput> _parseOutputs(Map<String, dynamic> body) {
    final data = body['data'] as List?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return data
        .map((e) => BrokerOutput.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<BonggolanOutput> _parseBonggolanOutputs(
    Map<String, dynamic> body,
  ) {
    final data = body['data'] as List?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return data
        .map(
          (e) => BonggolanOutput.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<BrokerInputs> fetchInputs(
    String noProduksi, {
    bool force = false,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/broker/$noProduksi/inputs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil input ($noProduksi)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] in ${elapsedMs}ms');

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil input ($noProduksi), code ${res.statusCode})',
      );
    }

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response bukan JSON valid: $e');
    }

    return compute(_parseInputs, body);
  }

  Future<List<BrokerOutput>> fetchOutputs(String noProduksi) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/broker/$noProduksi/outputs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil output ($noProduksi)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] outputs in ${elapsedMs}ms');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response output bukan JSON valid: $e');
    }

    if (res.statusCode != 200) {
      final message =
          body['message'] as String? ?? 'Gagal mengambil output ($noProduksi)';
      throw Exception('$message (HTTP ${res.statusCode})');
    }

    return compute(_parseOutputs, body);
  }

  Future<List<BonggolanOutput>> fetchBonggolanOutputs(String noProduksi) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      '$_base/api/production/broker/$noProduksi/outputs/bonggolan',
    );

    final started = DateTime.now();
    print('[GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil output bonggolan ($noProduksi)');
    } catch (e) {
      print('[ERROR] Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('[${res.statusCode}] bonggolan outputs in ${elapsedMs}ms');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response output bonggolan bukan JSON valid: $e');
    }

    if (res.statusCode != 200) {
      final message =
          body['message'] as String? ??
          'Gagal mengambil output bonggolan ($noProduksi)';
      throw Exception('$message (HTTP ${res.statusCode})');
    }

    return compute(_parseBonggolanOutputs, body);
  }

  // -----------------------------
  // NEW: validateLabel
  // -----------------------------
  /// GET /api/production/broker/validate-label/:labelCode
  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) {
      throw ArgumentError('labelCode tidak boleh kosong');
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      '$_base/api/production/broker/validate-label/${Uri.encodeComponent(code)}',
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
    if (res.statusCode == 404)
      return ProductionLabelLookupResult.notFound(body);

    final msg =
        (body['message'] as String?) ??
        'Gagal lookup label (HTTP ${res.statusCode})';
    throw Exception(msg);
  }

  // -----------------------------
  // NEW: Submit Inputs & Partials
  // -----------------------------
  /// POST /api/production/broker/:noProduksi/inputs
  /// Body: { broker: [...], bb: [...], bbPartialNew: [...], ... }
  Future<Map<String, dynamic>> submitInputsAndPartials(
    String noProduksi,
    Map<String, dynamic> payload,
  ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/broker/$noProduksi/inputs');

    final started = DateTime.now();
    print('➡️ [POST] $url');
    print('📦 Payload: ${json.encode(payload)}');

    http.Response res;
    try {
      res = await http
          .post(
            url,
            headers: {..._headers(token), 'Content-Type': 'application/json'},
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
      final message =
          body['message'] as String? ??
          'Gagal submit inputs (HTTP ${res.statusCode})';
      throw Exception(message);
    }
  }

  // -----------------------------
  // NEW: Move Outputs
  // -----------------------------
  /// PATCH /api/production/broker/:noProduksi/outputs/move
  Future<Map<String, dynamic>> moveOutputs(
    String noProduksi,
    String targetNoProduksi,
    List<Map<String, dynamic>> items,
  ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      '$_base/api/production/broker/${Uri.encodeComponent(noProduksi)}/outputs/move',
    );

    final payload = {'targetNoProduksi': targetNoProduksi, 'items': items};

    print('➡️ [PATCH] $url');
    print('📦 Move payload: ${json.encode(payload)}');

    http.Response res;
    try {
      res = await http
          .patch(
            url,
            headers: {..._headers(token), 'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout memindahkan output ($noProduksi)');
    } catch (e) {
      print('❌ Request error (move outputs): $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] move outputs');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response move outputs bukan JSON valid: $e');
    }

    if (res.statusCode == 200) return body;

    final message =
        body['message'] as String? ??
        'Gagal memindahkan output (HTTP ${res.statusCode})';
    throw Exception(message);
  }

  // -----------------------------
  // NEW: Move Bonggolan Outputs
  // -----------------------------
  /// PATCH /api/production/broker/:noProduksi/outputs/bonggolan/move
  Future<Map<String, dynamic>> moveBonggolanOutputs(
    String noProduksi,
    String targetNoProduksi,
    List<String> noBonggolanList,
  ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      '$_base/api/production/broker/${Uri.encodeComponent(noProduksi)}/outputs/bonggolan/move',
    );

    final payload = {
      'targetNoProduksi': targetNoProduksi,
      'noBonggolanList': noBonggolanList,
    };

    print('➡️ [PATCH] $url');
    print('📦 Move bonggolan payload: ${json.encode(payload)}');

    http.Response res;
    try {
      res = await http
          .patch(
            url,
            headers: {..._headers(token), 'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout memindahkan output bonggolan ($noProduksi)');
    } catch (e) {
      print('❌ Request error (move bonggolan): $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] move bonggolan outputs');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response move bonggolan bukan JSON valid: $e');
    }

    if (res.statusCode == 200) return body;

    final message =
        body['message'] as String? ??
        'Gagal memindahkan output bonggolan (HTTP ${res.statusCode})';
    throw Exception(message);
  }

  // -----------------------------
  // NEW: Delete Inputs & Partials
  // -----------------------------
  /// DELETE /api/production/broker/:noProduksi/inputs
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
    final url = Uri.parse('$_base/api/production/broker/$noProduksi/inputs');

    final started = DateTime.now();
    print('🗑️ [DELETE] $url');
    print('📦 Delete payload: ${json.encode(payload)}');

    http.Response res;
    try {
      res = await http
          .delete(
            url,
            headers: {..._headers(token), 'Content-Type': 'application/json'},
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
      final message =
          body['message'] as String? ??
          'Gagal delete inputs (HTTP ${res.statusCode})';
      throw Exception(message);
    }
  }
}
