// lib/features/production/bahan_baku/widgets/bahan_baku_pallet_popover.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/label_popover_widgets.dart';
import '../../../../core/utils/pdf_print_service.dart';
import '../model/bahan_baku_pallet.dart';

class BahanBakuPalletPopover extends StatefulWidget {
  final BahanBakuPallet pallet;
  final VoidCallback onClose;
  final VoidCallback onInputQc;
  final VoidCallback? onAfterPrint;

  const BahanBakuPalletPopover({
    super.key,
    required this.pallet,
    required this.onClose,
    required this.onInputQc,
    this.onAfterPrint,
  });

  @override
  State<BahanBakuPalletPopover> createState() => _BahanBakuPalletPopoverState();
}

class _BahanBakuPalletPopoverState extends State<BahanBakuPalletPopover> {
  static const _copyFeedbackDuration = Duration(milliseconds: 1200);
  bool _copied = false;
  Timer? _copiedResetTimer;

  void _runAndClose(VoidCallback action) {
    widget.onClose();
    action();
  }

  Future<void> _copyNoPallet() async {
    await Clipboard.setData(ClipboardData(text: widget.pallet.noPallet));
    if (!mounted) return;

    _copiedResetTimer?.cancel();
    setState(() => _copied = true);
    _copiedResetTimer = Timer(_copyFeedbackDuration, () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  void dispose() {
    _copiedResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const atlasBlue = Color(0xFF0C66E4);
    const atlasBlueSubtle = Color(0xFFE9F2FF);
    const atlasSurface = Color(0xFFF7F8F9);
    const atlasBorder = Color(0xFFDCDFE4);
    const atlasText = Color(0xFF172B4D);
    const atlasSubtleText = Color(0xFF44546F);

    final divider = const Divider(
      height: 0,
      thickness: 0.8,
      color: atlasBorder,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: const Color(0xFF091E42).withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: const BoxDecoration(
                  color: atlasBlueSubtle,
                  border: Border(bottom: BorderSide(color: atlasBorder)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: atlasBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: atlasBlue.withOpacity(0.24)),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: atlasBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.pallet.noBahanBaku} - ${widget.pallet.noPallet}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: atlasText,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.pallet.namaJenisPlastik,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: atlasSubtleText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Salin',
                      onPressed: _copyNoPallet,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          key: ValueKey(_copied),
                          color: atlasBlue,
                          size: 18,
                        ),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: atlasBorder),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: atlasSurface,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildInfoQcCard()],
                ),
              ),
              divider,
              LabelPopoverMenuTile(
                icon: Icons.science_outlined,
                label: 'Input QC',
                enabled: true,
                onTap: () => _runAndClose(widget.onInputQc),
              ),
              divider,
              LabelPopoverMenuTile(
                icon: Icons.print_outlined,
                label: 'Print',
                enabled: true,
                onTap: () => _runAndClose(() async {
                  final rootCtx = Navigator.of(
                    context,
                    rootNavigator: true,
                  ).context;
                  final pdfService = PdfPrintService(defaultSystem: 'pps');
                  final success = await pdfService.directPrintReport80mm(
                    context: rootCtx,
                    reportName: 'LabelPalletBB',
                    query: {
                      'NoBahanBaku': widget.pallet.noBahanBaku,
                      'NoPallet': widget.pallet.noPallet,
                    },
                  );
                  if (success) {
                    widget.onAfterPrint?.call();
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoQcCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCDFE4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quality Control',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF44546F),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCardItem(
                  'Tenggelam',
                  _formatTenggelam(widget.pallet.tenggelam),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCardItem(
                  'Density 1',
                  _formatQcValue(widget.pallet.density),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCardItem(
                  'Density 2',
                  _formatQcValue(widget.pallet.density2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCardItem(
                  'Density 3',
                  _formatQcValue(widget.pallet.density3),
                ),
              ),
            ],
          ),
          if ((widget.pallet.keterangan ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCardItem(
              'Keterangan',
              widget.pallet.keterangan!.trim(),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardItem(
    String label,
    String value, {
    Color? valueColor,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEBECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B778C),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF172B4D),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTenggelam(double? value) {
    if (value == null) return '-';
    if ((value - 5).abs() < 0.0001 || (value - 0.05).abs() < 0.0001) {
      return '5%';
    }
    if ((value - 10).abs() < 0.0001 || (value - 0.10).abs() < 0.0001) {
      return '10%';
    }
    return '${value.toStringAsFixed(2)}%';
  }

  String _formatQcValue(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(3);
  }
}
