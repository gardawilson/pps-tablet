// lib/features/shared/inject_production/packing_production_repository.dart

import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

import '../model/inject_production_model.dart';
import '../model/furniture_wip_by_inject_production_model.dart';
import '../model/packing_by_inject_production_model.dart';

class InjectProductionRepository {
  final ApiClient api;

  InjectProductionRepository({required this.api});

  /// 🔹 Fetch InjectProduksi_h by date (YYYY-MM-DD)
  /// Backend: GET /api/production/inject/:date
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "data": [
  ///     { ... InjectProduksi_h fields ... },
  ///     ...
  ///   ]
  /// }
  Future<List<InjectProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // YYYY-MM-DD

    final Map<String, dynamic> body =
    await api.getJson('/api/production/inject/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map(
          (e) => InjectProduction.fromJson(e as Map<String, dynamic>),
    )
        .toList();
  }

  /// 🔹 Fetch FurnitureWIP kandidat by NoProduksi Inject
  ///
  /// Backend: GET /api/production/inject/furniture-wip/:noProduksi
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "beratProdukHasilTimbang": 123.45,   // bisa null
  ///     "items": [
  ///       { "IdFurnitureWIP": 1, "NamaFurnitureWIP": "XXX" },
  ///       ...
  ///     ]
  ///   },
  ///   "meta": { "noProduksi": "S.0000..." }
  /// }
  Future<FurnitureWipByInjectResult>
  fetchFurnitureWipByInjectProduction(String noProduksi) async {
    final encodedNo = Uri.encodeComponent(noProduksi);

    try {
      final Map<String, dynamic> body = await api.getJson(
        '/api/production/inject/furniture-wip/$encodedNo',
      );

      // Normal (200 OK)
      return FurnitureWipByInjectResult.fromEnvelope(body);
    } on ApiException catch (e) {
      // ✅ 404 = "tidak ada data", jangan dianggap error
      if (e.statusCode == 404) {
        return const FurnitureWipByInjectResult(
          beratProdukHasilTimbang: null,
          items: <FurnitureWipByInjectItem>[],
        );
      }

      // Status lain (500, 401, dll) tetap error
      rethrow;
    }
  }


  /// 🔹 Fetch Packing (BarangJadi) kandidat by NoProduksi Inject
  ///
  /// Backend: GET /api/production/inject/packing/:noProduksi
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "beratProdukHasilTimbang": 123.45,   // bisa null
  ///     "items": [
  ///       { "IdBJ": 10, "NamaBJ": "Produk A" },
  ///       ...
  ///     ]
  ///   },
  ///   "meta": { "noProduksi": "S.0000..." }
  /// }
  Future<PackingByInjectResult> fetchPackingByInjectProduction(
      String noProduksi,
      ) async {
    final encodedNo = Uri.encodeComponent(noProduksi);

    try {
      final Map<String, dynamic> body = await api.getJson(
        '/api/production/inject/packing/$encodedNo',
      );

      return PackingByInjectResult.fromEnvelope(body);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const PackingByInjectResult(
          beratProdukHasilTimbang: null,
          items: <PackingByInjectItem>[],
        );
      }
      rethrow;
    }
  }

}
