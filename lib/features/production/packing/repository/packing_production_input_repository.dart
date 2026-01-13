// lib/features/production/packing/repository/packing_production_input_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';

import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/models/cabinet_material_item.dart';

import '../model/packing_production_inputs_model.dart';

class PackingProductionInputRepository {
  final ApiClient api;

  PackingProductionInputRepository({ApiClient? apiClient})
      : api = apiClient ?? ApiClient();

  // cache inputs per NoPacking
  final Map<String, PackingProductionInputs> _inputsCache = {};

  // cache master cabinet material per warehouse
  final Map<int, List<CabinetMaterialItem>> _cabinetMasterCache = {};

  /* =============================
   * GET INPUTS
   * ============================= */

  static PackingProductionInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Response tidak valid: field data kosong');
    }
    return PackingProductionInputs.fromJson(data);
  }

  /// GET /api/production/packing/:noPacking/inputs
  Future<PackingProductionInputs> fetchInputs(
      String noPacking, {
        bool force = false,
      }) async {
    final key = noPacking.trim();
    if (key.isEmpty) throw ArgumentError('noPacking tidak boleh kosong');

    if (!force && _inputsCache.containsKey(key)) {
      return _inputsCache[key]!;
    }

    final path = '/api/production/packing/$key/inputs';

    final body = await api.getJson(path);
    final inputs = await compute(_parseInputs, body);

    _inputsCache[key] = inputs;
    return inputs;
  }

  void invalidateInputs(String noPacking) => _inputsCache.remove(noPacking);
  void clearInputsCache() => _inputsCache.clear();

  /* =============================
   * GET MASTER CABINET MATERIALS (MASTER + STOCK)
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
   * VALIDATE / LOOKUP LABEL (FWIP / dll)
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

  /// POST /api/production/packing/:noPacking/inputs
  ///
  /// Payload (samakan pola spanner):
  /// {
  ///   "furnitureWip": [{ "noFurnitureWip": "BB...." }],
  ///   "cabinetMaterial": [{ "idCabinetMaterial": 1, "jumlah": 10 }],
  ///   "furnitureWipPartialNew": [{ "noFurnitureWip": "BB....", "pcs": 5 }]
  /// }
  Future<Map<String, dynamic>> submitInputsAndPartials(
      String noPacking,
      Map<String, dynamic> payload,
      ) async {
    final key = noPacking.trim();
    if (key.isEmpty) throw ArgumentError('noPacking tidak boleh kosong');

    final path = '/api/production/packing/$key/inputs';

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

  /// DELETE /api/production/packing/:noPacking/inputs
  ///
  /// Payload (samakan):
  /// {
  ///   "furnitureWip": [{ "noFurnitureWip": "BB...." }],
  ///   "cabinetMaterial": [{ "idCabinetMaterial": 1 }],
  ///   "furnitureWipPartial": [{ "noFurnitureWipPartial": "BC...." }]
  /// }
  Future<Map<String, dynamic>> deleteInputsAndPartials(
      String noPacking,
      Map<String, dynamic> payload,
      ) async {
    final key = noPacking.trim();
    if (key.isEmpty) throw ArgumentError('noPacking tidak boleh kosong');

    final path = '/api/production/packing/$key/inputs';

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
