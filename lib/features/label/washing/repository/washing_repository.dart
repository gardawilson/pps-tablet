import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../constants/api_constants.dart';
import '../../../../utils/token_storage.dart';
import '../model/washing_header_model.dart';
import '../model/washing_detail_model.dart';

class WashingRepository {
  /// Ambil daftar washing dengan pagination & search
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/washing?page=$page&limit=$limit&search=$search",
    );

    print("➡️ Fetching Washing Headers: $url");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${response.statusCode}]: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      final List<dynamic> data = body['data'] ?? [];
      final List<WashingHeader> items =
      data.map((e) => WashingHeader.fromJson(e)).toList();

      final meta = body['meta'] ?? {};

      return {
        "items": items,
        "page": meta['page'] ?? page,
        "limit": meta['limit'] ?? limit,
        "total": meta['total'] ?? items.length,
        "totalPages": meta['totalPages'] ?? 1,
      };
    } else {
      throw Exception(
        'Gagal fetch data washing (status: ${response.statusCode})',
      );
    }
  }

  /// Ambil detail washing berdasarkan NoWashing
  Future<List<WashingDetail>> fetchDetails(String noWashing) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/washing/$noWashing",
    );

    print("➡️ Fetching Washing Details: $url");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${response.statusCode}]: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List<dynamic> details = body['data']?['details'] ?? [];
      return details.map((e) => WashingDetail.fromJson(e)).toList();
    } else {
      throw Exception(
        'Gagal fetch detail washing (status: ${response.statusCode})',
      );
    }
  }
}
