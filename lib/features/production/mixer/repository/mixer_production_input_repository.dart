// lib/features/production/mixer/repository/mixer_production_input_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../model/mixer_inputs_model.dart';

class MixerProductionInputRepository {
  final ApiClient _api;

  MixerProductionInputRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final Map<String, MixerInputs> _inputsCache = {};

  /* =============================
   * GET INPUTS
   * ============================= */

  static MixerInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return MixerInputs.fromJson(data);
  }

  Future<MixerInputs> fetchInputs(String noProduksi,
      {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noProduksi)) {
      return _inputsCache[noProduksi]!;
    }

    final path = '/api/production/mixer/$noProduksi/inputs';

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

  /// GET /api/production/mixer/validate-label/:labelCode
  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) throw ArgumentError('labelCode tidak boleh kosong');

    final path =
        '/api/production/mixer/validate-label/${Uri.encodeComponent(code)}';

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

  /// POST /api/production/mixer/:noProduksi/inputs
  ///
  /// Payload structure:
  /// {
  ///   "broker": [{"noBroker": "D.xxx", "noSak": 1}],
  ///   "bb": [{"noBahanBaku": "A.xxx-1", "noPallet": 1, "noSak": 1}],
  ///   "gilingan": [{"noGilingan": "V.xxx"}],
  ///   "mixer": [{"noMixer": "H.xxx", "noSak": 1}],
  ///   "bbPartialNew": [{"noBahanBaku": "A.xxx-1", "noPallet": 1, "noSak": 1, "berat": 25.5}],
  ///   "brokerPartialNew": [{"noBroker": "D.xxx", "noSak": 1, "berat": 30.0}],
  ///   "gilinganPartialNew": [{"noGilingan": "V.xxx", "berat": 20.0}],
  ///   "mixerPartialNew": [{"noMixer": "H.xxx", "noSak": 1, "berat": 50.0}]
  /// }
  Future<Map<String, dynamic>> submitInputsAndPartials(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final path = '/api/production/mixer/$noProduksi/inputs';

    try {
      final body = await _api.postJson(path, body: payload);
      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);
      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal submit inputs (HTTP ${e.statusCode})';

      // Handle validation errors
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

  /// DELETE /api/production/mixer/:noProduksi/inputs
  ///
  /// Payload structure:
  /// {
  ///   "broker": [{"noBroker": "D.xxx", "noSak": 1}],
  ///   "bb": [{"noBahanBaku": "A.xxx-1", "noPallet": 1, "noSak": 1}],
  ///   "gilingan": [{"noGilingan": "V.xxx"}],
  ///   "mixer": [{"noMixer": "H.xxx", "noSak": 1}],
  ///   "bbPartial": [{"noBBPartial": "P.xxxxxxxxxx"}],
  ///   "brokerPartial": [{"noBrokerPartial": "Q.xxxxxxxxxx"}],
  ///   "gilinganPartial": [{"noGilinganPartial": "Y.xxxxxxxxxx"}],
  ///   "mixerPartial": [{"noMixerPartial": "T.xxxxxxxxxx"}]
  /// }
  ///
  /// Catatan: ApiClient akan throw untuk 404,
  /// sementara kamu mau 404 tetap return body (warning: tidak ada yang terhapus).
  Future<Map<String, dynamic>> deleteInputsAndPartials(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final path = '/api/production/mixer/$noProduksi/inputs';

    try {
      final body = await _api.deleteJson(path, body: payload);
      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);

      // 404 -> tetap return untuk UI (show warning to user)
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