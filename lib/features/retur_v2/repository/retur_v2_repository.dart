import '../../../core/network/api_client.dart';
import '../model/retur_v2_output.dart';
import '../model/retur_v2_transaction.dart';

class ReturV2Repository {
  final ApiClient _api;

  ReturV2Repository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? search,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final body = await _api.getJson('/api/production/return', query: qp);
    final dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map(
          (e) => ReturV2Transaction.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final totalPages = int.tryParse('${meta['totalPages'] ?? 1}') ?? 1;
    final totalData = int.tryParse('${body['totalData'] ?? 0}') ?? 0;

    return {
      'items': items,
      'page': page,
      'totalPages': totalPages,
      'total': totalData,
    };
  }

  Future<List<ReturV2Output>> fetchFurnitureWipOutputs(String noRetur) async {
    final body = await _api.getJson(
      '/api/production/return/$noRetur/outputs/furniture-wip',
    );
    final dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => ReturV2Output.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<ReturV2Output>> fetchBarangJadiOutputs(String noRetur) async {
    final body = await _api.getJson(
      '/api/production/return/$noRetur/outputs/barang-jadi',
    );
    final dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => ReturV2Output.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
