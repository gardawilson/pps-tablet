part of 'bs_v2_create_screen.dart';

// ─── Scan Input Dialog ─────────────────────────────────────────────────────

class _ScanInputDialog extends StatefulWidget {
  final BsV2CreateViewModel vm;
  const _ScanInputDialog({required this.vm});

  @override
  State<_ScanInputDialog> createState() => _ScanInputDialogState();
}

class _ScanInputDialogState extends State<_ScanInputDialog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabCtl;
  final TextEditingController _ctl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final MobileScannerController _scannerCtl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  Color? _flashColor;
  String? _scanError;
  bool _isProcessingScan = false;
  int _cameraQuarterTurns = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabCtl = TabController(length: 2, vsync: this);
    _tabCtl.addListener(() {
      if (_tabCtl.indexIsChanging) return;
      setState(() {}); // rebuild IndexedStack
      if (_tabCtl.index == 0) {
        _scannerCtl.start();
      } else {
        _scannerCtl.stop();
        _focus.requestFocus();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRotation());
  }

  @override
  void didChangeMetrics() => _updateRotation();

  void _updateRotation() {
    if (!mounted) return;
    final size = View.of(context).physicalSize;
    if (size.height > size.width && _cameraQuarterTurns != 0) {
      setState(() => _cameraQuarterTurns = 0);
      if (_tabCtl.index == 0) {
        _scannerCtl.stop();
        _scannerCtl.start();
      }
    }
  }

  void _toggleCameraRotation() {
    final next = _cameraQuarterTurns == 1 ? 3 : 1;
    setState(() => _cameraQuarterTurns = next);
    if (_tabCtl.index == 0) {
      _scannerCtl.stop();
      _scannerCtl.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtl.dispose();
    _ctl.dispose();
    _focus.dispose();
    _scannerCtl.dispose();
    super.dispose();
  }

  Future<void> _addManual() async {
    final code = _ctl.text.trim();
    if (code.isEmpty) return;
    await widget.vm.lookupLabel(code);
    if (!mounted) return;
    if (widget.vm.lookupError == null) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onScanDetect(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    final code = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessingScan = true;
      _scanError = null;
    });
    await widget.vm.lookupLabel(code);
    if (!mounted) return;

    if (widget.vm.lookupError == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _flashColor = Colors.red;
        _scanError = widget.vm.lookupError;
        _isProcessingScan = false;
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        setState(() {
          _flashColor = null;
          _scanError = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BsV2CreateViewModel>.value(
      value: widget.vm,
      child: Consumer<BsV2CreateViewModel>(
        builder: (ctx, vm, _) {
          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 40,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ───────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      decoration: const BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Scan / Input Label',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (vm.category != null)
                                Text(
                                  bsV2CategoryLabel(vm.category),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TabBar(
                            controller: _tabCtl,
                            indicatorColor: Colors.white,
                            indicatorWeight: 3,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white.withValues(
                              alpha: 0.55,
                            ),
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.camera_alt_outlined, size: 18),
                                text: 'Scan Kamera',
                                iconMargin: EdgeInsets.only(bottom: 4),
                              ),
                              Tab(
                                icon: Icon(Icons.keyboard_outlined, size: 18),
                                text: 'Input Manual',
                                iconMargin: EdgeInsets.only(bottom: 4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Tab content ──────────────────────────────────────
                    SizedBox(
                      height: 420,
                      child: IndexedStack(
                        index: _tabCtl.index,
                        children: [
                          // ── Tab 0: Scan Kamera ─────────────────────
                          Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: RotatedBox(
                                    quarterTurns: _cameraQuarterTurns,
                                    child: MobileScanner(
                                      controller: _scannerCtl,
                                      onDetect: _onScanDetect,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ScanFramePainter(),
                                ),
                              ),
                              if (_flashColor != null)
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: _flashColor!.withValues(alpha: 0.2),
                                  ),
                                ),
                              if (_isProcessingScan)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: Color(0x55000000),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_scanError != null)
                                Positioned(
                                  bottom: 16,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _scanError!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: _toggleCameraRotation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xCC000000),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.screen_rotation_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── Tab 1: Input Manual ────────────────────
                          SingleChildScrollView(
                            reverse: true,
                            padding: EdgeInsets.fromLTRB(
                              24,
                              24,
                              24,
                              MediaQuery.viewInsetsOf(ctx).bottom + 24,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kPrimary.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _kPrimary.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: _kPrimary.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Format: B.xxx / M.xxx / D.xxx',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _kPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _ctl,
                                  focusNode: _focus,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: 'Kode Label',
                                    hintText: 'B.0000000001',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    errorText: vm.lookupError,
                                    errorStyle: const TextStyle(fontSize: 11),
                                    errorMaxLines: 2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: _kBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: _kBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: _kPrimary,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: _kSurface,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    suffixIcon: _ctl.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 16,
                                            ),
                                            onPressed: () =>
                                                setState(() => _ctl.clear()),
                                          )
                                        : null,
                                  ),
                                  onSubmitted: (_) => _addManual(),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 48,
                                  child: Material(
                                    color: _kPrimary,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      onTap: vm.isLookingUp ? null : _addManual,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Center(
                                        child: vm.isLookingUp
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .add_circle_outline_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Tambah Label',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Scan Frame Painter ────────────────────────────────────────────────────

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLen = 30.0;
    const cornerRadius = 9.0;
    const strokeW = 3.5;

    final boxSize = size.shortestSide * 0.65;
    final center = Offset(size.width / 2, size.height / 2);
    final frameRect = Rect.fromCenter(
      center: center,
      width: boxSize,
      height: boxSize,
    );
    final left = frameRect.left;
    final top = frameRect.top;
    final right = frameRect.right;
    final bottom = frameRect.bottom;

    final dimPaint = Paint()..color = const Color(0x66000000);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final holeRect = RRect.fromRectAndRadius(
      frameRect,
      const Radius.circular(cornerRadius + 2),
    );
    final overlay = Path()
      ..addRect(fullRect)
      ..addRRect(holeRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, dimPaint);

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawTopLeft() {
      canvas.drawLine(
        Offset(left + cornerRadius, top),
        Offset(left + cornerRadius + cornerLen, top),
        paint,
      );
      canvas.drawLine(
        Offset(left, top + cornerRadius),
        Offset(left, top + cornerRadius + cornerLen),
        paint,
      );
      canvas.drawArc(
        Rect.fromLTWH(left, top, cornerRadius * 2, cornerRadius * 2),
        3.141592653589793,
        1.5707963267948966,
        false,
        paint,
      );
    }

    void drawTopRight() {
      canvas.drawLine(
        Offset(right - cornerRadius, top),
        Offset(right - cornerRadius - cornerLen, top),
        paint,
      );
      canvas.drawLine(
        Offset(right, top + cornerRadius),
        Offset(right, top + cornerRadius + cornerLen),
        paint,
      );
      canvas.drawArc(
        Rect.fromLTWH(
          right - cornerRadius * 2,
          top,
          cornerRadius * 2,
          cornerRadius * 2,
        ),
        -1.5707963267948966,
        1.5707963267948966,
        false,
        paint,
      );
    }

    void drawBottomLeft() {
      canvas.drawLine(
        Offset(left + cornerRadius, bottom),
        Offset(left + cornerRadius + cornerLen, bottom),
        paint,
      );
      canvas.drawLine(
        Offset(left, bottom - cornerRadius),
        Offset(left, bottom - cornerRadius - cornerLen),
        paint,
      );
      canvas.drawArc(
        Rect.fromLTWH(
          left,
          bottom - cornerRadius * 2,
          cornerRadius * 2,
          cornerRadius * 2,
        ),
        1.5707963267948966,
        1.5707963267948966,
        false,
        paint,
      );
    }

    void drawBottomRight() {
      canvas.drawLine(
        Offset(right - cornerRadius, bottom),
        Offset(right - cornerRadius - cornerLen, bottom),
        paint,
      );
      canvas.drawLine(
        Offset(right, bottom - cornerRadius),
        Offset(right, bottom - cornerRadius - cornerLen),
        paint,
      );
      canvas.drawArc(
        Rect.fromLTWH(
          right - cornerRadius * 2,
          bottom - cornerRadius * 2,
          cornerRadius * 2,
          cornerRadius * 2,
        ),
        0,
        1.5707963267948966,
        false,
        paint,
      );
    }

    drawTopLeft();
    drawTopRight();
    drawBottomLeft();
    drawBottomRight();

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.9),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(left, center.dy, boxSize, 2))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(left + 8, center.dy),
      Offset(right - 8, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Note Dialog ───────────────────────────────────────────────────────────

class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final TextEditingController _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: _kPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Transaksi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23),
                          ),
                        ),
                        Text(
                          'Opsional',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctl,
                maxLines: 2,
                minLines: 2,
                autofocus: true,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tulis catatan...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: _kSurface,
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: _kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: const Color(0xFF0A7349),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () =>
                            Navigator.of(context).pop(_ctl.text.trim()),
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
