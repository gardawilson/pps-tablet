// lib/features/reject_type/repository/reject_type_repository.dart
import '../../../../core/network/api_client.dart';
import '../model/reject_type_model.dart';

class RejectTypeRepository {
  final ApiClient api;

  RejectTypeRepository({required this.api});

  /// Backend returns only active (Enable = 1)
  /// GET /api/master/reject
  Future<List<RejectType>> fetchAllActive() async {
    final Map<String, dynamic> body =
    await api.getJson('/api/reject-type');
    // kalau di backend kamu mount-nya beda, samakan path-nya di sini

    final List data = (body['data'] ?? []) as List;

    return data
        .map((e) => RejectType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
