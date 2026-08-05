import '../../../core/network/api_client.dart';
import '../../../core/services/user_session_storage.dart';
import '../model/trade_in_salesperson.dart';
import '../model/trade_in_transaction.dart';

class TradeInRepository {
  final ApiClient _api;

  TradeInRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<TradeInSalesPerson>> fetchSalesPersons() async {
    final body = await _api.getJson('/api/trade-in/master/salesperson');
    final dataList = (body['data'] ?? []) as List;
    return dataList
        .map(
          (e) => TradeInSalesPerson.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// Preview nomor penerimaan berikutnya — server tidak commit transaksi
  /// apapun, cuma intip nomor (rollback), jadi aman dipanggil berkali-kali.
  Future<String> fetchNextNo() async {
    final body = await _api.getJson('/api/trade-in/next-no');
    final data = body['data'] as Map<String, dynamic>?;
    return data?['noPenerimaan']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? filter,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (filter != null && filter.trim().isNotEmpty) 'filter': filter.trim(),
    };
    final body = await _api.getJson('/api/trade-in', query: qp);
    final dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map(
          (e) => TradeInTransaction.fromJson(Map<String, dynamic>.from(e as Map)),
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

  Future<String> create({
    required String supplier,
    required String salesPersonCode,
    required String jenis,
    required String tanggal,
    required int idReject,
    required String berat,
  }) async {
    final createBy = await UserSessionStorage.getUsername();
    final body = await _api.postJson(
      '/api/trade-in',
      body: {
        'supplier': supplier,
        'salesPersonCode': salesPersonCode,
        'jenis': jenis,
        'tanggal': tanggal,
        'createBy': createBy,
        'reject': {'idReject': idReject, 'berat': berat, 'noReject': ''},
      },
    );
    final data = body['data'] as Map<String, dynamic>?;
    return data?['noPenerimaan']?.toString() ?? '';
  }

  Future<void> delete(String noPenerimaan) async {
    await _api.deleteJson('/api/trade-in/${Uri.encodeComponent(noPenerimaan)}');
  }
}
