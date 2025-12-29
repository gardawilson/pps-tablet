// lib/features/login/model/login_result.dart
class LoginResult {
  final bool success;
  final String message;

  /// auth | validation | network | server | unknown
  final String errorType;

  /// backend_offline | dns | internet_offline | timeout | server_503 | server_500 | server_error | network_error | unknown
  final String detailCode;

  LoginResult({
    required this.success,
    required this.message,
    required this.errorType,
    required this.detailCode,
  });

  factory LoginResult.ok([String msg = 'Login berhasil']) => LoginResult(
    success: true,
    message: msg,
    errorType: '',
    detailCode: '',
  );
}
