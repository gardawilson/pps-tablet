import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/stock_opname_model.dart';
import '../model/stock_opname_pagination_model.dart';

class StockOpnameRepository {
  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  dynamic _decodeBody(http.Response response) {
    try {
      return json.decode(response.body);
    } catch (_) {
      throw Exception(
        'Response API tidak valid (${response.statusCode}): ${response.body}',
      );
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    final body = _decodeBody(response);
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return fallback;
  }

  Future<List<StockOpname>> fetchStockOpnameList() async {
    final url = Uri.parse(ApiConstants.stockOpnameList);

    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final body = _decodeBody(response);

      if (body is List) {
        return body.map((e) => StockOpname.fromJson(e)).toList();
      } else if (body is Map && body.containsKey('data')) {
        return (body['data'] as List)
            .map((e) => StockOpname.fromJson(e))
            .toList();
      } else {
        throw Exception('Format data tidak sesuai');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token is invalid or expired');
    } else {
      throw Exception(
        _errorMessage(response, 'Tidak ada Jadwal Stock Opname saat ini'),
      );
    }
  }

  Future<StockOpnamePaginationResponse> fetchStockOpnamePaged({
    required int page,
    required int limit,
    String search = '',
    String filter = 'Semua',
  }) async {
    String? isAscend;
    if (filter == 'Ascend') {
      isAscend = '1';
    } else if (filter == 'PPS' || filter == 'Local' || filter == 'Standard') {
      isAscend = '0';
    }

    // Build URL dengan query parameters
    final uri = Uri.parse(ApiConstants.stockOpnameList).replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
        if (isAscend != null) 'isAscend': isAscend,
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final body = _decodeBody(response);
      if (body is! Map<String, dynamic>) {
        throw Exception('Format response Stock Opname tidak sesuai');
      }
      return StockOpnamePaginationResponse.fromJson(body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token is invalid or expired');
    } else {
      throw Exception(
        _errorMessage(response, 'Gagal memuat data Stock Opname'),
      );
    }
  }
}
