import 'package:pps_tablet/core/network/api_client.dart';

import '../model/mapping_blok_model.dart';
import '../model/mapping_label_model.dart';
import '../model/mapping_lokasi_model.dart';

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

  Future<MappingLabelResult> fetchLabelByLokasi({
    required String blok,
    required int idLokasi,
  }) async {
    final body = await api.getJson(
      '/api/label/all',
      query: {'blok': blok, 'idlokasi': idLokasi.toString()},
    );

    final data = body['data'];
    if (data is! List) throw Exception('Format data label tidak sesuai');

    return MappingLabelResult(
      data: data
          .map((e) => MappingLabelItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalData: (body['totalData'] as num?)?.toInt() ?? 0,
      totalQty: (body['totalQty'] as num?)?.toInt() ?? 0,
      totalBerat: (body['totalBerat'] as num?)?.toDouble() ?? 0,
    );
  }
}
