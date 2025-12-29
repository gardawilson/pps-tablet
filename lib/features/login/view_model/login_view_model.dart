// lib/features/login/view_model/login_view_model.dart
import '../data/login_repository.dart';
import '../model/login_result.dart';
import '../model/user_model.dart';

class LoginViewModel {
  LoginViewModel({LoginRepository? repo}) : _repo = repo ?? LoginRepository();
  final LoginRepository _repo;

  Future<LoginResult> validateLogin(User user) async {
    // ViewModel hanya validasi ringan + delegasi ke repository
    if (user.username.trim().isEmpty || user.password.isEmpty) {
      return LoginResult(
        success: false,
        message: 'Username dan password harus diisi',
        errorType: 'validation',
        detailCode: 'validation',
      );
    }

    // repository sudah return LoginResult (tidak throw)
    return _repo.login(user);
  }
}
