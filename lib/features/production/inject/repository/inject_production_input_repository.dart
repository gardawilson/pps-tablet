// lib/features/production/inject_production/repository/inject_production_input_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/models/cabinet_material_item.dart';
import '../model/inject_production_inputs_model.dart';

class InjectProductionInputRepository {
  final ApiClient api;

  InjectProductionInputRepository({ApiClient? apiClient})
      : api = apiClient ?? ApiClient();

  final Map<String, InjectProductionInputs> _inputsCache = {};

  // cache master cabinet material per warehouse
  final Map<int, List<CabinetMaterialItem>> _cabinetMasterCache = {};

  /* =============================
   * GET INPUTS (5 categories: Broker, Mixer, Gilingan, FWIP, Material)
   * ============================= */

  static InjectProductionInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return InjectProductionInputs.fromJson(data);
  }

  /// GET /api/production/inject/:noProduksi/inputs
  Future<InjectProductionInputs> fetchInputs(
      String noProduksi, {
        bool force = false,
      }) async {
    if (!force && _inputsCache.containsKey(noProduksi)) {
      return _inputsCache[noProduksi]!;
    }

    final path = '/api/production/inject/$noProduksi/inputs';

    final body = await api.getJson(path);
    final inputs = await compute(_parseInputs, body);

    _inputsCache[noProduksi] = inputs;
    return inputs;
  }

  void invalidateInputs(String noProduksi) => _inputsCache.remove(noProduksi);
  void clearCache() => _inputsCache.clear();

  /* =============================
   * GET MASTER CABINET MATERIALS (MASTER + STOCK)
   * ============================= */

  static List<CabinetMaterialItem> _parseCabinetMaterials(Map<String, dynamic> body) {
    final data = body['data'];

    if (data == null) return <CabinetMaterialItem>[];
    if (data is! List) {
      throw FormatException('Response tidak valid: field data bukan List');
    }

    return data
        .whereType<Map>()
        .map((e) => CabinetMaterialItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /api/mst-furniture-material/cabinet-materials?idWarehouse=X
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
   * VALIDATE / LOOKUP LABEL (MULTI-PREFIX: BB., D., H., V.)
   * ============================= */

  /// GET /api/production/inject/validate-label/:labelCode
  ///
  /// Supports multiple prefixes:
  /// - BB. -> FurnitureWIP (full) or FurnitureWIPPartial
  /// - D.  -> Broker_d (full or partial sisa)
  /// - H.  -> Mixer_d (full or partial sisa)
  /// - V.  -> Gilingan (full or partial sisa)
  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) throw ArgumentError('labelCode tidak boleh kosong');

    final path =
        '/api/production/inject/validate-label/${Uri.encodeComponent(code)}';

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
   * POST SUBMIT INPUTS & PARTIALS (UPSERT)
   * ============================= */

  /// POST /api/production/inject/:noProduksi/inputs
  ///
  /// Payload structure:
  /// {
  ///   // FULL inputs (existing labels to attach)
  ///   "broker": [{ "noBroker": "D.xxx", "noSak": 1 }],
  ///   "mixer": [{ "noMixer": "H.xxx", "noSak": 1 }],
  ///   "gilingan": [{ "noGilingan": "V.xxx" }],
  ///   "furnitureWip": [{ "noFurnitureWip": "BB.xxx" }],
  ///   "cabinetMaterial": [{ "idCabinetMaterial": 123, "pcs": 10 }],
  ///
  ///   // PARTIAL inputs (existing partial labels to attach)
  ///   "brokerPartial": [{ "noBrokerPartial": "Q.xxx" }],
  ///   "mixerPartial": [{ "noMixerPartial": "T.xxx" }],
  ///   "gilinganPartial": [{ "noGilinganPartial": "Y.xxx" }],
  ///   "furnitureWipPartial": [{ "noFurnitureWipPartial": "BC.xxx" }],
  ///
  ///   // NEW PARTIALS (create new partial from full label)
  ///   "brokerPartialNew": [{ "noBroker": "D.xxx", "noSak": 1, "berat": 5.5 }],
  ///   "mixerPartialNew": [{ "noMixer": "H.xxx", "noSak": 1, "berat": 10.2 }],
  ///   "gilinganPartialNew": [{ "noGilingan": "V.xxx", "berat": 8.0 }],
  ///   "furnitureWipPartialNew": [{ "noFurnitureWip": "BB.xxx", "pcs": 3 }]
  /// }
  Future<Map<String, dynamic>> submitInputsAndPartials(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final path = '/api/production/inject/$noProduksi/inputs';

    try {
      final body = await api.postJson(path, body: payload);

      // setelah submit sukses, invalidate cache inputs agar fetch ulang ambil data terbaru
      invalidateInputs(noProduksi);

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

  /// DELETE /api/production/inject/:noProduksi/inputs
  ///
  /// Payload structure (same keys as submit, but for deletion):
  /// {
  ///   "broker": [{ "noBroker": "D.xxx", "noSak": 1 }],
  ///   "mixer": [{ "noMixer": "H.xxx", "noSak": 1 }],
  ///   "gilingan": [{ "noGilingan": "V.xxx" }],
  ///   "furnitureWip": [{ "noFurnitureWip": "BB.xxx" }],
  ///   "cabinetMaterial": [{ "idCabinetMaterial": 123 }],
  ///
  ///   "brokerPartial": [{ "noBrokerPartial": "Q.xxx" }],
  ///   "mixerPartial": [{ "noMixerPartial": "T.xxx" }],
  ///   "gilinganPartial": [{ "noGilinganPartial": "Y.xxx" }],
  ///   "furnitureWipPartial": [{ "noFurnitureWipPartial": "BC.xxx" }]
  /// }
  Future<Map<String, dynamic>> deleteInputsAndPartials(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final path = '/api/production/inject/$noProduksi/inputs';

    try {
      final body = await api.deleteJson(path, body: payload);

      // setelah delete sukses, invalidate cache inputs
      invalidateInputs(noProduksi);

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
        throw Exception(msg.isNotEmpty ? msg : 'Request delete inputs tidak valid');
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