import 'package:pps_tablet/core/network/api_client.dart';

import '../model/mapping_blok_model.dart';
import '../model/mapping_label_model.dart';
import '../model/mapping_lokasi_model.dart';
export '../model/mapping_lokasi_model.dart' show MasterKategori, MasterJenis;

class MappingRepository {
  final ApiClient api;

  MappingRepository({required this.api});

  Future<List<MappingBlok>> fetchBlokList() async {
    final body = await api.getJson('/api/mapping/blok');
    final data = body['data'];

    if (data is! List) {
      throw Exception('Format data mapping blok tidak sesuai');
    }

    return data
        .map((e) => MappingBlok.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MappingLokasi>> fetchLokasiByBlok(String blok) async {
    final body = await api.getJson('/api/mapping/lokasi', query: {'blok': blok});
    final data = body['data'];

    if (data is! List) {
      throw Exception('Format data mapping lokasi tidak sesuai');
    }

    return data
        .map((e) => MappingLokasi.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> fetchLayout(String blok) async {
    final body = await api.getJson('/api/mapping/layout/$blok');
    if (body['success'] != true) return null;
    return body['data'] as Map<String, dynamic>?;
  }

  Future<void> saveLayout(String blok, Map<String, dynamic> payload) async {
    await api.postJson('/api/mapping/layout/$blok', body: payload);
  }

  Future<List<MasterKategori>> fetchKategori() async {
    final body = await api.getJson('/api/master-kategori');
    final data = body['data'];
    if (data is! List) throw Exception('Format data kategori tidak sesuai');
    return data
        .map((e) => MasterKategori.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MasterJenis>> fetchJenis(int idKategori) async {
    final body = await api.getJson('/api/master-jenis',
        query: {'idKategori': idKategori.toString()});
    final data = body['data'];
    if (data is! List) throw Exception('Format data jenis tidak sesuai');
    return data
        .map((e) => MasterJenis.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createLokasi(
    String blok,
    Map<String, dynamic> payload,
  ) async {
    await api.postJson('/api/mapping/lokasi/$blok', body: payload);
  }

  Future<void> updateLokasi(
    String blok,
    int idLokasi,
    Map<String, dynamic> payload,
  ) async {
    await api.putJson('/api/mapping/lokasi/$blok/$idLokasi', body: payload);
  }

  Future<MappingLabelResult> fetchLabelByLokasi({
    required String blok,
    required int idLokasi,
  }) async {
    final body = await api.getJson(
      '/api/label/all/v2',
      query: {'blok': blok, 'idlokasi': idLokasi.toString()},
    );

    final raw = body['data'];
    if (raw is! List) throw Exception('Format data label tidak sesuai');

    final items = raw
        .map((e) => MappingLabelItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return MappingLabelResult(
      data: items,
      totalData: (body['totalData'] as num?)?.toInt() ?? items.length,
      totalQty: items.fold(0, (s, e) => s + e.qty),
      totalBerat: items.fold(0.0, (s, e) => s + (e.berat ?? 0)),
    );
  }
}
