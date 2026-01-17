// lib/features/shared/return_production/return_production_repository.dart
import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/return_production_model.dart';

class ReturnProductionRepository {
  final ApiClient api;

  ReturnProductionRepository({ApiClient? api}) : api = api ?? ApiClient();

  // =========================
  //  GET BY DATE
  //  GET /api/production/return/:date (YYYY-MM-DD)
  // =========================
  Future<List<ReturnProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    final Map<String, dynamic> body =
    await api.getJson('/api/production/return/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => ReturnProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  //  PAGINATED LIST
  //  GET /api/production/return?page=&pageSize=&search=&dateFrom=&dateTo=
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? search,
    String? noRetur, // optional alias like sortir reject pattern
    String? dateFrom, // optional: 'yyyy-MM-dd'
    String? dateTo, // optional: 'yyyy-MM-dd'
  }) async {
    final String? effectiveSearch =
    (noRetur != null && noRetur.trim().isNotEmpty)
        ? noRetur.trim()
        : (search != null && search.trim().isNotEmpty ? search.trim() : null);

    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (effectiveSearch != null) 'search': effectiveSearch,
      if (dateFrom != null && dateFrom.trim().isNotEmpty) 'dateFrom': dateFrom,
      if (dateTo != null && dateTo.trim().isNotEmpty) 'dateTo': dateTo,
    };

    final body = await api.getJson('/api/production/return', query: qp);

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => ReturnProduction.fromJson(e as Map<String, dynamic>))
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
        '✅ Return parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items, // List<ReturnProduction>
      'page': currentPage, // int
      'totalPages': totalPages, // int
      'total': totalData, // int
    };
  }

  /// Convenience if you only need list for a given page
  Future<List<ReturnProduction>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    String? noRetur,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final r = await fetchAll(
      page: page,
      pageSize: pageSize,
      search: search,
      noRetur: noRetur,
      dateFrom: dateFrom == null ? null : toDbDateString(dateFrom),
      dateTo: dateTo == null ? null : toDbDateString(dateTo),
    );
    return (r['items'] as List<ReturnProduction>);
  }

  // =========================
  //  CREATE (POST)
  //  POST /api/production/return
  // =========================
  Future<ReturnProduction> createReturn({
    required DateTime tanggal,
    required int idPembeli,
    String? invoice,
    String? noBJSortir,
  }) async {
    final payload = <String, dynamic>{
      'tanggal': toDbDateString(tanggal),
      'idPembeli': idPembeli,
      if (invoice != null && invoice.trim().isNotEmpty) 'invoice': invoice.trim(),
      if (noBJSortir != null && noBJSortir.trim().isNotEmpty)
        'noBJSortir': noBJSortir.trim(),
    };

    print('🧾 Return create payload: $payload');

    final body = await api.postJson('/api/production/return', body: payload);

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header return');
    }

    return ReturnProduction.fromJson(data);
  }

  // =========================
  //  UPDATE (PUT) - HEADER ONLY
  //  PUT /api/production/return/:noRetur
  //  req body format fixed:
  //  {
  //    "tanggal": "...",
  //    "invoice": "...",
  //    "idPembeli": 12,
  //    "noBJSortir": "J.000..."
  //  }
  // =========================
  Future<ReturnProduction> updateReturn({
    required String noRetur,
    DateTime? tanggal,
    String? invoice,
    int? idPembeli,
    String? noBJSortir,
  }) async {
    final payload = <String, dynamic>{};

    if (tanggal != null) payload['tanggal'] = toDbDateString(tanggal);
    if (invoice != null) payload['invoice'] = invoice; // allow '' if you want clear
    if (idPembeli != null) payload['idPembeli'] = idPembeli;
    if (noBJSortir != null) payload['noBJSortir'] = noBJSortir;

    print('🧾 Return update payload: $payload');

    final body = await api.putJson(
      '/api/production/return/$noRetur',
      body: payload,
    );

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header return');
    }

    return ReturnProduction.fromJson(data);
  }

  // =========================
  //  DELETE
  //  DELETE /api/production/return/:noRetur
  // =========================
  Future<void> deleteReturn(String noRetur) async {
    print('🗑️ Deleting return: $noRetur');

    try {
      await api.deleteJson('/api/production/return/$noRetur');
      print('✅ Return deleted successfully');
    } catch (e) {
      print('❌ Delete Return error: $e');

      if (e is ApiException) {
        if (e.responseBody != null && e.responseBody!.isNotEmpty) {
          try {
            final decoded = jsonDecode(e.responseBody!);
            final msg = decoded['message'] ??
                decoded['error'] ??
                decoded['msg'] ??
                'Gagal menghapus return';
            throw Exception(msg);
          } catch (_) {
            throw Exception(e.responseBody);
          }
        }
        throw Exception('Gagal menghapus return (${e.statusCode})');
      }

      rethrow;
    }
  }
}
