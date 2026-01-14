// lib/features/shared/bj_jual/bj_jual_repository.dart
import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/bj_jual_model.dart';

class BJJualRepository {
  final ApiClient api;

  BJJualRepository({ApiClient? api}) : api = api ?? ApiClient();

  // ==========================================
  //  PAGINATED LIST
  //  GET /api/production/bj-jual?page=&pageSize=&search=&dateFrom=&dateTo=
  //  return: { data, meta, totalData }
  //  repo output: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? search,
    String? noBJJual,
    String? dateFrom, // optional: 'yyyy-MM-dd'
    String? dateTo,   // optional: 'yyyy-MM-dd'
  }) async {
    final String? effectiveSearch =
    (noBJJual != null && noBJJual.trim().isNotEmpty)
        ? noBJJual.trim()
        : (search != null && search.trim().isNotEmpty ? search.trim() : null);

    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (effectiveSearch != null) 'search': effectiveSearch,
      if (dateFrom != null && dateFrom.trim().isNotEmpty) 'dateFrom': dateFrom,
      if (dateTo != null && dateTo.trim().isNotEmpty) 'dateTo': dateTo,
    };

    final body = await api.getJson('/api/bj-jual', query: qp);

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => BJJual.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;

    final currentPage = (meta['page'] ?? page) is int
        ? (meta['page'] ?? page) as int
        : int.tryParse('${meta['page'] ?? page}') ?? page;

    final totalPages = (meta['totalPages'] ?? 1) is int
        ? (meta['totalPages'] ?? 1) as int
        : int.tryParse('${meta['totalPages'] ?? 1}') ?? 1;

    final totalData = (body['totalData'] ?? meta['total'] ?? 0) is int
        ? (body['totalData'] ?? meta['total'] ?? 0) as int
        : int.tryParse('${body['totalData'] ?? meta['total'] ?? 0}') ?? 0;

    print('✅ BJJual parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items,       // List<BJJual>
      'page': currentPage,  // int
      'totalPages': totalPages, // int
      'total': totalData,   // int
    };
  }

  /// Convenience if you only need list for a given page
  Future<List<BJJual>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    String? noBJJual,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final r = await fetchAll(
      page: page,
      pageSize: pageSize,
      search: search,
      noBJJual: noBJJual,
      dateFrom: dateFrom == null ? null : toDbDateString(dateFrom),
      dateTo: dateTo == null ? null : toDbDateString(dateTo),
    );
    return (r['items'] as List<BJJual>);
  }

  // =========================
  //  CREATE (POST)
  //  POST /api/production/bj-jual
  //  required: tanggal, idPembeli
  // =========================
  Future<BJJual> createBJJual({
    required DateTime tanggal,
    required int idPembeli,
    String? remark,
  }) async {
    final payload = <String, dynamic>{
      'tanggal': toDbDateString(tanggal),
      'idPembeli': idPembeli,
      if (remark != null) 'remark': remark,
    };

    print('🧾 BJJual create payload: $payload');

    final body = await api.postJson('/api/bj-jual', body: payload);

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header BJ Jual');
    }

    return BJJual.fromJson(data);
  }

  // =========================
  //  UPDATE (PUT)
  //  PUT /api/production/bj-jual/:noBJJual
  //  Partial update (send only changed fields)
  // =========================
  Future<BJJual> updateBJJual({
    required String noBJJual,
    DateTime? tanggal,
    int? idPembeli,
    String? remark,
  }) async {
    final payload = <String, dynamic>{};

    if (tanggal != null) payload['tanggal'] = toDbDateString(tanggal);
    if (idPembeli != null) payload['idPembeli'] = idPembeli;
    if (remark != null) payload['remark'] = remark;

    print('🧾 BJJual update payload: $payload');

    final body = await api.putJson(
      '/api/bj-jual/$noBJJual',
      body: payload,
    );

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header BJ Jual');
    }

    return BJJual.fromJson(data);
  }

  // =========================
  //  DELETE
  //  DELETE /api/production/bj-jual/:noBJJual
  // =========================
  Future<void> deleteBJJual(String noBJJual) async {
    print('🗑️ Deleting BJ Jual: $noBJJual');

    try {
      await api.deleteJson('/api/bj-jual/$noBJJual');
      print('✅ BJ Jual deleted successfully');
    } catch (e) {
      print('❌ Delete BJ Jual error: $e');

      if (e is ApiException) {
        if (e.responseBody != null && e.responseBody!.isNotEmpty) {
          try {
            final decoded = jsonDecode(e.responseBody!);
            final msg = decoded['message'] ??
                decoded['error'] ??
                decoded['msg'] ??
                'Gagal menghapus BJ Jual';
            throw Exception(msg);
          } catch (_) {
            throw Exception(e.responseBody);
          }
        }
        throw Exception('Gagal menghapus BJ Jual (${e.statusCode})');
      }

      rethrow;
    }
  }
}
