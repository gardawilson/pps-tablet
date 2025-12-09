// lib/features/shared/key_fitting_production/packing_production_repository.dart

import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/key_fitting_production_model.dart';

class KeyFittingProductionRepository {
  final ApiClient api;

  KeyFittingProductionRepository({required this.api});

  /// Get PasangKunci_h (Key Fitting production) by date
  /// Backend: GET /api/production/key-fitting/:date (YYYY-MM-DD)
  Future<List<KeyFittingProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    final Map<String, dynamic> body =
    await api.getJson('/api/production/key-fitting/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => KeyFittingProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
