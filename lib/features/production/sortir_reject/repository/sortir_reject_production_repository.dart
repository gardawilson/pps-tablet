// lib/features/shared/sortir_reject_production/sortir_reject_production_repository.dart

import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';

import '../model/sortir_reject_production_model.dart';

class SortirRejectProductionRepository {
  final ApiClient api;

  SortirRejectProductionRepository({required this.api});

  /// Get BJSortirReject_h by date
  /// Backend: GET /api/sortir-reject/:date (YYYY-MM-DD)
  Future<List<SortirRejectProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    // Pakai ApiClient
    final Map<String, dynamic> body =
    await api.getJson('/api/production/sortir-reject/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) =>
        SortirRejectProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
