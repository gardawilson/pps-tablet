// lib/features/shared/hot_stamp_production/packing_production_repository.dart

import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/hot_stamp_production_model.dart';

class HotStampProductionRepository {
  final ApiClient api;

  HotStampProductionRepository({required this.api});

  /// Get HotStamping_h by date
  /// Backend: GET /api/production/hot-stamping/:date (YYYY-MM-DD)
  Future<List<HotStampProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    final Map<String, dynamic> body =
    await api.getJson('/api/production/hot-stamp/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => HotStampProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
