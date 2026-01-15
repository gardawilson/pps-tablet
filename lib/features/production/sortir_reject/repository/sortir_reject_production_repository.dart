// lib/features/shared/sortir_reject_production/sortir_reject_production_repository.dart
import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/sortir_reject_production_model.dart';

class SortirRejectProductionRepository {
  final ApiClient api;

  SortirRejectProductionRepository({ApiClient? api}) : api = api ?? ApiClient();

  // =========================
  //  GET BY DATE
  //  GET /api/production/sortir-reject/:date (YYYY-MM-DD)
  // =========================
  Future<List<SortirRejectProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    final Map<String, dynamic> body =
    await api.getJson('/api/production/sortir-reject/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => SortirRejectProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  //  PAGINATED LIST
  //  GET /api/production/sortir-reject?page=&pageSize=&search=&dateFrom=&dateTo=
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? search,
    String? noBJSortir,
    String? dateFrom, // optional: 'yyyy-MM-dd'
    String? dateTo, // optional: 'yyyy-MM-dd'
  }) async {
    final String? effectiveSearch =
    (noBJSortir != null && noBJSortir.trim().isNotEmpty)
        ? noBJSortir.trim()
        : (search != null && search.trim().isNotEmpty ? search.trim() : null);

    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (effectiveSearch != null) 'search': effectiveSearch,
      if (dateFrom != null && dateFrom.trim().isNotEmpty) 'dateFrom': dateFrom,
      if (dateTo != null && dateTo.trim().isNotEmpty) 'dateTo': dateTo,
    };

    final body =
    await api.getJson('/api/production/sortir-reject', query: qp);

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => SortirRejectProduction.fromJson(e as Map<String, dynamic>))
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

    print(
        '✅ SortirReject parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items, // List<SortirRejectProduction>
      'page': currentPage, // int
      'totalPages': totalPages, // int
      'total': totalData, // int
    };
  }

  /// Convenience if you only need list for a given page
  Future<List<SortirRejectProduction>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    String? noBJSortir,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final r = await fetchAll(
      page: page,
      pageSize: pageSize,
      search: search,
      noBJSortir: noBJSortir,
      dateFrom: dateFrom == null ? null : toDbDateString(dateFrom),
      dateTo: dateTo == null ? null : toDbDateString(dateTo),
    );
    return (r['items'] as List<SortirRejectProduction>);
  }

  // =========================
  //  CREATE (POST)
  //  POST /api/production/sortir-reject
  // =========================
  Future<SortirRejectProduction> createSortirReject({
    required DateTime tglBJSortir,
    required int idWarehouse,
    int? idUsername, // optional, backend default from token jika null
  }) async {
    final payload = <String, dynamic>{
      'tglBJSortir': toDbDateString(tglBJSortir),
      'idWarehouse': idWarehouse,
      if (idUsername != null) 'idUsername': idUsername,
    };

    print('🧾 SortirReject create payload: $payload');

    final body =
    await api.postJson('/api/production/sortir-reject', body: payload);

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header sortir reject');
    }

    return SortirRejectProduction.fromJson(data);
  }

  // =========================
  //  UPDATE (PUT)
  //  PUT /api/production/sortir-reject/:noBJSortir
  //  Partial update (send only changed fields)
  // =========================
  Future<SortirRejectProduction> updateSortirReject({
    required String noBJSortir,
    DateTime? tglBJSortir,
    int? idWarehouse,
    int? idUsername, // kalau memang mau allow (BE kamu masih nerima)
  }) async {
    final payload = <String, dynamic>{};

    if (tglBJSortir != null) {
      payload['tglBJSortir'] = toDbDateString(tglBJSortir);
    }
    if (idWarehouse != null) payload['idWarehouse'] = idWarehouse;

    // NOTE: idealnya idUsername tidak diedit, tapi BE kamu menerima -> optional
    if (idUsername != null) payload['idUsername'] = idUsername;

    print('🧾 SortirReject update payload: $payload');

    final body = await api.putJson(
      '/api/production/sortir-reject/$noBJSortir',
      body: payload,
    );

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header sortir reject');
    }

    return SortirRejectProduction.fromJson(data);
  }

  // =========================
  //  DELETE
  //  DELETE /api/production/sortir-reject/:noBJSortir
  // =========================
  Future<void> deleteSortirReject(String noBJSortir) async {
    print('🗑️ Deleting sortir reject: $noBJSortir');

    try {
      await api.deleteJson('/api/production/sortir-reject/$noBJSortir');
      print('✅ SortirReject deleted successfully');
    } catch (e) {
      print('❌ Delete SortirReject error: $e');

      if (e is ApiException) {
        if (e.responseBody != null && e.responseBody!.isNotEmpty) {
          try {
            final decoded = jsonDecode(e.responseBody!);
            final msg = decoded['message'] ??
                decoded['error'] ??
                decoded['msg'] ??
                'Gagal menghapus sortir reject';
            throw Exception(msg);
          } catch (_) {
            throw Exception(e.responseBody);
          }
        }
        throw Exception('Gagal menghapus sortir reject (${e.statusCode})');
      }

      rethrow;
    }
  }
}
