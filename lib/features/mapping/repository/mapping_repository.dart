import 'package:pps_tablet/core/network/api_client.dart';

import '../model/mapping_blok_model.dart';
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
}
