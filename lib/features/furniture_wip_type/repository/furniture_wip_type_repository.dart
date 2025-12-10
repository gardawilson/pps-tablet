// lib/features/furniture_wip_type/repository/reject_type_repository.dart
import '../../../../core/network/api_client.dart';
import '../model/furniture_wip_type_model.dart';

class FurnitureWipTypeRepository {
  final ApiClient api;

  FurnitureWipTypeRepository({required this.api});

  /// Backend returns only active (Enable = 1)
  /// GET /api/master/furniture-wip-types
  Future<List<FurnitureWipType>> fetchAllActive() async {
    final Map<String, dynamic> body =
    await api.getJson('/api/furniture-wip-type');

    final List data = (body['data'] ?? []) as List;

    return data
        .map((e) => FurnitureWipType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
