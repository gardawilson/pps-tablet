import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../model/gilingan_inputs_model.dart';

class GilinganProductionInputRepository {
  final ApiClient _api;

  GilinganProductionInputRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final Map<String, GilinganInputs> _inputsCache = {};

  /* =============================
   * GET INPUTS
   * ============================= */

  static GilinganInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return GilinganInputs.fromJson(data);
  }

  Future<GilinganInputs> fetchInputs(String noProduksi,
      {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noProduksi)) {
      return _inputsCache[noProduksi]!;
    }

    final path = '/api/production/gilingan/$noProduksi/inputs';

    final body = await _api.getJson(path);
    final inputs = await compute(_parseInputs, body);

    _inputsCache[noProduksi] = inputs;
    return inputs;
  }

  void invalidateInputs(String noProduksi) => _inputsCache.remove(noProduksi);
  void clearCache() => _inputsCache.clear();

  /* =============================
   * VALIDATE / LOOKUP LABEL
   * ============================= */

  /// GET /api/production/gilingan/validate-label/:labelCode
  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) throw ArgumentError('labelCode tidak boleh kosong');

    final path =
        '/api/production/gilingan/validate-label/${Uri.encodeComponent(code)}';

    try {
      final body = await _api.getJson(path);
      return ProductionLabelLookupResult.success(body);
    } on ApiException catch (e) {
      // ApiClient melempar untuk non-2xx. Kita mapping sesuai kebutuhan.
      if (e.statusCode == 404) {
        final parsed = _tryDecodeMap(e.responseBody);
        return ProductionLabelLookupResult.notFound(parsed);
      }

      final parsed = _tryDecodeMap(e.responseBody);
      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal lookup label (HTTP ${e.statusCode})';
      throw Exception(msg);
    }
  }

  /* =============================
   * POST SUBMIT INPUTS & PARTIALS
   * ============================= */

  /// POST /api/production/gilingan/:noProduksi/inputs
  Future<Map<String, dynamic>> submitInputsAndPartials(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final path = '/api/production/gilingan/$noProduksi/inputs';

    try {
      final body = await _api.postJson(path, body: payload);
      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);
      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal submit inputs (HTTP ${e.statusCode})';

      // Ikuti perilaku lama kamu:
      if (e.statusCode == 422) {
        throw Exception(msg.isNotEmpty ? msg : 'Beberapa data tidak valid');
      }
      if (e.statusCode == 400) {
        throw Exception(msg.isNotEmpty ? msg : 'Request tidak valid');
      }

      throw Exception(msg);
    }
  }

  /* =============================
   * DELETE INPUTS & PARTIALS
   * ============================= */

  /// DELETE /api/production/gilingan/:noProduksi/inputs
  ///
  /// Catatan: ApiClient akan throw untuk 404,
  /// sementara kamu mau 404 tetap return body (warning: tidak ada yang terhapus).
  Future<Map<String, dynamic>> deleteInputsAndPartials(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final path = '/api/production/gilingan/$noProduksi/inputs';

    try {
      final body = await _api.deleteJson(path, body: payload);
      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);

      // sama seperti broker: 404 -> tetap return untuk UI
      if (e.statusCode == 404) {
        return parsed;
      }

      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal delete inputs (HTTP ${e.statusCode})';

      if (e.statusCode == 400) {
        throw Exception(msg.isNotEmpty
            ? msg
            : 'Request delete inputs tidak valid');
      }

      throw Exception(msg);
    }
  }

  /* =============================
   * Helpers
   * ============================= */

  Map<String, dynamic> _tryDecodeMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      // fallback kalau body bukan JSON
      return <String, dynamic>{'message': raw};
    }
  }
}
