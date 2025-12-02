import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/services/permission_storage.dart';

class LoginResult {
  final bool success;
  final String message;
  final String errorType;

  LoginResult({
    required this.success,
    required this.message,
    required this.errorType,
  });
}

class LoginViewModel {
  Future<LoginResult> validateLogin(User user) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw SocketException('Connection timeout');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('Login success: ${data['message']}');

          String token = data['token'];
          var userData = data['user'];
          List<String> permissions = [];

          if (userData['permissions'] != null) {
            permissions = List<String>.from(userData['permissions']);
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await PermissionStorage.savePermissions(permissions);

          print('✅ Token dan permissions disimpan');

          return LoginResult(
            success: true,
            message: 'Login berhasil',
            errorType: '',
          );
        }
      }

      // Handle error responses with errorType from backend
      var data = jsonDecode(response.body);
      String errorType = data['errorType'] ?? 'unknown';
      String message = data['message'] ?? 'Terjadi kesalahan';

      // Map backend error types to frontend error types
      String frontendErrorType;
      switch (errorType) {
        case 'user_not_found':
        case 'wrong_password':
        case 'user_inactive':
          frontendErrorType = 'auth';
          break;
        case 'validation':
          frontendErrorType = 'validation';
          break;
        case 'database_connection':
        case 'server_error':
          frontendErrorType = 'server';
          break;
        default:
          frontendErrorType = 'unknown';
      }

      // Specific handling based on status code
      if (response.statusCode == 401) {
        return LoginResult(
          success: false,
          message: message,
          errorType: 'auth',
        );
      } else if (response.statusCode == 403) {
        return LoginResult(
          success: false,
          message: message,
          errorType: 'auth',
        );
      } else if (response.statusCode == 404) {
        return LoginResult(
          success: false,
          message: message,
          errorType: 'auth',
        );
      } else if (response.statusCode == 500) {
        return LoginResult(
          success: false,
          message: message,
          errorType: 'server',
        );
      } else if (response.statusCode == 503) {
        return LoginResult(
          success: false,
          message: message,
          errorType: 'server',
        );
      } else {
        return LoginResult(
          success: false,
          message: message,
          errorType: frontendErrorType,
        );
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      return LoginResult(
        success: false,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        errorType: 'network',
      );
    } on HttpException catch (e) {
      print('HTTP error: $e');
      return LoginResult(
        success: false,
        message: 'Terjadi kesalahan komunikasi dengan server.',
        errorType: 'network',
      );
    } on FormatException catch (e) {
      print('Format error: $e');
      return LoginResult(
        success: false,
        message: 'Format data tidak valid dari server.',
        errorType: 'server',
      );
    } catch (e) {
      print('Unknown error during login: $e');
      return LoginResult(
        success: false,
        message: 'Terjadi kesalahan tidak terduga: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }
}