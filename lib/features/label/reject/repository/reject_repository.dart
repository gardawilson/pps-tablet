// lib/features/reject/repository/reject_repository.dart

import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../model/reject_header_model.dart';
import '../model/reject_partial_model.dart';

class RejectRepository {
  final ApiClient api;

  RejectRepository({required this.api});

  // Helper untuk ambil pesan error yang lebih ramah dari ApiException
  String _friendlyError(ApiException e, String defaultMsg) {
    try {
      if (e.responseBody == null || e.responseBody!.isEmpty) {
        return '$defaultMsg (status: ${e.statusCode})';
      }

      final decoded = json.decode(e.responseBody!) as Map<String, dynamic>;
      final msg = (decoded['message'] ?? decoded['error'])?.toString();

      if (msg == null || msg.isEmpty) {
        return '$defaultMsg (status: ${e.statusCode})';
      }
      return '$msg (status: ${e.statusCode})';
    } catch (_) {
      return '$defaultMsg (status: ${e.statusCode})';
    }
  }

  // =======================================================================
  // GET /api/labels/reject?page=&limit=&search=
  // =======================================================================
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    try {
      final body = await api.getJson(
        '/api/labels/reject',
        query: {
          'page': page,
          'limit': limit,
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      // 🔴 MASALAH: Asumsi body['data'] selalu List
      // Backend bisa return Map atau List tergantung kondisi
      final dynamic rawData = body['data'];
      final List<dynamic> raw;

      if (rawData is List) {
        raw = rawData;
      } else if (rawData is Map<String, dynamic>) {
        // Jika backend return single object, wrap dalam List
        raw = [rawData];
      } else {
        raw = [];
      }

      final items = raw
          .whereType<Map<String, dynamic>>() // 🟢 Filter hanya Map yang valid
          .map((e) => RejectHeader.fromJson(e))
          .toList();

      final meta = (body['meta'] as Map<String, dynamic>?) ?? const {};
      return {
        'items': items,
        'page': meta['page'] ?? page,
        'limit': meta['limit'] ?? limit,
        'total': meta['total'] ?? items.length,
        'totalPages': meta['totalPages'] ?? 1,
      };
    } on ApiException catch (e) {
      throw Exception(
        _friendlyError(e, 'Gagal fetch Reject'),
      );
    }
  }

  // =======================================================================
  // POST /api/labels/reject
  // =======================================================================
  Future<Map<String, dynamic>> createReject(
      Map<String, dynamic> body,
      ) async {
    // Guard: outputCode wajib
    final oc = (body['outputCode'] ?? '').toString().trim();
    if (oc.isEmpty) {
      throw Exception(
        'outputCode wajib diisi (S., BH., BI., BJ., J.)',
      );
    }

    // 🟢 TAMBAHAN: Validasi prefix
    final validPrefixes = ['S.', 'BH.', 'BI.', 'BJ.', 'J.'];
    final hasValidPrefix = validPrefixes.any((p) => oc.startsWith(p));

    if (!hasValidPrefix) {
      throw Exception(
        'outputCode harus dimulai dengan salah satu: ${validPrefixes.join(", ")}',
      );
    }

    try {
      final res = await api.postJson(
        '/api/labels/reject',
        body: body,
      );

      // 🟢 TAMBAHAN: Defensive parsing untuk response
      // Backend mungkin return structure berbeda
      if (res['data'] == null) {
        throw Exception('Response tidak mengandung data');
      }

      return res;
    } on ApiException catch (e) {
      throw Exception(
        _friendlyError(e, 'Gagal membuat Reject'),
      );
    }
  }

  // =======================================================================
  // PUT /api/labels/reject/:noReject
  // =======================================================================
  Future<Map<String, dynamic>> updateReject(
      String noReject,
      Map<String, dynamic> body,
      ) async {
    // 🟢 TAMBAHAN: Validasi noReject tidak kosong
    if (noReject.trim().isEmpty) {
      throw Exception('NoReject tidak boleh kosong');
    }

    if (body.isEmpty) {
      throw Exception('Tidak ada field yang diubah.');
    }

    try {
      final res = await api.putJson(
        '/api/labels/reject/${Uri.encodeComponent(noReject)}',
        body: body,
      );
      return res;
    } on ApiException catch (e) {
      throw Exception(
        _friendlyError(e, 'Gagal update Reject'),
      );
    }
  }

  // =======================================================================
  // DELETE /api/labels/reject/:noReject
  // =======================================================================
  Future<Map<String, dynamic>> deleteReject(
      String noReject,
      ) async {
    // 🟢 TAMBAHAN: Validasi noReject tidak kosong
    if (noReject.trim().isEmpty) {
      throw Exception('NoReject tidak boleh kosong');
    }

    try {
      final res = await api.deleteJson(
        '/api/labels/reject/${Uri.encodeComponent(noReject)}',
      );
      return res;
    } on ApiException catch (e) {
      throw Exception(
        _friendlyError(e, 'Gagal menghapus Reject'),
      );
    }
  }

  // =======================================================================
  // GET /api/labels/reject/partials/:noreject
  // =======================================================================
  Future<RejectPartialInfo> fetchPartialInfo({
    required String noReject,
  }) async {
    // 🟢 TAMBAHAN: Validasi noReject tidak kosong
    if (noReject.trim().isEmpty) {
      throw Exception('NoReject tidak boleh kosong');
    }

    try {
      final body = await api.getJson(
        '/api/labels/reject/partials/${Uri.encodeComponent(noReject)}',
      );

      return RejectPartialInfo.fromEnvelope(body);
    } on ApiException catch (e) {
      throw Exception(
        _friendlyError(e, 'Failed to fetch reject partial info'),
      );
    }
  }
}