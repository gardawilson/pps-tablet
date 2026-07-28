import '../../../core/network/api_client.dart';
import '../model/retur_v2_pending_import.dart';
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

  Future<Map<String, dynamic>> fetchPendingImport({
    required int page,
    int pageSize = 20,
  }) async {
    final body = await _api.getJson(
      '/api/production/return/import-as-gsu-after',
      query: {'page': page, 'pageSize': pageSize},
    );
    final dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map(
          (e) => ReturV2PendingImportGroup.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
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
}
