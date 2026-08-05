import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../model/so_v2_blok_page.dart';
import '../model/so_v2_complete_summary.dart';
import '../model/so_v2_generate_preview.dart';
import '../model/so_v2_kategori.dart';
import '../model/so_v2_lokasi_page.dart';
import '../model/so_v2_label_page.dart';
import '../model/so_v2_scan_summary.dart';

class SoV2Repository {
  final ApiClient _api;

  SoV2Repository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<SoV2Kategori>> fetchKategori({int? year, int? month}) async {
    final body = await _api.getJson(
      '/api/stock-opname-v2/kategori',
      query: {
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );
    final dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => SoV2Kategori.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<({String message, SoV2GeneratePreview preview})> previewGenerate({
    required int categoryId,
  }) async {
    final body = await _api.getJson(
      '/api/stock-opname-v2/transaksi/preview',
      query: {'categoryId': categoryId},
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response tidak mengandung data');
    return (
      message: body['message']?.toString() ?? '',
      preview: SoV2GeneratePreview.fromJson(data),
    );
  }

  Future<Map<String, dynamic>> generateNoStockOpname({
    required int categoryId,
  }) async {
    final body = await _api.postJson(
      '/api/stock-opname-v2/transaksi',
      body: {'categoryId': categoryId},
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response tidak mengandung data');
    return data;
  }

  Future<void> deleteStockOpname(String stockOpnameNo) async {
    await _api.deleteJson('/api/stock-opname-v2/transaksi/$stockOpnameNo');
  }

  Future<SoV2BlokPage> fetchBlok({required String stockOpnameNo}) async {
    final body = await _api.getJson(
      '/api/stock-opname-v2/transaksi/$stockOpnameNo/blok',
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response tidak mengandung data');
    return SoV2BlokPage.fromJson(data);
  }

  Future<SoV2LokasiPage> fetchLokasi({
    required String stockOpnameNo,
    required String blok,
  }) async {
    final body = await _api.getJson(
      '/api/stock-opname-v2/transaksi/$stockOpnameNo/blok/$blok/lokasi',
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response tidak mengandung data');
    return SoV2LokasiPage.fromJson(data);
  }

  Future<SoV2LabelPage> fetchLabelPage({
    required String stockOpnameNo,
    required String blok,
    required int locationId,
    required int page,
    int pageSize = 20,
    String? search,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    try {
      final body = await _api.getJson(
        '/api/stock-opname-v2/transaksi/$stockOpnameNo/blok/$blok/lokasi/$locationId/label',
        query: qp,
      );
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Response tidak mengandung data');
      return SoV2LabelPage.fromJson(data);
    } on ApiException catch (e) {
      // Backend membalas 404 saat page > totalPages (atau belum ada snapshot),
      // meski body-nya tetap membawa meta pagination valid dengan data
      // kosong. Perlakukan sebagai halaman kosong, bukan error.
      if (e.statusCode == 404 && e.responseBody != null) {
        try {
          final decoded = jsonDecode(e.responseBody!) as Map<String, dynamic>;
          final data = decoded['data'] as Map<String, dynamic>?;
          if (data != null) return SoV2LabelPage.fromJson(data);
        } catch (_) {
          // responseBody bukan JSON yang diharapkan -> rethrow di bawah.
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeStockOpname(String stockOpnameNo) async {
    final body = await _api.patchJson(
      '/api/stock-opname-v2/transaksi/$stockOpnameNo/complete',
    );
    final data = body['data'] as Map<String, dynamic>?;
    return data ?? {};
  }

  Future<SoV2CompleteSummary> fetchCompleteSummary(
    String stockOpnameNo,
  ) async {
    final body = await _api.getJson(
      '/api/stock-opname-v2/transaksi/$stockOpnameNo/complete-summary',
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response tidak mengandung data');
    return SoV2CompleteSummary.fromJson(data);
  }

  /// Hapus hasil scan satu label (mis. label yang salah lokasi/isLocationMismatch)
  /// supaya bisa discan ulang dengan lokasi yang benar.
  Future<void> deleteHasilLabel({
    required String stockOpnameNo,
    required String labelNo,
  }) async {
    await _api.deleteJson(
      '/api/stock-opname-v2/transaksi/$stockOpnameNo/hasil/${Uri.encodeComponent(labelNo)}',
    );
  }

  Future<SoV2ScanSummary> fetchScanSummary(String stockOpnameNo) async {
    final body = await _api.getJson(
      '/api/stock-opname-v2/transaksi/$stockOpnameNo/scan-summary',
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Response tidak mengandung data');
    return SoV2ScanSummary.fromJson(data);
  }
}
