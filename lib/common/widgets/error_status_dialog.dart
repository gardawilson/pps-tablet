import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ErrorStatusDialog extends StatefulWidget {
  final String title;
  final String message;
  final double maxWidth;

  const ErrorStatusDialog({
    super.key,
    required this.title,
    required this.message,
    this.maxWidth = 380,
  });

  @override
  State<ErrorStatusDialog> createState() => _ErrorStatusDialogState();
}

class _ErrorStatusDialogState extends State<ErrorStatusDialog>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtl;
  late final AnimationController _contentCtl;

  late final Animation<double> _dialogScale;
  late final Animation<double> _dialogFade;
  late final Animation<double> _lottieScale;
  late final Animation<double> _lottieOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _msgOpacity;
  late final Animation<Offset> _msgSlide;
  late final Animation<double> _btnOpacity;
  late final Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();

    _enterCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _dialogScale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterCtl, curve: Curves.easeOutCubic));
    _dialogFade = CurvedAnimation(
      parent: _enterCtl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _contentCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _lottieScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _lottieOpacity = _fade(0.0, 0.4);
    _titleOpacity = _fade(0.25, 0.65);
    _titleSlide = _slide(0.25, 0.65, 0.08);
    _msgOpacity = _fade(0.42, 0.78);
    _msgSlide = _slide(0.42, 0.78, 0.08);
    _btnOpacity = _fade(0.62, 1.0);
    _btnSlide = _slide(0.62, 1.0, 0.06);

    _enterCtl.forward();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _contentCtl.forward();
    });
  }

  Animation<double> _fade(double b, double e) => CurvedAnimation(
    parent: _contentCtl,
    curve: Interval(b, e, curve: Curves.easeOutCubic),
  );

  Animation<Offset> _slide(double b, double e, double dy) =>
      Tween<Offset>(begin: Offset(0, dy), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _contentCtl,
          curve: Interval(b, e, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _enterCtl.dispose();
    _contentCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = math.min(widget.maxWidth, screenW * 0.88);

    return FadeTransition(
      opacity: _dialogFade,
      child: ScaleTransition(
        scale: _dialogScale,
        child: Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: dialogW,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lottie
                  ScaleTransition(
                    scale: _lottieScale,
                    child: FadeTransition(
                      opacity: _lottieOpacity,
                      child: Lottie.asset(
                        'assets/animations/error.json',
                        width: 100,
                        height: 100,
                        repeat: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  _staggered(
                    opacity: _titleOpacity,
                    slide: _titleSlide,
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Message
                  _staggered(
                    opacity: _msgOpacity,
                    slide: _msgSlide,
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF8A94A6),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _staggered(
                    opacity: _btnOpacity,
                    slide: _btnSlide,
                    child: Column(
                      children: [
                        Divider(height: 1, color: Colors.grey.shade100),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _staggered({
    required Animation<double> opacity,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return SlideTransition(
      position: slide,
      child: FadeTransition(opacity: opacity, child: child),
    );
  }
}
