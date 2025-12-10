// lib/features/packing_type/repository/reject_type_repository.dart

import '../../../../core/network/api_client.dart';
import '../model/packing_type_model.dart';

class PackingTypeRepository {
  final ApiClient api;

  PackingTypeRepository({required this.api});

  /// Backend returns only active (Enable = 1)
  /// GET /api/master/packing
  Future<List<PackingType>> fetchAllActive() async {
    final Map<String, dynamic> body =
    await api.getJson('/api/packing-type');

    final List data = (body['data'] ?? []) as List;

    return data
        .map((e) => PackingType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
