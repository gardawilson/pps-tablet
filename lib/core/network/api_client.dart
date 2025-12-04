// lib/core/network/api_client.dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'endpoints.dart';
import '../services/token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? responseBody;

  ApiException(this.statusCode, this.message, {this.responseBody});

  @override
  String toString() =>
      'ApiException($statusCode): $message ${responseBody ?? ''}';
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 25);

  String get _base =>
      ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  /// Build URL from path + query
  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final base = _base;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$base$cleanPath').replace(
      queryParameters: query?.map(
            (k, v) => MapEntry(k, v?.toString() ?? ''),
      ),
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<http.Response> _send(
      String method,
      String path, {
        Map<String, dynamic>? query,
        Object? body,
      }) async {
    final url = _buildUri(path, query);
    final headers = await _headers();

    print('➡️ [$method] $url');
    if (body != null) {
      print('📦 Body: $body');
    }

    late http.Response resp;
    final started = DateTime.now();

    try {
      switch (method) {
        case 'GET':
          resp = await _client
              .get(url, headers: headers)
              .timeout(_timeout);
          break;
        case 'POST':
          resp = await _client
              .post(url, headers: headers, body: json.encode(body))
              .timeout(_timeout);
          break;
        case 'PUT':
          resp = await _client
              .put(url, headers: headers, body: json.encode(body))
              .timeout(_timeout);
          break;
        case 'DELETE':
          resp = await _client
              .delete(url, headers: headers, body: body != null ? json.encode(body) : null)
              .timeout(_timeout);
          break;
        default:
          throw ArgumentError('HTTP method not supported: $method');
      }
    } on TimeoutException {
      throw ApiException(408, 'Request timeout: $method $url');
    } catch (e) {
      print('❌ [$method] $url error: $e');
      rethrow;
    }

    print('⬅️ [${resp.statusCode}] in '
        '${DateTime.now().difference(started).inMilliseconds}ms');
    if (resp.body.isNotEmpty) {
      print('📨 Body: ${resp.body}');
    }

    return resp;
  }

  Map<String, dynamic> _decodeJsonBody(http.Response resp) {
    if (resp.body.isEmpty) return <String, dynamic>{};

    final decoded = utf8.decode(resp.bodyBytes);
    final dynamic jsonBody = json.decode(decoded);

    if (jsonBody is Map<String, dynamic>) return jsonBody;

    // Kalau API kadang balikin list, bungkus jadi map
    return {'data': jsonBody};
  }

  // ---------------------------
  // Public helpers
  // ---------------------------

  Future<Map<String, dynamic>> getJson(
      String path, {
        Map<String, dynamic>? query,
      }) async {
    final resp = await _send('GET', path, query: query);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(
        resp.statusCode,
        'GET $path failed',
        responseBody: resp.body,
      );
    }

    return _decodeJsonBody(resp);
  }

  Future<Map<String, dynamic>> postJson(
      String path, {
        Map<String, dynamic>? query,
        Object? body,
      }) async {
    final resp = await _send('POST', path, query: query, body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(
        resp.statusCode,
        'POST $path failed',
        responseBody: resp.body,
      );
    }

    return _decodeJsonBody(resp);
  }

  Future<Map<String, dynamic>> putJson(
      String path, {
        Map<String, dynamic>? query,
        Object? body,
      }) async {
    final resp = await _send('PUT', path, query: query, body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(
        resp.statusCode,
        'PUT $path failed',
        responseBody: resp.body,
      );
    }

    return _decodeJsonBody(resp);
  }

  /// Delete yang mungkin mengembalikan body (200) atau tidak (204).
  Future<Map<String, dynamic>> deleteJson(
      String path, {
        Map<String, dynamic>? query,
        Object? body,
      }) async {
    final resp = await _send('DELETE', path, query: query, body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(
        resp.statusCode,
        'DELETE $path failed',
        responseBody: resp.body,
      );
    }

    // 204 No Content
    if (resp.statusCode == 204 || resp.body.isEmpty) {
      return <String, dynamic>{};
    }

    return _decodeJsonBody(resp);
  }
}
