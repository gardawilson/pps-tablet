import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../constants/api_constants.dart';
import '../../../../utils/token_storage.dart';
import '../model/washing_header_model.dart';


class WashingRepository {
  Future<List<WashingHeader>> fetchHeaders() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/label/washing");

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((e) => WashingHeader.fromJson(e)).toList();
    } else {
      throw Exception('Gagal fetch data washing');
    }
  }
}

