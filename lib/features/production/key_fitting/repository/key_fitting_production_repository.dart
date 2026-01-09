// lib/features/shared/key_fitting_production/packing_production_repository.dart
import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/key_fitting_production_model.dart';

class KeyFittingProductionRepository {
  final ApiClient api;

  KeyFittingProductionRepository({ApiClient? api})
      : api = api ?? ApiClient();

  /// Get PasangKunci_h (Key Fitting) by date
  /// Backend: GET /api/production/key-fitting/:date (YYYY-MM-DD)
  Future<List<KeyFittingProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    final Map<String, dynamic> body =
    await api.getJson('/api/production/key-fitting/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => KeyFittingProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  //  PAGINATED LIST
  //  GET /api/production/key-fitting
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? search,
    String? noProduksi,
  }) async {
    final String? effectiveSearch =
    (noProduksi != null && noProduksi.trim().isNotEmpty)
        ? noProduksi.trim()
        : (search != null && search.trim().isNotEmpty ? search.trim() : null);

    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (effectiveSearch != null) 'search': effectiveSearch,
    };

    final body = await api.getJson('/api/production/key-fitting', query: qp);

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => KeyFittingProduction.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final currentPage = (meta['page'] ?? page) as int;
    final totalPages = (meta['totalPages'] ?? 1) as int;
    final totalData = (body['totalData'] ?? meta['total'] ?? 0) as int;

    print(
        '✅ KeyFitting parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items, // List<KeyFittingProduction>
      'page': currentPage, // int
      'totalPages': totalPages, // int
      'total': totalData, // int
    };
  }

  /// Convenience jika hanya butuh list halaman tertentu
  Future<List<KeyFittingProduction>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    String? noProduksi,
  }) async {
    final r = await fetchAll(
      page: page,
      pageSize: pageSize,
      search: search,
      noProduksi: noProduksi,
    );
    return (r['items'] as List<KeyFittingProduction>);
  }

  // =========================
  //  CREATE (POST)
  //  POST /api/production/key-fitting
  //  jamKerja bisa int atau 'HH:mm-HH:mm'
  // =========================
  Future<KeyFittingProduction> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    required dynamic jamKerja, // int atau String 'HH:mm-HH:mm'
    required int shift,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    double? hourMeter,
  }) async {
    final tglStr = toDbDateString(tglProduksi);

    String _normalizeTime(String v) {
      final t = v.trim();
      if (t.isEmpty) return t;
      if (t.length == 5) return '$t:00'; // HH:mm -> HH:mm:00
      return t;
    }

    final payload = <String, dynamic>{
      'tglProduksi': tglStr,
      'idMesin': idMesin,
      'idOperator': idOperator,
      'jamKerja': jamKerja, // ✅ backend parse int / "HH:mm-HH:mm"
      'shift': shift,
      if (hourStart != null && hourStart.isNotEmpty)
        'hourStart': _normalizeTime(hourStart),
      if (hourEnd != null && hourEnd.isNotEmpty)
        'hourEnd': _normalizeTime(hourEnd),
      if (checkBy1 != null) 'checkBy1': checkBy1,
      if (checkBy2 != null) 'checkBy2': checkBy2,
      if (approveBy != null) 'approveBy': approveBy,
      if (hourMeter != null) 'hourMeter': hourMeter,
    };

    print('📦 Key fitting create payload: $payload');

    final body =
    await api.postJson('/api/production/key-fitting', body: payload);

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header key fitting');
    }

    return KeyFittingProduction.fromJson(data);
  }

  // =========================
  //  UPDATE (PUT)
  //  PUT /api/production/key-fitting/:noProduksi
  //  Partial update (kirim hanya yang berubah)
  // =========================
  Future<KeyFittingProduction> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    dynamic jamKerja, // int atau String
    int? shift,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    double? hourMeter,
  }) async {
    String _normalizeTime(String v) {
      final t = v.trim();
      if (t.isEmpty) return t;
      if (t.length == 5) return '$t:00';
      return t;
    }

    final payload = <String, dynamic>{};

    if (tglProduksi != null) payload['tglProduksi'] = toDbDateString(tglProduksi);
    if (idMesin != null) payload['idMesin'] = idMesin;
    if (idOperator != null) payload['idOperator'] = idOperator;
    if (jamKerja != null) payload['jamKerja'] = jamKerja;
    if (shift != null) payload['shift'] = shift;

    if (hourStart != null && hourStart.isNotEmpty) {
      payload['hourStart'] = _normalizeTime(hourStart);
    }
    if (hourEnd != null && hourEnd.isNotEmpty) {
      payload['hourEnd'] = _normalizeTime(hourEnd);
    }

    if (checkBy1 != null) payload['checkBy1'] = checkBy1;
    if (checkBy2 != null) payload['checkBy2'] = checkBy2;
    if (approveBy != null) payload['approveBy'] = approveBy;
    if (hourMeter != null) payload['hourMeter'] = hourMeter;

    print('📦 Key fitting update payload: $payload');

    final body = await api.putJson(
      '/api/production/key-fitting/$noProduksi',
      body: payload,
    );

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header key fitting');
    }

    return KeyFittingProduction.fromJson(data);
  }

  // =========================
  //  DELETE
  //  DELETE /api/production/key-fitting/:noProduksi
  // =========================
  Future<void> deleteProduksi(String noProduksi) async {
    print('🗑️ Deleting key fitting production: $noProduksi');

    try {
      await api.deleteJson('/api/production/key-fitting/$noProduksi');
      print('✅ Key fitting production deleted successfully');
    } catch (e) {
      print('❌ Delete key fitting production error: $e');

      if (e is ApiException) {
        if (e.responseBody != null && e.responseBody!.isNotEmpty) {
          try {
            final decoded = jsonDecode(e.responseBody!);
            final msg = decoded['message'] ??
                decoded['error'] ??
                decoded['msg'] ??
                'Gagal menghapus key fitting produksi';
            throw Exception(msg);
          } catch (_) {
            throw Exception(e.responseBody);
          }
        }
        throw Exception('Gagal menghapus key fitting produksi (${e.statusCode})');
      }

      rethrow;
    }
  }
}
