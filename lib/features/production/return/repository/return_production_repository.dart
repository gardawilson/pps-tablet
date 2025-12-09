// lib/features/shared/return_production/packing_production_repository.dart
import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';

import '../model/return_production_model.dart';

class ReturnProductionRepository {
  final ApiClient api;

  ReturnProductionRepository({required this.api});

  /// Get BJRetur_h by date
  /// Backend: GET /api/production/return/:date (YYYY-MM-DD)
  Future<List<ReturnProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    // Pakai ApiClient
    final Map<String, dynamic> body =
    await api.getJson('/api/production/return/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => ReturnProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
