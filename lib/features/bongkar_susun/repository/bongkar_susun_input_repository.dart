// lib/features/shared/bongkar_susun/repository/bongkar_susun_input_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../production/shared/models/production_label_lookup_result.dart';
import '../model/bongkar_susun_inputs_model.dart';

class BongkarSusunInputRepository {
  static const _timeout = Duration(seconds: 25);

  final Map<String, BongkarSusunInputs> _inputsCache = {};

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  // -----------------------------
  // fetchInputs
  // -----------------------------
  static BongkarSusunInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return BongkarSusunInputs.fromJson(data);
  }

  /// GET /api/bongkar-susun/:noBongkarSusun/inputs
  Future<BongkarSusunInputs> fetchInputs(String noBongkarSusun,
      {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noBongkarSusun)) {
      return _inputsCache[noBongkarSusun]!;
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/bongkar-susun/$noBongkarSusun/inputs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil input ($noBongkarSusun)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] in ${elapsedMs}ms');

    if (res.statusCode != 200) {
      throw Exception(
          'Gagal mengambil input ($noBongkarSusun), code ${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response bukan JSON valid: $e');
    }

    final inputs = await compute(_parseInputs, body);

    _inputsCache[noBongkarSusun] = inputs;
    return inputs;
  }

  void invalidateInputs(String noBongkarSusun) =>
      _inputsCache.remove(noBongkarSusun);
  void clearCache() => _inputsCache.clear();

  // -----------------------------
  // validateLabel
  // -----------------------------
  /// GET /api/bongkar-susun/validate-label/:labelCode
  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) {
      throw ArgumentError('labelCode tidak boleh kosong');
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      '$_base/api/bongkar-susun/validate-label/${Uri.encodeComponent(code)}',
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

    if (res.statusCode == 200) {
      return ProductionLabelLookupResult.success(body);
    }
    if (res.statusCode == 404) {
      return ProductionLabelLookupResult.notFound(body);
    }

    final msg = (body['message'] as String?) ??
        'Gagal lookup label (HTTP ${res.statusCode})';
    throw Exception(msg);
  }

  // -----------------------------
  // Submit Inputs
  // -----------------------------
  /// POST /api/bongkar-susun/:noBongkarSusun/inputs
  /// Body: {
  ///   broker: [{ noBroker, noSak }],
  ///   bb: [{ noBahanBaku, noPallet, noSak }],
  ///   washing: [{ noWashing, noSak }],
  ///   crusher: [{ noCrusher }],
  ///   gilingan: [{ noGilingan }],
  ///   mixer: [{ noMixer, noSak }],
  ///   bonggolan: [{ noBonggolan }],
  ///   furnitureWip: [{ noFurnitureWip }],
  ///   barangJadi: [{ noBj }]
  /// }
  Future<Map<String, dynamic>> submitInputs(
      String noBongkarSusun,
      Map<String, dynamic> payload,
      ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/bongkar-susun/$noBongkarSusun/inputs');

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
      throw Exception('Timeout submit inputs ($noBongkarSusun)');
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
      final message =
          body['message'] as String? ?? 'Beberapa data tidak valid';
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
  // Delete Inputs
  // -----------------------------
  /// DELETE /api/bongkar-susun/:noBongkarSusun/inputs
  /// Body: {
  ///   broker: [{ noBroker, noSak }],
  ///   bb: [{ noBahanBaku, noPallet, noSak }],
  ///   washing: [{ noWashing, noSak }],
  ///   crusher: [{ noCrusher }],
  ///   gilingan: [{ noGilingan }],
  ///   mixer: [{ noMixer, noSak }],
  ///   bonggolan: [{ noBonggolan }],
  ///   furnitureWip: [{ noFurnitureWip }],
  ///   barangJadi: [{ noBj }]
  /// }
  ///
  /// Backend:
  /// - 200 => success (bisa dengan warning kalau ada notFound)
  /// - 404 => tidak ada data yang terhapus, tapi tetap response JSON yang rapi
  /// - 400 => request tidak valid (mis. tidak ada array yang berisi)
  /// - 500 => error server
  Future<Map<String, dynamic>> deleteInputs(
      String noBongkarSusun,
      Map<String, dynamic> payload,
      ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/bongkar-susun/$noBongkarSusun/inputs');

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
      throw Exception('Timeout delete inputs ($noBongkarSusun)');
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
}