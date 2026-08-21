import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'success_status_dialog.dart' show StatusAction;

const _kWarningAccent = Color(0xFFF59E0B);

/// Dialog status "warning" — kerangka animasi & layout identik dengan
/// `SuccessStatusDialog`/`ErrorStatusDialog` (fade+scale masuk, stagger
/// title/message/tombol), pakai `assets/animations/warning.json`. Mendukung
/// `actions` custom (mis. "Batal"/"Ya, Lanjutkan") seperti
/// `SuccessStatusDialog`, dipakai untuk dialog konfirmasi yang butuh
/// keputusan user, bukan sekadar notifikasi.
class WarningStatusDialog extends StatefulWidget {
  final String title;
  final String message;
  final Widget? extraContent;
  final double maxWidth;
  final List<StatusAction>? actions;

  const WarningStatusDialog({
    super.key,
    required this.title,
    required this.message,
    this.extraContent,
    this.maxWidth = 380,
    this.actions,
  });

  @override
  State<WarningStatusDialog> createState() => _WarningStatusDialogState();
}

class _WarningStatusDialogState extends State<WarningStatusDialog>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtl;
  late final AnimationController _contentCtl;

  late final Animation<double> _dialogScale;
  late final Animation<double> _dialogFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
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

    _iconScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _iconOpacity = _fade(0.0, 0.4);
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

    final buttons = (widget.actions == null || widget.actions!.isEmpty)
        ? <StatusAction>[
            StatusAction(
              label: 'OK',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]
        : widget.actions!;

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
                  ScaleTransition(
                    scale: _iconScale,
                    child: FadeTransition(
                      opacity: _iconOpacity,
                      child: Lottie.asset(
                        'assets/animations/warning.json',
                        width: 100,
                        height: 100,
                        repeat: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  if (widget.extraContent != null) ...[
                    const SizedBox(height: 14),
                    _staggered(
                      opacity: _msgOpacity,
                      slide: _msgSlide,
                      child: widget.extraContent!,
                    ),
                  ],
                  const SizedBox(height: 28),
                  _staggered(
                    opacity: _btnOpacity,
                    slide: _btnSlide,
                    child: Column(
                      children: [
                        Divider(height: 1, color: Colors.grey.shade100),
                        const SizedBox(height: 20),
                        buttons.length == 1
                            ? SizedBox(
                                width: double.infinity,
                                child: _buildButton(buttons.first),
                              )
                            : Row(
                                children: [
                                  for (int i = 0; i < buttons.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 10),
                                    Expanded(child: _buildButton(buttons[i])),
                                  ],
                                ],
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

  Widget _buildButton(StatusAction a) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
    const vPad = EdgeInsets.symmetric(vertical: 13);

    if (a.isPrimary) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kWarningAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: shape,
          padding: vPad,
        ),
        onPressed: a.onPressed,
        child: Text(
          a.label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade200),
        foregroundColor: const Color(0xFF4A5568),
        shape: shape,
        padding: vPad,
      ),
      onPressed: a.onPressed,
      child: Text(
        a.label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
