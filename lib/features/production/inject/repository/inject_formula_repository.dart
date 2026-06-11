// lib/features/production/inject/repository/inject_formula_repository.dart

import '../../../../core/network/api_client.dart';
import '../model/inject_formula_model.dart';

class InjectFormulaRepository {
  final ApiClient _api;

  InjectFormulaRepository({ApiClient? api}) : _api = api ?? ApiClient();

  /// GET /api/production/inject/:noProduksi/formula-inputs
  Future<InjectFormulaData> fetch(String noProduksi) async {
    final body = await _api.getJson(
      '/api/production/inject/$noProduksi/formula-inputs',
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response formula tidak valid');
    return InjectFormulaData.fromJson(data);
  }
}
