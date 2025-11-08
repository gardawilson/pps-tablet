import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/broker_inputs_model.dart';
import '../model/broker_production_model.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

class BrokerProductionInputRepository {
  static const _timeout = Duration(seconds: 25);

  // Simple in-memory cache for inputs
  final Map<String, BrokerInputs> _inputsCache = {};

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };
  
  // Optional: parse on an isolate for large JSON
  static BrokerInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return BrokerInputs.fromJson(data);
  }

  Future<BrokerInputs> fetchInputs(String noProduksi, {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noProduksi)) {
      return _inputsCache[noProduksi]!;
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/broker/$noProduksi/inputs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil input ($noProduksi)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] in ${elapsedMs}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil input ($noProduksi), code ${res.statusCode})');
    }

    // Decode safely (handles non-ASCII)
    final decoded = utf8.decode(res.bodyBytes);

    // Parse JSON (optionally via compute to keep UI smooth for large payloads)
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response bukan JSON valid: $e');
    }

    final inputs = await compute(_parseInputs, body);

    _inputsCache[noProduksi] = inputs;
    return inputs;
  }

  void invalidateInputs(String noProduksi) => _inputsCache.remove(noProduksi);
  void clearCache() => _inputsCache.clear();

}

