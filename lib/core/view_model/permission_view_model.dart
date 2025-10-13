import 'package:flutter/foundation.dart';
import '../services/permission_storage.dart';

class PermissionViewModel extends ChangeNotifier {
  List<String> _permissions = [];

  List<String> get permissions => _permissions;

  Future<void> loadPermissions() async {
    _permissions = await PermissionStorage.getPermissions();
    notifyListeners();
  }

  bool can(String code) => _permissions.contains(code);

  void clear() {
    _permissions.clear();
    notifyListeners();
  }
}
