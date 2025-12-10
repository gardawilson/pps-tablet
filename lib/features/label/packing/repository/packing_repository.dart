// lib/features/packing/repository/reject_repository.dart

import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../model/packing_header_model.dart';
import '../model/packing_partial_model.dart';

class PackingRepository {
  final ApiClient api;

  PackingRepository({required this.api});

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
  // GET /api/labels/packing?page=&limit=&search=
  // =======================================================================
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    try {
      final body = await api.getJson(
        '/api/labels/packing',
        query: {
          'page': page,
          'limit': limit,
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      final List<dynamic> raw = body['data'] ?? [];
      final items = raw
          .map(
            (e) => PackingHeader.fromJson(e as Map<String, dynamic>),
      )
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
      throw Exception(_friendlyError(
        e,
        'Gagal fetch Packing (Barang Jadi)',
      ));
    }
  }

  // =======================================================================
  // POST /api/labels/packing
  //
  // Body example:
  // {
  //   "header": {
  //     "IdBJ": 123,
  //     "Pcs": 10,
  //     "Berat": 25.5,
  //     "DateCreate": "2025-12-05",
  //     "Jam": "08:00",
  //     "IsPartial": 0,
  //     "IdWarehouse": 3,
  //     "Blok": "A",
  //     "IdLokasi": "1"
  //   },
  //   "outputCode": "BD.0000..." / "S.0000..." / "BG.0000..." / "L.0000..."
  // }
  // =======================================================================
  Future<Map<String, dynamic>> createPacking(
      Map<String, dynamic> body,
      ) async {
    // Guard: outputCode wajib
    final oc = (body['outputCode'] ?? '').toString().trim();
    if (oc.isEmpty) {
      throw Exception('outputCode wajib diisi (BD., S., BG., L.)');
    }

    try {
      final res = await api.postJson(
        '/api/labels/packing',
        body: body,
      );
      return res;
    } on ApiException catch (e) {
      throw Exception(_friendlyError(
        e,
        'Gagal membuat Packing (Barang Jadi)',
      ));
    }
  }

  // =======================================================================
  // PUT /api/labels/packing/:noBJ
  // =======================================================================
  Future<Map<String, dynamic>> updatePacking(
      String noBJ,
      Map<String, dynamic> body,
      ) async {
    if (body.isEmpty) {
      throw Exception('Tidak ada field yang diubah.');
    }

    try {
      final res = await api.putJson(
        '/api/labels/packing/${Uri.encodeComponent(noBJ)}',
        body: body,
      );
      return res;
    } on ApiException catch (e) {
      throw Exception(_friendlyError(
        e,
        'Gagal update Packing (Barang Jadi)',
      ));
    }
  }

  // =======================================================================
  // DELETE /api/labels/packing/:noBJ
  // =======================================================================
  Future<Map<String, dynamic>> deletePacking(
      String noBJ,
      ) async {
    try {
      final res = await api.deleteJson(
        '/api/labels/packing/${Uri.encodeComponent(noBJ)}',
      );
      return res;
    } on ApiException catch (e) {
      throw Exception(_friendlyError(
        e,
        'Gagal menghapus Packing',
      ));
    }
  }

  // =======================================================================
  // GET /api/labels/packing/partials/:noBJ
  // =======================================================================
  Future<PackingPartialInfo> fetchPartialInfo({
    required String noBJ,
  }) async {
    try {
      final body = await api.getJson(
        '/api/labels/packing/partials/${Uri.encodeComponent(noBJ)}',
      );

      return PackingPartialInfo.fromEnvelope(body);
    } on ApiException catch (e) {
      throw Exception(_friendlyError(
        e,
        'Failed to fetch packing partial info',
      ));
    }
  }
}
