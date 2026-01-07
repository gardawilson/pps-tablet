// lib/features/cetakan/repository/cetakan_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/mst_cetakan_model.dart';

class CetakanRepository {
  static const _timeout = Duration(seconds: 25);
  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Future<http.Response> _get(Uri url) async {
    final token = await TokenStorage.getToken();
    final started = DateTime.now();
    print('➡️ [GET] $url');
    try {
      final res = await http.get(url, headers: _headers(token)).timeout(_timeout);
      print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');
      return res;
    } on TimeoutException {
      throw Exception('Timeout saat mengambil data dari $url');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }
  }

  /// Ambil semua cetakan dari /api/master-cetakan (active only)
  /// Optional: filter by idBj kalau BE kamu support query param idBj
  Future<List<MstCetakan>> fetchAll({
    int? idBj,
  }) async {
    final params = <String, String>{};
    if (idBj != null) params['idBj'] = '$idBj';

    final uri = Uri.parse('$_base/api/mst-cetakan')
        .replace(queryParameters: params.isEmpty ? null : params);

    final res = await _get(uri);

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data cetakan (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list.map((e) => MstCetakan.fromJson(e as Map<String, dynamic>)).toList();
  }
}
