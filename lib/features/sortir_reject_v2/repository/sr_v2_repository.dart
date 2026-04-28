import '../../../core/network/api_client.dart';
import '../model/sr_v2_label_info.dart';
import '../model/sr_v2_transaction.dart';

class SrV2Repository {
  final ApiClient _api;

  SrV2Repository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<SrV2LabelInfo> fetchLabelInfo(String labelCode) async {
    final body = await _api.getJson('/api/sortir-reject-v2/label/$labelCode');
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response tidak mengandung data label');
    return SrV2LabelInfo.fromJson(data);
  }

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
    final body = await _api.getJson('/api/sortir-reject-v2', query: qp);
    final dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map(
          (e) => SrV2Transaction.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    final totalData = body['total'] is int
        ? body['total'] as int
        : int.tryParse(body['total']?.toString() ?? '0') ?? 0;
    final ps = body['pageSize'] is int ? body['pageSize'] as int : pageSize;
    final totalPages = ps > 0 ? ((totalData + ps - 1) ~/ ps) : 1;

    return {
      'items': items,
      'page': page,
      'totalPages': totalPages,
      'total': totalData,
    };
  }

  Future<SrV2Transaction> fetchDetail(String noSortir) async {
    final body = await _api.getJson('/api/sortir-reject-v2/$noSortir');
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null)
      throw Exception('Response tidak mengandung data transaksi');
    return SrV2Transaction.fromJson(data);
  }

  Future<SrV2Transaction> submit({
    required int idWarehouse,
    required List<String> inputs,
    required List<Map<String, dynamic>> outputs,
  }) async {
    final reqBody = <String, dynamic>{
      'idWarehouse': idWarehouse,
      'inputs': inputs,
      'outputs': outputs,
    };
    final jsonResp = await _api.postJson(
      '/api/sortir-reject-v2',
      body: reqBody,
    );
    final data = jsonResp['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response tidak mengandung data');
    return SrV2Transaction.fromJson(data);
  }
}
