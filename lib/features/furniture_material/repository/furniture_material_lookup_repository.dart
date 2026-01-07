// lib/features/furniture_material/repository/furniture_material_lookup_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/furniture_material_lookup_model.dart';

class FurnitureMaterialLookupRepository {
  static const _timeout = Duration(seconds: 25);
  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Future<FurnitureMaterialLookupResult?> fetchByCetakanWarna({
    required int idCetakan,
    required int idWarna,
  }) async {
    final token = await TokenStorage.getToken();

    final uri = Uri.parse('$_base/api/mst-furniture-material/by-cetakan-warna').replace(
      queryParameters: {
        'idCetakan': '$idCetakan',
        'idWarna': '$idWarna',
      },
    );

    print('➡️ [GET] $uri');
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    print('⬅️ [${res.statusCode}]');

    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Gagal lookup furniture material (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final data = body['data'];

    if (data == null) return null;
    return FurnitureMaterialLookupResult.fromJson(data as Map<String, dynamic>);
  }
}
