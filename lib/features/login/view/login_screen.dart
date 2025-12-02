import 'package:flutter/material.dart';
import '../view_model/login_view_model.dart';
import '../model/user_model.dart';
import '../view_model/update_view_model.dart';
import '../model/update_model.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/view_model/permission_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final LoginViewModel _viewModel = LoginViewModel();
  final UpdateViewModel _updateViewModel = UpdateViewModel();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isPasswordVisible = false;
  bool _isCheckingUpdate = false;
  String _errorMessage = '';
  String _errorType = ''; // 'auth', 'network', 'server', 'unknown'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkForUpdates();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);

    try {
      final updateInfo = await _updateViewModel.checkForUpdate();
      if (updateInfo != null && mounted) {
        _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memeriksa update: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
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
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Pembaruan Tersedia',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Versi baru: ${updateInfo.version}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Perubahan:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  updateInfo.changelog,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: downloadProgress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mengunduh... $downloadProgress%',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isDownloading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Nanti'),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isDownloading
                    ? null
                    : () async {
                  setDialogState(() => isDownloading = true);
                  try {
                    if (await Permission.requestInstallPackages.request() !=
                        PermissionStatus.granted) {
                      throw Exception('Install permission denied');
                    }

                    final file = await _updateViewModel.downloadUpdate(
                      updateInfo.fileName,
                          (progress) =>
                          setDialogState(() => downloadProgress = progress),
                    );

                    if (file == null) throw Exception('Download failed');

                    if (!file.existsSync() || await file.length() == 0) {
                      throw Exception('Downloaded file is invalid');
                    }

                    final result = await OpenFile.open(
                      file.path,
                      type: 'application/vnd.android.package-archive',
                    );

                    if (result.type != ResultType.done) {
                      throw Exception('Install failed: ${result.message}');
                    }

                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setDialogState(() => isDownloading = false);
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
    _clearErrorMessage();

    // Unfocus untuk menutup keyboard
    _usernameFocusNode.unfocus();
    _passwordFocusNode.unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Username dan password harus diisi';
        _errorType = 'validation';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = User(username: username, password: password);
      final result = await _viewModel.validateLogin(user);

      if (result.success) {
        if (!mounted) return;

        final permVm = context.read<PermissionViewModel>();
        await permVm.loadPermissions();

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = result.message;
          _errorType = result.errorType;
        });

        // Show detailed error dialog for network/server errors
        if (result.errorType == 'network' || result.errorType == 'server') {
          _showErrorDialog(result.message, result.errorType);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan tidak terduga';
        _errorType = 'unknown';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message, String errorType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              errorType == 'network'
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              errorType == 'network' ? 'Koneksi Bermasalah' : 'Server Error',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            if (errorType == 'network') ...[
              const Text(
                'Saran:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Periksa koneksi internet Anda'),
              const Text('• Pastikan server dapat dijangkau'),
              const Text('• Coba lagi dalam beberapa saat'),
            ] else ...[
              const Text(
                'Saran:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Hubungi administrator sistem'),
              const Text('• Coba lagi dalam beberapa menit'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _login(); // Retry login
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _clearErrorMessage() {
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
        _errorType = '';
      });
    }
  }

  Color _getErrorColor() {
    switch (_errorType) {
      case 'auth':
        return Colors.red;
      case 'network':
        return Colors.orange;
      case 'server':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  IconData _getErrorIcon() {
    switch (_errorType) {
      case 'auth':
        return Icons.lock_outline;
      case 'network':
        return Icons.wifi_off_rounded;
      case 'server':
        return Icons.cloud_off_rounded;
      default:
        return Icons.error_outline;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          _usernameFocusNode.unfocus();
          _passwordFocusNode.unfocus();
        },
        child: Stack(
          children: [
            const _GradientBackground(),

            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isKeyboardVisible ? 0.0 : 1.0,
                  child: const Text(
                    'Welcome to PPS!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isKeyboardVisible
                  ? (screenHeight - 480 - keyboardHeight) / 2
                  : (screenHeight - 480) / 2,
              left: 0,
              right: 0,
              bottom: 100,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildLoginCard(isKeyboardVisible),
              ),
            ),

            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isKeyboardVisible ? 0.0 : 1.0,
                  child: Text(
                    'Copyright © 2025, Utama Corporation\nAll rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            if (_isCheckingUpdate)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(bool isKeyboardVisible) {
    return Center(
      child: Container(
        width: 400,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isKeyboardVisible ? 80 : 120,
              width: isKeyboardVisible ? 80 : 120,
              child: Image.asset(
                'assets/images/icon_without_bg.png',
                fit: BoxFit.contain,
              ),
            ),

            Divider(
              color: Colors.grey[300],
              thickness: 1,
              height: 32,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearErrorMessage(),
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D47A1),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _clearErrorMessage(),
              onSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D47A1),
                    width: 2,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),

            // Enhanced Error message with icon and color coding
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _errorMessage.isNotEmpty ? 60 : 0,
              child: _errorMessage.isNotEmpty
                  ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getErrorColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getErrorColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getErrorIcon(),
                        color: _getErrorColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: _getErrorColor(),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6D4D8C),
            Color(0xFFF9A825),
          ],
        ),
      ),
    );
  }
}