import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';


import '../../production/shared/models/production_label_lookup_result.dart';
import '../model/bj_jual_inputs_model.dart';

class BJJualInputRepository {
  final ApiClient api;

  BJJualInputRepository({ApiClient? apiClient}) : api = apiClient ?? ApiClient();

  // cache inputs per NoBJJual
  final Map<String, BJJualInputs> _inputsCache = {};

  // cache master cabinet material per warehouse (kalau BJ Jual juga butuh)
  final Map<int, List<CabinetMaterialItem>> _cabinetMasterCache = {};

  /* =============================
   * GET INPUTS
   * ============================= */

  static BJJualInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Response tidak valid: field data kosong');
    }
    return BJJualInputs.fromJson(data);
  }

  /// GET /api/production/bj-jual/:noBJJual/inputs
  ///
  /// Expected shape:
  /// {
  ///   barangJadi: [...],
  ///   furnitureWip: [...],
  ///   cabinetMaterial: [...],
  ///   summary: { barangJadi: n, furnitureWip: n, cabinetMaterial: n }
  /// }
  Future<BJJualInputs> fetchInputs(
      String noBJJual, {
        bool force = false,
      }) async {
    final key = noBJJual.trim();
    if (key.isEmpty) throw ArgumentError('noBJJual tidak boleh kosong');

    if (!force && _inputsCache.containsKey(key)) {
      return _inputsCache[key]!;
    }

    final path = '/api/bj-jual/$key/inputs';

    final body = await api.getJson(path);
    final inputs = await compute(_parseInputs, body);

    _inputsCache[key] = inputs;
    return inputs;
  }

  void invalidateInputs(String noBJJual) => _inputsCache.remove(noBJJual);
  void clearInputsCache() => _inputsCache.clear();

  /* =============================
   * GET MASTER CABINET MATERIALS (optional)
   * ============================= */

  static List<CabinetMaterialItem> _parseCabinetMaterials(
      Map<String, dynamic> body,
      ) {
    final data = body['data'];

    if (data == null) return <CabinetMaterialItem>[];
    if (data is! List) {
      throw const FormatException('Response tidak valid: field data bukan List');
    }

    return data
        .whereType<Map>()
        .map((e) => CabinetMaterialItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /api/mst-furniture-material/cabinet-materials?idWarehouse=5
  /// (dipakai juga di Packing; kalau BJ Jual butuh material master + stock)
  Future<List<CabinetMaterialItem>> fetchMasterCabinetMaterials({
    required int idWarehouse,
    bool force = false,
  }) async {
    if (!force && _cabinetMasterCache.containsKey(idWarehouse)) {
      return _cabinetMasterCache[idWarehouse]!;
    }

    final path = '/api/mst-furniture-material/cabinet-materials';

    final body = await api.getJson(path, query: {
      'idWarehouse': idWarehouse.toString(),
    });

    final items = await compute(_parseCabinetMaterials, body);

    _cabinetMasterCache[idWarehouse] = items;
    return items;
  }

  void invalidateCabinetMaster(int idWarehouse) =>
      _cabinetMasterCache.remove(idWarehouse);

  void clearCabinetMasterCache() => _cabinetMasterCache.clear();

  /* =============================
   * VALIDATE / LOOKUP LABEL (shared)
   * ============================= */

  /// Reuse endpoint shared:
  /// GET /api/production/lookup-label/:labelCode
  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) throw ArgumentError('labelCode tidak boleh kosong');

    final path = '/api/production/lookup-label/${Uri.encodeComponent(code)}';

    try {
      final body = await api.getJson(path);
      return ProductionLabelLookupResult.success(body);
    } on ApiException catch (e) {
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

  /// POST /api/production/bj-jual/:noBJJual/inputs
  ///
  /// Payload suggestion (samakan pola spanner/packing):
  /// {
  ///   "barangJadi": [{ "noBJ": "BJ...." }],
  ///   "furnitureWip": [{ "noFurnitureWip": "BB...." }],
  ///   "cabinetMaterial": [{ "idCabinetMaterial": 1, "jumlah": 10 }],
  ///
  ///   "barangJadiPartialNew": [{ "noBJ": "BJ....", "pcs": 5 }],
  ///   "furnitureWipPartialNew": [{ "noFurnitureWip": "BB....", "pcs": 5 }]
  /// }
  Future<Map<String, dynamic>> submitInputsAndPartials(
      String noBJJual,
      Map<String, dynamic> payload,
      ) async {
    final key = noBJJual.trim();
    if (key.isEmpty) throw ArgumentError('noBJJual tidak boleh kosong');

    final path = '/api/bj-jual/$key/inputs';

    try {
      final body = await api.postJson(path, body: payload);

      // setelah submit sukses, invalidate cache inputs agar fetch ulang ambil data terbaru
      invalidateInputs(key);

      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);
      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal submit inputs (HTTP ${e.statusCode})';

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

  /// DELETE /api/production/bj-jual/:noBJJual/inputs
  ///
  /// Payload suggestion:
  /// {
  ///   "barangJadi": [{ "noBJ": "BJ...." }],
  ///   "barangJadiPartial": [{ "noBJPartial": "BJ...." }],
  ///
  ///   "furnitureWip": [{ "noFurnitureWip": "BB...." }],
  ///   "furnitureWipPartial": [{ "noFurnitureWipPartial": "BC...." }],
  ///
  ///   "cabinetMaterial": [{ "idCabinetMaterial": 1 }]
  /// }
  Future<Map<String, dynamic>> deleteInputsAndPartials(
      String noBJJual,
      Map<String, dynamic> payload,
      ) async {
    final key = noBJJual.trim();
    if (key.isEmpty) throw ArgumentError('noBJJual tidak boleh kosong');

    final path = '/api/bj-jual/$key/inputs';

    try {
      final body = await api.deleteJson(path, body: payload);

      // setelah delete sukses, invalidate cache inputs
      invalidateInputs(key);

      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);

      // 404 -> tetap return untuk UI (show warning)
      if (e.statusCode == 404) {
        return parsed;
      }

      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal delete inputs (HTTP ${e.statusCode})';

      if (e.statusCode == 400) {
        throw Exception(
          msg.isNotEmpty ? msg : 'Request delete inputs tidak valid',
        );
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
      return <String, dynamic>{'message': raw};
    }
  }
}
