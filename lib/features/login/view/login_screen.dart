import 'package:flutter/material.dart';
import '../view_model/login_view_model.dart';
import '../model/user_model.dart';
import '../view_model/update_view_model.dart';
import '../model/update_model.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoginViewModel _viewModel = LoginViewModel();
  final UpdateViewModel _updateViewModel = UpdateViewModel();
  bool _isPasswordVisible = false;
  bool _isCheckingUpdate = false;
  String _errorMessage = '';
  bool _isLoading = false; // Untuk menangani loading state


  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);

    try {
      final updateInfo = await _updateViewModel.checkForUpdate();
      if (updateInfo != null && mounted) {
        _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa update: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  void _showUpdateDialog(UpdateInfo updateInfo) {
    int downloadProgress = 0;
    bool isDownloading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Pembaruan Tersedia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Versi baru: ${updateInfo.version}'),
                const SizedBox(height: 10),
                const Text('Perubahan:'),
                Text(updateInfo.changelog),
                if (isDownloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: downloadProgress / 100,
                  ),
                  Text('Downloading $downloadProgress%'),
                ],
              ],
            ),
            actions: [
              if (!isDownloading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Nanti'),
                ),
              TextButton(
                onPressed: isDownloading
                    ? null
                    : () async {
                  setState(() => isDownloading = true);
                  try {
                    // 1. Request permission
                    if (await Permission.requestInstallPackages.request() != PermissionStatus.granted) {
                      throw Exception('Install permission denied');
                    }

                    // 2. Download file
                    final file = await _updateViewModel.downloadUpdate(
                      updateInfo.fileName,
                          (progress) => setState(() => downloadProgress = progress),
                    );

                    if (file == null) throw Exception('Download failed');

                    // 3. Verifikasi file sebelum install
                    if (!file.existsSync() || await file.length() == 0) {
                      throw Exception('Downloaded file is invalid');
                    }

                    // 4. Install APK
                    final result = await OpenFile.open(file.path, type: 'application/vnd.android.package-archive');

                    if (result.type != ResultType.done) {
                      throw Exception('Install failed: ${result.message}');
                    }

                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                      setState(() => isDownloading = false);
                    }
                  }
                },
                child: Text(isDownloading ? 'Mengunduh...' : 'Perbarui'),
              ),
            ],
          );
        },
      ),
    );
  }


  void _login() async {
    // Clear previous errors
    _clearErrorMessage();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Validate empty fields
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Username dan password harus diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      User user = User(
        username: username,
        password: password,
      );

      bool isValid = await _viewModel.validateLogin(user);

      if (isValid) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage = 'Username atau password salah!');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearErrorMessage() {
    if (_errorMessage.isNotEmpty) {
      setState(() => _errorMessage = '');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi apakah keyboard sedang muncul
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    bool isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6D4D8C), // purple tone
                  Color(0xFFF9A825), // amber/orange tone
                ],
              ),
            ),
          ),

          // Welcome text
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 50),
              // Sembunyikan welcome text ketika keyboard muncul (opsional)
              opacity: isKeyboardVisible ? 0.0 : 1.0,
              child: Text(
                'Welcome to PPS!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Centered login card dengan animasi untuk keyboard
          AnimatedPadding(
            duration: const Duration(milliseconds: 50),
            curve: Curves.easeInOut,
            // Geser ke atas ketika keyboard muncul
            padding: EdgeInsets.only(
              bottom: isKeyboardVisible ? keyboardHeight * 0.7 : 0,
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 400,
                  height: 450,
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/icon_without_bg.png',
                        width: 120,
                        height: 120,
                      ),

                      Divider(
                        color: Colors.grey,      // Warna garis
                        thickness: 0.5,            // Ketebalan garis
                        height: 25,              // Tinggi space yang ditempati
                      ),

                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Copyright - tetap di posisi bawah
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 50),
              // Sembunyikan copyright ketika keyboard muncul (opsional)
              opacity: isKeyboardVisible ? 0.0 : 1.0,
              child: Text(
                'Copyright © 2025, Utama Corporation\nAll rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}