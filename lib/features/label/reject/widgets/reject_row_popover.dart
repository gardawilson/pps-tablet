import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pps_tablet/core/services/dialog_service.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/label_popover_widgets.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/network/label_print_lock_api.dart';
import '../../../../core/services/label_print_sync_queue.dart';
import '../../../../core/utils/pdf_print_service.dart';
import '../../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../model/reject_header_model.dart';
import '../repository/reject_repository.dart';

class RejectRowPopover extends StatefulWidget {
  final RejectHeader header;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;
  final VoidCallback onAuditHistory;
  final VoidCallback onPartialInfo;

  const RejectRowPopover({
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
  State<RejectRowPopover> createState() => _RejectRowPopoverState();
}

class _RejectRowPopoverState extends State<RejectRowPopover> {
  static const _copyFeedbackDuration = Duration(milliseconds: 1200);
  bool _copied = false;
  Timer? _copiedResetTimer;

  void _runAndClose(VoidCallback action) {
    widget.onClose();
    action();
  }

  Future<void> _copyOnly() async {
    await Clipboard.setData(ClipboardData(text: widget.header.noReject));
    if (!mounted) return;

    _copiedResetTimer?.cancel();
    setState(() => _copied = true);
    _copiedResetTimer = Timer(_copyFeedbackDuration, () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  bool _isSortirRejectLabel() {
    final outputCode = (widget.header.outputCode ?? '').trim();
    return outputCode.startsWith('J.');
  }

  Future<void> _handleEdit() async {
    if (_isSortirRejectLabel()) {
      widget.onClose();
      await DialogService.instance.showError(
        title: 'Tidak Dapat Diedit',
        message:
            'Label yang berasal dari Sortir Reject tidak dapat diedit. Silakan buat label baru jika diperlukan perubahan.',
      );
      return;
    }
    _runAndClose(widget.onEdit);
  }

  Future<bool> _confirmResetPrintStatus() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Status Print'),
          content: Text(
            'Yakin reset status print untuk label ${widget.header.noReject} ke 0?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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
    final canEdit = perm.can('label_reject:update');
    final canDelete = perm.can('label_reject:delete');

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
                        Icons.delete_outline,
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
                            widget.header.noReject,
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
                            widget.header.namaRejectDisplay,
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
                onTap: () => _handleEdit(),
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

                  final noReject = widget.header.noReject;
                  final lockApi = LabelPrintLockApi();
                  final repo = RejectRepository(api: ApiClient());
                  final lockVm = context.read<LabelPrintLockSocketManager>();
                  final queue = context.read<LabelPrintSyncQueue>();
                  var isLockAcquired = false;
                  var isPrinted = false;

                  try {
                    await lockApi.acquire(noReject);
                    isLockAcquired = true;

                    await PdfPrintService(defaultSystem: 'pps').previewFromUrl(
                      context: rootCtx,
                      pdfUrl: Uri.parse(ApiConstants.rejectLabelPdf(noReject)),
                      title: noReject,
                      onPrinted: () {
                        isPrinted = true;
                        () async {
                          var needsIncrement = false;
                          var needsRelease = false;

                          try {
                            final count = await repo.markAsPrinted(noReject);
                            if (count != null) {
                              lockVm.setPrintCount(noReject, count);
                            }
                          } catch (_) {
                            needsIncrement = true;
                          }

                          try {
                            await lockApi.release(noReject);
                          } catch (_) {
                            needsRelease = true;
                          }

                          if (needsIncrement || needsRelease) {
                            await queue.enqueue(
                              feature: 'reject',
                              noLabel: noReject,
                              needsIncrement: needsIncrement,
                              needsReleaseLock: needsRelease,
                            );
                          }
                        }().ignore();
                      },
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    final msg = e.toString().replaceFirst('Exception: ', '');
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                  } finally {
                    if (isLockAcquired && !isPrinted) {
                      () async {
                        try {
                          await lockApi.release(noReject);
                        } catch (_) {
                          await queue.enqueue(
                            feature: 'reject',
                            noLabel: noReject,
                            needsReleaseLock: true,
                          );
                        }
                      }().ignore();
                    }
                  }
                }),
              ),
              divider,
              LabelPopoverMenuTile(
                icon: Icons.restart_alt_rounded,
                label: 'Reset Status Print',
                enabled: canDelete,
                tooltipWhenDisabled: 'Tidak punya izin reset status print',
                onTap: () async {
                  final isConfirmed = await _confirmResetPrintStatus();
                  if (!isConfirmed) return;

                  final messenger = ScaffoldMessenger.of(context);
                  final noReject = widget.header.noReject;
                  final repo = RejectRepository(api: ApiClient());
                  final lockVm = context.read<LabelPrintLockSocketManager>();
                  widget.onClose();

                  try {
                    final count = await repo.resetPrintStatus(noReject);
                    lockVm.setPrintCount(noReject, count ?? 0);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Status print berhasil direset'),
                      ),
                    );
                  } catch (e) {
                    final msg = e.toString().replaceFirst('Exception: ', '');
                    messenger.showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
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
