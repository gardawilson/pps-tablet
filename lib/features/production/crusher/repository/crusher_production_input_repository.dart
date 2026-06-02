// lib/features/production/crusher/repository/crusher_production_input_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../../stock_opname/model/label_validation_result.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../model/crusher_inputs_model.dart';
import '../model/crusher_output_model.dart';
import '../model/crusher_production_model.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

class CrusherProductionInputRepository {
  static const _timeout = Duration(seconds: 25);

  final Map<String, CrusherInputs> _inputsCache = {};

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  // -----------------------------
  // FETCH INPUTS (READY)
  // -----------------------------
  static CrusherInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return CrusherInputs.fromJson(data);
  }

  Future<CrusherInputs> fetchInputs(String noCrusherProduksi, {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noCrusherProduksi)) {
      return _inputsCache[noCrusherProduksi]!;
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/crusher/$noCrusherProduksi/inputs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil input ($noCrusherProduksi)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] in ${elapsedMs}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil input ($noCrusherProduksi), code ${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response bukan JSON valid: $e');
    }

    final inputs = await compute(_parseInputs, body);

    _inputsCache[noCrusherProduksi] = inputs;
    return inputs;
  }

  void invalidateInputs(String noCrusherProduksi) => _inputsCache.remove(noCrusherProduksi);
  void clearCache() => _inputsCache.clear();

  // -----------------------------
  // FETCH OUTPUTS
  // -----------------------------
  Future<List<CrusherOutput>> fetchOutputs(String noCrusherProduksi) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/crusher/$noCrusherProduksi/outputs');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil output ($noCrusherProduksi)');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil output ($noCrusherProduksi), code ${res.statusCode}');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List? ?? []);
    return list
        .map((e) => CrusherOutput.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

// -----------------------------
// VALIDATE LABEL
// -----------------------------
  /// GET /api/produksi/crusher/validate-label/:labelCode
  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) {
      throw ArgumentError('labelCode tidak boleh kosong');
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      '$_base/api/production/crusher/validate-label/${Uri.encodeComponent(code)}',
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
// SUBMIT INPUTS & PARTIALS
// -----------------------------
  /// POST /api/produksi/crusher/:noCrusherProduksi/inputs
  /// Body: { bb: [...], bbPartialNew: [...], bonggolan: [...] }
  Future<Map<String, dynamic>> submitInputsAndPartials(
    String noCrusherProduksi,
    Map<String, dynamic> payload,
  ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/crusher/$noCrusherProduksi/inputs');

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
      throw Exception('Timeout submit inputs ($noCrusherProduksi)');
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
// CREATE OUTPUT
// -----------------------------
  /// POST /api/labels/crusher
  /// Body: { header: { IdCrusher, DateCreate, Berat }, ProcessedCode }
  Future<void> createOutputs({
    required String noProduksi,
    required int idJenis,
    required double berat,
    required DateTime tglProduksi,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/labels/crusher');

    final dateStr =
        '${tglProduksi.year.toString().padLeft(4, '0')}-'
        '${tglProduksi.month.toString().padLeft(2, '0')}-'
        '${tglProduksi.day.toString().padLeft(2, '0')}';

    final payload = {
      'header': {
        'IdCrusher': idJenis,
        'DateCreate': dateStr,
        'Berat': berat,
      },
      'ProcessedCode': noProduksi,
    };

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
      throw Exception('Timeout create output crusher ($noProduksi)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] create output crusher');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response create output crusher bukan JSON valid: $e');
    }

    if (res.statusCode == 200 || res.statusCode == 201) return;

    final msg = (body['message'] as String?) ??
        'Gagal create output crusher (HTTP ${res.statusCode})';
    throw Exception(msg);
  }

// -----------------------------
// SPLIT TIME (GANTI PRODUKSI)
// -----------------------------
  /// POST /api/production/crusher/split-time/{idMesin}/{tanggal}
  /// Body: { "hourStart": "13:30", "outputJenisId": 12 }
  Future<Map<String, dynamic>> splitTime({
    required int idMesin,
    required DateTime tanggal,
    required String hourStart,
    required int outputJenisId,
  }) async {
    final token = await TokenStorage.getToken();
    final dateStr =
        '${tanggal.year.toString().padLeft(4, '0')}-'
        '${tanggal.month.toString().padLeft(2, '0')}-'
        '${tanggal.day.toString().padLeft(2, '0')}';
    final url = Uri.parse('$_base/api/production/crusher/split-time/$idMesin/$dateStr');

    final payload = {'hourStart': hourStart, 'outputJenisId': outputJenisId};

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
      throw Exception('Timeout split-time crusher ($idMesin)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] split-time crusher');

    final decoded = utf8.decode(res.bodyBytes);
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response split-time bukan JSON valid: $e');
    }

    if (res.statusCode == 200 || res.statusCode == 201) return body;

    final msg = (body['message'] as String?) ??
        'Gagal split-time crusher (HTTP ${res.statusCode})';
    throw Exception(msg);
  }

// -----------------------------
// DELETE INPUTS & PARTIALS
// -----------------------------
  /// DELETE /api/produksi/crusher/:noCrusherProduksi/inputs
  /// Body: { bb: [...], bbPartial: [...], bonggolan: [...] }
  ///
  /// Backend:
  /// - 200 => success (bisa dengan warning kalau ada notFound)
  /// - 404 => tidak ada data yang terhapus, tapi tetap response JSON yang rapi
  /// - 400 => request tidak valid (mis. tidak ada array yang berisi)
  /// - 500 => error server
  Future<Map<String, dynamic>> deleteInputsAndPartials(
    String noCrusherProduksi,
    Map<String, dynamic> payload,
  ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/crusher/$noCrusherProduksi/inputs');

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
      throw Exception('Timeout delete inputs ($noCrusherProduksi)');
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