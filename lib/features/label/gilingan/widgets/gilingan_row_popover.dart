import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/label_popover_widgets.dart';
import '../../../../core/utils/pdf_print_service.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../model/gilingan_header_model.dart';
import '../repository/gilingan_repository.dart';

class GilinganRowPopover extends StatefulWidget {
  final GilinganHeader header;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;
  final VoidCallback onAuditHistory;
  final VoidCallback onPartialInfo;

  const GilinganRowPopover({
    super.key,
    required this.header,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
    required this.onAuditHistory,
    required this.onPartialInfo,
  });

  @override
  State<GilinganRowPopover> createState() => _GilinganRowPopoverState();
}

class _GilinganRowPopoverState extends State<GilinganRowPopover> {
  static const _copyFeedbackDuration = Duration(milliseconds: 1200);
  bool _copied = false;
  Timer? _copiedResetTimer;

  void _runAndClose(VoidCallback action) {
    widget.onClose();
    action();
  }

  Future<void> _copyOnly() async {
    await Clipboard.setData(ClipboardData(text: widget.header.noGilingan));
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
    const atlasBorder = Color(0xFFDCDFE4);
    const atlasText = Color(0xFF172B4D);
    const atlasSubtleText = Color(0xFF44546F);

    final divider = const Divider(
      height: 0,
      thickness: 0.8,
      color: atlasBorder,
    );

    final perm = context.watch<PermissionViewModel>();
    final canEdit = perm.can('label_gilingan:update');
    final canDelete = perm.can('label_gilingan:delete');

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: const Color(0xFF091E42).withValues(alpha: 0.18),
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
                        color: atlasBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: atlasBlue.withValues(alpha: 0.24),
                        ),
                      ),
                      child: const Icon(
                        Icons.settings_input_component_outlined,
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
                            widget.header.noGilingan,
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
                            (widget.header.namaGilingan ?? '').trim().isEmpty
                                ? 'Gilingan'
                                : widget.header.namaGilingan!.trim(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: atlasSubtleText,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Salin',
                      onPressed: _copyOnly,
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
              divider,
              LabelPopoverMenuTile(
                icon: Icons.history_rounded,
                label: 'History',
                enabled: true,
                onTap: () => _runAndClose(widget.onAuditHistory),
              ),
              divider,
              LabelPopoverMenuTile(
                icon: Icons.splitscreen_outlined,
                label: 'Info Partial',
                enabled: widget.header.isPartialBool,
                tooltipWhenDisabled: 'Label ini tidak memiliki partial',
                onTap: () => _runAndClose(widget.onPartialInfo),
              ),
              divider,
              LabelPopoverMenuTile(
                icon: Icons.edit_outlined,
                label: 'Edit',
                enabled: canEdit,
                tooltipWhenDisabled: 'Tidak punya izin edit',
                onTap: () => _runAndClose(widget.onEdit),
              ),
              divider,
              LabelPopoverMenuTile(
                icon: Icons.print_outlined,
                label: 'Print',
                enabled: true,
                onTap: () => _runAndClose(() {
                  final rootCtx = Navigator.of(
                    context,
                    rootNavigator: true,
                  ).context;

                  PdfPrintService(defaultSystem: 'pps').previewReport80mm(
                    context: rootCtx,
                    reportName: 'CrLabelGilingan',
                    query: {'NoGilingan': widget.header.noGilingan},
                    title: widget.header.noGilingan,
                    onPrinted: () {
                      GilinganRepository().markAsPrinted(
                        widget.header.noGilingan,
                      );
                    },
                  );
                }),
              ),
              divider,
              LabelPopoverMenuTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                enabled: canDelete,
                tooltipWhenDisabled: 'Tidak punya izin hapus',
                iconColor: const Color(0xFFC9372C),
                textStyle: const TextStyle(
                  color: Color(0xFFC9372C),
                  fontWeight: FontWeight.w600,
                ),
                onTap: () => _runAndClose(widget.onDelete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
