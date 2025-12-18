// lib/features/shared/bongkar_susun/repository/bongkar_susun_repository.dart
import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../model/bongkar_susun_model.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

class BongkarSusunRepository {
  // Simple in-memory cache for inputs (siap untuk fitur detail nanti)
  final Map<String, dynamic> _inputsCache = {};

  final ApiClient _apiClient;

  BongkarSusunRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // =========================
  //  BY DATE (tetap ada)
  // =========================
  Future<List<BongkarSusun>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date);

    try {
      final body = await _apiClient.getJson('/api/bongkar-susun/$dateDb');

      final List list = (body['data'] ?? []) as List;
      return list
          .map((e) => BongkarSusun.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      // Samakan behaviour lama: 404 dianggap tidak ada data → []
      if (e.statusCode == 404) {
        return <BongkarSusun>[];
      }
      rethrow;
    }
  }

  // ==========================================
  //  PAGINATED LIST (infinite scroll style)
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,

    // Text search for NoBongkarSusun (contains)
    String? search,

    // VM convenience: prefer this if provided
    String? noBongkarSusun,
    bool exactNoBongkarSusun = false, // backend currently does LIKE only

    // Other optional filters (siap untuk ekspansi backend)
    DateTime? date, // legacy single date -> maps to dateFrom/dateTo
    DateTime? dateFrom,
    DateTime? dateTo,
    int? idUsername,
  }) async {
    // Prefer explicit noBongkarSusun over generic search
    final String? effectiveSearch =
    (noBongkarSusun != null && noBongkarSusun.trim().isNotEmpty)
        ? noBongkarSusun.trim()
        : (search != null && search.trim().isNotEmpty
        ? search.trim()
        : null);

    // Map dates: if range not provided but single `date` is set, use it for both from/to
    final String? df = dateFrom != null
        ? toDbDateString(dateFrom)
        : (date != null ? toDbDateString(date) : null);

    final String? dt = dateTo != null
        ? toDbDateString(dateTo)
        : (date != null ? toDbDateString(date) : null);

    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (effectiveSearch != null) 'search': effectiveSearch, // API searches NoBongkarSusun
      if (df != null) 'dateFrom': df,
      if (dt != null) 'dateTo': dt,
      if (idUsername != null) 'idUsername': idUsername,
    };

    final body = await _apiClient.getJson(
      '/api/bongkar-susun',
      query: qp,
    );

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => BongkarSusun.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final currentPage = (meta['page'] ?? page) as int;
    final totalPages = (meta['totalPages'] ?? 1) as int;
    final totalData = (body['totalData'] ?? meta['total'] ?? 0) as int;

    print(
        '✅ BongkarSusun parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items, // List<BongkarSusun>
      'page': currentPage,
      'totalPages': totalPages,
      'total': totalData,
    };
  }

  /// Convenience jika hanya butuh list halaman tertentu
  Future<List<BongkarSusun>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    String? noBongkarSusun,
    bool exactNoBongkarSusun = false,
    DateTime? date,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? idUsername,
  }) async {
    final r = await fetchAll(
      page: page,
      pageSize: pageSize,
      search: search,
      noBongkarSusun: noBongkarSusun,
      exactNoBongkarSusun: exactNoBongkarSusun,
      date: date,
      dateFrom: dateFrom,
      dateTo: dateTo,
      idUsername: idUsername,
    );
    return (r['items'] as List<BongkarSusun>);
  }

  // =========================
  //  CREATE (POST)
  // =========================
  Future<BongkarSusun> createBongkarSusun({
    required DateTime tanggal,
    String? note,
  }) async {
    final tglStr = toDbDateString(tanggal);

    final body = <String, dynamic>{
      'tanggal': tglStr,
      if (note != null && note.isNotEmpty) 'note': note,
    };

    final jsonResp = await _apiClient.postJson(
      '/api/bongkar-susun',
      body: body,
    );

    final data = jsonResp['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Response tidak mengandung data header');
    }

    return BongkarSusun.fromJson(data);
  }

  // =========================
  //  UPDATE (PUT)
  // =========================
  Future<BongkarSusun> updateBongkarSusun({
    required String noBongkarSusun, // ← dari URL
    DateTime? tanggal,
    String? note,
  }) async {
    // karena ini UPDATE, semua boleh null → kita kirim hanya yang diisi
    final body = <String, dynamic>{};

    if (tanggal != null) {
      body['tanggal'] = toDbDateString(tanggal);
    }

    if (note != null) {
      body['note'] = note; // boleh kosong string untuk clear jadi NULL
    }

    final jsonResp = await _apiClient.putJson(
      '/api/bongkar-susun/$noBongkarSusun',
      body: body,
    );

    final data = jsonResp['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Response tidak mengandung data header');
    }

    return BongkarSusun.fromJson(data);
  }

  // =========================
  //  DELETE
  // =========================
  Future<void> deleteBongkarSusun(String noBongkarSusun) async {
    await _apiClient.deleteJson(
      '/api/bongkar-susun/$noBongkarSusun',
    );

    // kalau sebelumnya kita sudah pernah ambil inputs untuk noBongkarSusun ini, buang dari cache
    _inputsCache.remove(noBongkarSusun);
  }
}
