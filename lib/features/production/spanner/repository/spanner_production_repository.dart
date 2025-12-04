import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/spanner_production_model.dart';


class SpannerProductionRepository {
  final ApiClient api;

  SpannerProductionRepository({required this.api});

  /// Get Spanner_h by date
  /// Backend: GET /api/production/spanner/:date (YYYY-MM-DD)
  Future<List<SpannerProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    final Map<String, dynamic> body =
    await api.getJson('/api/production/spanner/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => SpannerProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
