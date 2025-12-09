import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/packing_production_model.dart';

class PackingProductionRepository {
  final ApiClient api;

  PackingProductionRepository({required this.api});

  /// Get PackingProduksi_h by date
  /// Backend: GET /api/production/packing/:date (YYYY-MM-DD)
  Future<List<PackingProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    final Map<String, dynamic> body =
    await api.getJson('/api/production/packing/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => PackingProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
