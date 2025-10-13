import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/services/permission_storage.dart'; // tambahkan ini

class LoginViewModel {
  Future<bool> validateLogin(User user) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
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

          // Simpan token dan permissions
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await PermissionStorage.savePermissions(permissions);

          print('✅ Token dan permissions disimpan');
          return true;
        } else {
          print('Login gagal: ${data['message']}');
          return false;
        }
      } else {
        print('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }
}
