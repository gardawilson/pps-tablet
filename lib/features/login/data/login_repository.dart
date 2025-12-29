// lib/features/login/data/login_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import '../../../core/network/endpoints.dart';
import '../../../core/services/permission_storage.dart';
import '../model/user_model.dart';
import '../model/login_result.dart';

class LoginRepository {
  Future<LoginResult> login(User user) async {
    try {
      final uri = Uri.parse(ApiConstants.login);
      final payload = user.toJson();

      print('Login URL: $uri');
      print('Login payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );

      final body = response.body.trim();
      print('Response status: ${response.statusCode}');
      print('Body length: ${body.length}');
      if (body.isNotEmpty) {
        final preview = body.substring(0, body.length > 220 ? 220 : body.length);
        print('Body preview: $preview');
      }

      if (body.isEmpty) {
        return LoginResult(
          success: false,
          message: 'Server mengembalikan response kosong (status ${response.statusCode}).',
          errorType: 'server',
          detailCode: 'server_error',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        return LoginResult(
          success: false,
          message: 'Response server bukan JSON valid.',
          errorType: 'server',
          detailCode: 'server_error',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        return LoginResult(
          success: false,
          message: 'Format JSON tidak sesuai (bukan object).',
          errorType: 'server',
          detailCode: 'server_error',
        );
      }

      final data = decoded;

      // SUCCESS
      if (response.statusCode == 200 && data['success'] == true) {
        final token = (data['token'] ?? data['accessToken'])?.toString() ?? '';
        if (token.isEmpty) {
          return LoginResult(
            success: false,
            message: 'Login success=true tapi token kosong / key token berbeda.',
            errorType: 'server',
            detailCode: 'server_error',
          );
        }

        final userData = data['user'];
        List<String> permissions = [];
        if (userData is Map<String, dynamic>) {
          permissions = _normalizePermissions(userData['permissions']);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await PermissionStorage.savePermissions(permissions);

        print('✅ Token disimpan: ${token.substring(0, token.length > 12 ? 12 : token.length)}...');
        print('✅ Permissions disimpan: ${permissions.length} item');

        return LoginResult.ok(data['message']?.toString() ?? 'Login berhasil');
      }

      // ERROR FROM BACKEND
      final backendErrorType = (data['errorType'] ?? 'unknown').toString();
      final backendMessage = (data['message'] ?? 'Terjadi kesalahan').toString();

      if (response.statusCode == 503) {
        return LoginResult(
          success: false,
          message: backendMessage.isNotEmpty
              ? backendMessage
              : 'Server sedang offline / maintenance (503).',
          errorType: 'server',
          detailCode: 'server_503',
        );
      }

      if (response.statusCode == 500) {
        return LoginResult(
          success: false,
          message: backendMessage.isNotEmpty
              ? backendMessage
              : 'Terjadi kesalahan di server (500).',
          errorType: 'server',
          detailCode: 'server_500',
        );
      }

      final mapped = _mapErrorType(
        statusCode: response.statusCode,
        backendErrorType: backendErrorType,
      );

      return LoginResult(
        success: false,
        message: backendMessage,
        errorType: mapped.errorType,
        detailCode: mapped.detailCode,
      );
    }

    // NETWORK / CONNECTIVITY
    on TimeoutException catch (e) {
      print('Timeout: $e');
      return LoginResult(
        success: false,
        message: 'Server tidak merespons (timeout).',
        errorType: 'network',
        detailCode: 'timeout',
      );
    }

    on HandshakeException catch (e) {
      print('SSL Handshake error: $e');
      return LoginResult(
        success: false,
        message: 'Gagal konek SSL (sertifikat server bermasalah).',
        errorType: 'network',
        detailCode: 'network_error',
      );
    }

    on http.ClientException catch (e) {
      print('HTTP ClientException: $e');
      return LoginResult(
        success: false,
        message: 'Tidak dapat terhubung ke server.',
        errorType: 'network',
        detailCode: 'network_error',
      );
    }

    on SocketException catch (e) {
      final code = _socketDetail(e);
      final msg = _socketMessage(code);
      print('SocketException: ${e.message}');
      return LoginResult(
        success: false,
        message: msg,
        errorType: 'network',
        detailCode: code,
      );
    }

    catch (e, st) {
      print('Unknown error during login: $e');
      print('Stacktrace: $st');
      return LoginResult(
        success: false,
        message: 'Terjadi kesalahan tidak terduga: $e',
        errorType: 'unknown',
        detailCode: 'unknown',
      );
    }
  }

  // helpers (dipindahkan dari ViewModel)
  List<String> _normalizePermissions(dynamic permsRaw) {
    if (permsRaw == null) return [];
    if (permsRaw is List) {
      return permsRaw
          .map((e) {
        if (e is String) return e;
        if (e is Map<String, dynamic>) {
          final v = e['code'] ?? e['permission'] ?? e['name'];
          return (v ?? '').toString();
        }
        return e.toString();
      })
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
    }
    final s = permsRaw.toString().trim();
    return s.isEmpty ? [] : [s];
  }

  String _socketDetail(SocketException e) {
    final m = (e.message).toLowerCase();
    if (m.contains('failed host lookup') ||
        m.contains('name not known') ||
        m.contains('nodename nor servname provided')) {
      return 'dns';
    }
    if (m.contains('connection refused')) return 'backend_offline';
    if (m.contains('no route to host') ||
        m.contains('network is unreachable') ||
        m.contains('unreachable')) {
      return 'internet_offline';
    }
    if (m.contains('timed out')) return 'timeout';
    return 'network_error';
  }

  String _socketMessage(String code) {
    switch (code) {
      case 'backend_offline':
        return 'Backend sedang offline / server mati (connection refused).';
      case 'dns':
        return 'Alamat server tidak ditemukan (DNS gagal).';
      case 'internet_offline':
        return 'Koneksi jaringan bermasalah (tidak ada rute ke server).';
      case 'timeout':
        return 'Koneksi ke server timeout.';
      default:
        return 'Tidak dapat terhubung ke server.';
    }
  }

  _MappedError _mapErrorType({
    required int statusCode,
    required String backendErrorType,
  }) {
    if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
      return _MappedError('auth', 'auth_error');
    }
    if (statusCode == 400) {
      return _MappedError('validation', 'validation_error');
    }
    if (statusCode == 500) {
      return _MappedError('server', 'server_500');
    }
    if (statusCode == 503) {
      return _MappedError('server', 'server_503');
    }

    switch (backendErrorType) {
      case 'user_not_found':
      case 'wrong_password':
      case 'user_inactive':
      case 'invalid_credentials':
        return _MappedError('auth', 'auth_error');
      case 'validation':
        return _MappedError('validation', 'validation_error');
      case 'database_connection':
      case 'server_error':
        return _MappedError('server', 'server_error');
      default:
        return _MappedError('unknown', 'unknown');
    }
  }
}

class _MappedError {
  final String errorType;
  final String detailCode;
  _MappedError(this.errorType, this.detailCode);
}
