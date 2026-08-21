import 'package:pps_tablet/core/network/api_client.dart';

import '../model/penjualan_header_model.dart';
import '../model/penjualan_detail_model.dart';

/// Wrapper `ApiClient` untuk seluruh endpoint `/api/penjualan`.
class PenjualanRepository {
  final ApiClient _api;

  PenjualanRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static const _base = '/api/penjualan';

  /// [status]: 'incomplete' (default, dipakai backend kalau tidak dikirim),
  /// 'complete', atau 'all'.
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (dateFrom != null)
        'dateFrom': dateFrom.toIso8601String().split('T').first,
      if (dateTo != null) 'dateTo': dateTo.toIso8601String().split('T').first,
      if (status != null) 'status': status,
    };
    final body = await _api.getJson(_base, query: qp);
    final dataList = (body['data'] ?? []) as List;
    final items = dataList
        .whereType<Map>()
        .map((e) => PenjualanHeader.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final totalPages = (body['meta']?['totalPages'] as num?)?.toInt() ?? 1;

    return {'items': items, 'totalPages': totalPages};
  }

  Future<PenjualanDetail> fetchDetail(String noBJJual) async {
    final body = await _api.getJson('$_base/$noBJJual');
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Data Penjualan tidak ditemukan');
    return PenjualanDetail.fromJson(data);
  }

  /// Backend memvalidasi kategori/jenis/kuota secara transaksional. Kalau
  /// pcs label melebihi sisa kebutuhan, backend TIDAK langsung menolak —
  /// mengembalikan `needsConfirmation: true` (tanpa mengubah data apapun)
  /// supaya UI bisa menawarkan pemecahan (partial) ke user. Panggil ulang
  /// dengan [confirmPartial]=true untuk benar-benar mengeksekusi partial.
  /// Return body mentah (bukan cuma `data`) supaya caller bisa cek
  /// `needsConfirmation` di level root.
  Future<Map<String, dynamic>> scan(
    String noBJJual,
    String noLabel, {
    bool confirmPartial = false,
  }) async {
    return _api.postJson(
      '$_base/$noBJJual/scan',
      body: {'noLabel': noLabel, 'confirmPartial': confirmPartial},
    );
  }
}
