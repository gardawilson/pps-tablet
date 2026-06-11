// lib/features/production/inject/repository/inject_validate_label_repository.dart

import '../../../../core/network/api_client.dart';
import '../model/inject_validate_label_model.dart';

class InjectValidateLabelRepository {
  final ApiClient _api;

  InjectValidateLabelRepository({ApiClient? api}) : _api = api ?? ApiClient();

  /// GET /api/production/inject/:noProduksi/validate-label/:labelCode
  Future<InjectValidateLabelResult> validate(
    String noProduksi,
    String labelCode,
  ) async {
    final body = await _api.getJson(
      '/api/production/inject/$noProduksi/validate-label/$labelCode',
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response validasi label tidak valid');
    return InjectValidateLabelResult.fromJson(data);
  }
}
