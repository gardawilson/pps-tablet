import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../model/update_model.dart';
import '../../view_model/update_view_model.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateViewModel vm;

  const UpdateDialog({
    super.key,
    required this.vm,
  });

  /// Tampilkan dialog untuk check & auto update dalam satu flow
  static Future<bool?> show(
      BuildContext context, {
        required UpdateViewModel vm,
      }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => UpdateDialog(vm: vm),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  // State machine
  UpdatePhase _phase = UpdatePhase.checking;

  // Update info
  UpdateInfo? _updateInfo;
  int _progress = 0;
  String? _errorText;

  // Animations
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _scaleController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCheckUpdate();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _startCheckUpdate() async {
    setState(() {
      _phase = UpdatePhase.checking;
      _errorText = null;
      _progress = 0;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final info = await widget.vm.checkForUpdate();
      if (!mounted) return;

      if (info == null) {
        // sudah versi terbaru
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        Navigator.of(context).pop(false);
        return;
      }

      setState(() {
        _updateInfo = info;
        _phase = UpdatePhase.updateAvailable;
      });

      // auto start download
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      await _startAutoUpdate();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
        _phase = UpdatePhase.checkError;
      });

      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _startAutoUpdate() async {
    final info = _updateInfo;
    if (info == null) return;

    setState(() {
      _phase = UpdatePhase.downloading;
      _errorText = null;
      _progress = 0;
    });

    try {
      // Permission: install unknown apps
      final st = await Permission.requestInstallPackages.status;
      if (!st.isGranted) {
        final r = await Permission.requestInstallPackages.request();
        if (!r.isGranted) {
          await openAppSettings();
          throw Exception(
            'Izin install APK belum aktif.\nBuka Settings > Install unknown apps untuk aplikasi ini.',
          );
        }
      }

      final file = await widget.vm.downloadUpdate(
        info,
            (p) {
          if (!mounted) return;
          setState(() => _progress = p.clamp(0, 100));
        },
      );

      if (file == null) throw Exception('Download gagal (file null)');
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('File download tidak valid');
      }

      // ✅ Tampilkan "Update Siap!" dulu
      setState(() => _phase = UpdatePhase.installing);

      // ✅ Tunggu 1.5 detik untuk user melihat success message
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      // ✅ Baru kemudian buka installer
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        throw Exception('Gagal membuka installer: ${result.message}');
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
        _phase = UpdatePhase.downloadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;

    return WillPopScope(
      onWillPop: () async => false,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 80 : 24,
            vertical: isLandscape ? 40 : 80,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: isLandscape
                  ? mq.size.height * 0.85
                  : mq.size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan close button (hanya untuk error state)
                if (_phase == UpdatePhase.downloadError ||
                    _phase == UpdatePhase.checkError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        tooltip: 'Tutup',
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24),

                // Content dengan scroll untuk landscape
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 32 : 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLottieAnimation(),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        Text(
                          _getTitle(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getSubtitle(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Version Badge
                        if (_shouldShowVersionBadge) ...[
                          _buildVersionBadge(),
                          const SizedBox(height: 16),
                        ],

                        // Changelog
                        if (_shouldShowChangelog) ...[
                          _buildChangelogSection(isLandscape),
                          const SizedBox(height: 16),
                        ],

                        // Progress Bar
                        if (_phase == UpdatePhase.downloading ||
                            _phase == UpdatePhase.installing) ...[
                          _buildProgressSection(),
                          const SizedBox(height: 16),
                        ],

                        // Checking Progress
                        if (_phase == UpdatePhase.checking) ...[
                          _buildCheckingProgress(),
                          const SizedBox(height: 16),
                        ],

                        // Error Message
                        if (_errorText != null) ...[
                          _buildErrorMessage(),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _shouldShowVersionBadge {
    return _updateInfo != null &&
        (_phase == UpdatePhase.updateAvailable ||
            _phase == UpdatePhase.downloading ||
            _phase == UpdatePhase.installing);
  }

  bool get _shouldShowChangelog {
    return _updateInfo != null &&
        _updateInfo!.changelog.trim().isNotEmpty &&
        (_phase == UpdatePhase.updateAvailable ||
            _phase == UpdatePhase.downloading ||
            _phase == UpdatePhase.installing);
  }

  String _getTitle() {
    switch (_phase) {
      case UpdatePhase.checking:
        return 'Memeriksa Pembaruan';
      case UpdatePhase.updateAvailable:
        return 'Pembaruan Tersedia!';
      case UpdatePhase.downloading:
        return 'Mengunduh Pembaruan';
      case UpdatePhase.installing:
        return 'Update Siap!';
      case UpdatePhase.checkError:
        return 'Gagal Memeriksa';
      case UpdatePhase.downloadError:
        return 'Update Gagal';
    }
  }

  String _getSubtitle() {
    switch (_phase) {
      case UpdatePhase.checking:
        return 'Menghubungi server untuk cek versi terbaru';
      case UpdatePhase.updateAvailable:
        return 'Versi baru tersedia, memulai download...';
      case UpdatePhase.downloading:
        return 'Mohon tunggu hingga proses download selesai';
      case UpdatePhase.installing:
        return 'File berhasil diunduh, membuka installer...';
      case UpdatePhase.checkError:
        return 'Tidak dapat terhubung ke server update';
      case UpdatePhase.downloadError:
        return 'Tutup dan buka kembali aplikasi untuk mencoba lagi';
    }
  }

  Widget _buildLottieAnimation() {
    String asset;
    bool repeat;

    switch (_phase) {
      case UpdatePhase.checking:
        asset = 'assets/animations/loading.json';
        repeat = true;
        break;
      case UpdatePhase.updateAvailable:
        asset = 'assets/animations/success.json';
        repeat = true;
        break;
      case UpdatePhase.downloading:
        asset = 'assets/animations/loading.json';
        repeat = true;
        break;
      case UpdatePhase.installing:
        asset = 'assets/animations/success.json';
        repeat = true; // ✅ Loop terus saat installing
        break;
      case UpdatePhase.checkError:
      case UpdatePhase.downloadError:
        asset = 'assets/animations/error.json';
        repeat = false;
        break;
    }

    return SizedBox(
      width: _phase == UpdatePhase.checking ? 100 : 120,
      height: _phase == UpdatePhase.checking ? 100 : 120,
      child: Lottie.asset(
        key: ValueKey(_phase), // ✅ Force rebuild per phase change
        asset,
        repeat: repeat,
        frameRate: FrameRate(60),
      ),
    );
  }

  Widget _buildVersionBadge() {
    final info = _updateInfo;
    if (info == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0D47A1).withOpacity(0.08),
              const Color(0xFF1976D2).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0D47A1).withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.new_releases_rounded,
                color: Color(0xFF0D47A1),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Versi Terbaru',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0D47A1),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.latestVersion,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D47A1),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangelogSection(bool isLandscape) {
    final info = _updateInfo;
    if (info == null) return const SizedBox.shrink();

    final changelog = info.changelog.trim();
    if (changelog.isEmpty) return const SizedBox.shrink();

    final items = changelog
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: isLandscape ? 200 : 300,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.article_outlined,
                    color: Colors.grey.shade700, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Changelog',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600 + (idx * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(-20 * (1 - value), 0),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D47A1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: (_progress.clamp(0, 100)) / 100),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _progress >= 100
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [
                            const Color(0xFF0D47A1),
                            const Color(0xFF1976D2)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: (_progress >= 100
                                ? Colors.green.shade400
                                : const Color(0xFF0D47A1))
                                .withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Progress info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Icon berubah berdasarkan progress dan phase
                if (_progress < 100)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 2 * 3.14159,
                        child: Icon(
                          Icons.download_rounded,
                          size: 20,
                          color: const Color(0xFF0D47A1),
                        ),
                      );
                    },
                    onEnd: () {
                      if (mounted) setState(() {});
                    },
                  ),

                if (_progress >= 100)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: Colors.green.shade600,
                        ),
                      );
                    },
                  ),

                const SizedBox(width: 10),

                // Text berubah berdasarkan phase
                Text(
                  _progress >= 100
                      ? (_phase == UpdatePhase.installing
                      ? 'Siap Install!'
                      : 'Download Selesai!')
                      : 'Mengunduh Update',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _progress >= 100
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            // Percentage badge
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 1.0,
                    end: value >= 100 ? 1.05 : 1.0,
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: value >= 100
                              ? Colors.green.shade50
                              : const Color(0xFF0D47A1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: value >= 100
                                ? Colors.green.shade300
                                : const Color(0xFF0D47A1).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '$value%',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: value >= 100
                                ? Colors.green.shade700
                                : const Color(0xFF0D47A1),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),

        // Helper text - berubah berdasarkan state
        if (_progress > 0 && _progress < 100) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Mohon tunggu, proses download sedang berjalan...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ✅ FIXED: Success message saat installing phase
        if (_progress >= 100 && _phase == UpdatePhase.installing) ...[
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            key: const ValueKey('installing-message'), // ✅ Tambah key untuk stability
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, animValue, child) {
              // ✅ FIX: Gunakan animValue untuk scale DAN opacity
              return Transform.scale(
                scale: 0.8 + (animValue * 0.2), // Scale dari 0.8 ke 1.0
                child: Opacity(
                  opacity: animValue.clamp(0.0, 1.0), // ✅ Clamp untuk safety
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.install_mobile_rounded,
                          size: 18,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Membuka installer...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCheckingProgress() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFFE3F2FD),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mohon tunggu sebentar...',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.red.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorText ?? 'Unknown error',
                style: TextStyle(
                    fontSize: 13, color: Colors.red.shade700, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// State machine untuk update flow
enum UpdatePhase {
  checking,
  updateAvailable,
  downloading,
  installing,
  checkError,
  downloadError,
}
