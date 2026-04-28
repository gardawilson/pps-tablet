import '../../../core/network/api_client.dart';
import '../model/mst_barang_jadi_model.dart';

class MstBarangJadiRepository {
  final ApiClient _api;

  MstBarangJadiRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  Future<List<MstBarangJadi>> fetchAll({
    String search = '',
    int page = 1,
    int pageSize = 3000,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    final body = await _api.getJson('/api/mst-barang-jadi', query: qp);
    final dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => MstBarangJadi.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
