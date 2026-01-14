// lib/features/shared/bj_jual/widgets/bj_jual_row_popover.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/view_model/permission_view_model.dart';
import '../model/bj_jual_model.dart';

class BJJualRowPopover extends StatelessWidget {
  final BJJual row;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // optional (kalau nanti ada layar detail / input label)
  final VoidCallback? onInput;
  final VoidCallback? onPrint;

  const BJJualRowPopover({
    super.key,
    required this.row,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    this.onInput,
    this.onPrint,
  });

  void _runAndClose(VoidCallback action) {
    onClose();
    action();
  }

  Future<void> _copyOnly(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: row.noBJJual));
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      SnackBar(
        content: Text('noBJJual "${row.noBJJual}" disalin'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider =
    Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);

    final perm = context.watch<PermissionViewModel>();

    // ✅ GANTI permission key sesuai sistem kamu
    // contoh: 'bj_jual:update' / 'bj_jual:delete'
    final canEdit = perm.can('label_crusher:update') && !row.isLocked;
    final canDelete = perm.can('label_crusher:delete') && !row.isLocked;

    final String? lockHint = row.isLocked ? row.lockStatusMessage : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 340),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 6,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header band
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: row.isLocked
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [Colors.teal.shade400, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        row.isLocked ? Icons.lock : Icons.receipt_long_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.noBJJual,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${row.namaPembeli} • ${row.tanggalTextShort}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.isLocked
                                ? row.lockInfoText
                                : (row.remark?.isNotEmpty == true
                                ? row.remark!
                                : '—'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.copy_outlined,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      onPressed: () => _copyOnly(context),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              divider,

              // Lock warning banner
              if (row.isLocked) ...[
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Data terkunci - Edit/Hapus dinonaktifkan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                divider,
              ],

              // Optional: Input/Detail
              if (onInput != null) ...[
                _MenuTile(
                  icon: Icons.input,
                  label: 'Input',
                  enabled: canEdit,
                  disabledHint: lockHint ?? 'Tidak punya izin edit',
                  onTap: () => _runAndClose(onInput!),
                ),
                divider,
              ],

              // Edit
              _MenuTile(
                icon: Icons.edit_outlined,
                label: 'Edit',
                enabled: canEdit,
                disabledHint: lockHint ?? 'Tidak punya izin edit',
                onTap: () => _runAndClose(onEdit),
              ),
              divider,

              // Delete
              _MenuTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                enabled: canDelete,
                disabledHint: lockHint ?? 'Tidak punya izin hapus',
                iconColor: canDelete ? Colors.red.shade600 : null,
                textStyle: TextStyle(
                  color: canDelete ? Colors.red.shade600 : Colors.grey,
                ),
                onTap: () => _runAndClose(onDelete),
              ),

              // Optional Print
              if (onPrint != null) ...[
                divider,
                _MenuTile(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  enabled: true,
                  onTap: () => _runAndClose(onPrint!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledHint;
  final Color? iconColor;
  final TextStyle? textStyle;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.disabledHint,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
    enabled ? (iconColor ?? theme.iconTheme.color) : Colors.grey;

    final baseStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    final effectiveTextStyle = (textStyle ?? baseStyle).copyWith(
      color: enabled ? (textStyle?.color ?? baseStyle.color) : Colors.grey,
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: effectiveIconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: effectiveTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return InkWell(
        onTap: () {
          if ((disabledHint ?? '').isEmpty) return;
          final m = ScaffoldMessenger.maybeOf(context);
          m?.hideCurrentSnackBar();
          m?.showSnackBar(
            SnackBar(
              content: Text(disabledHint!),
              duration: const Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Opacity(opacity: 0.55, child: content),
      );
    }

    return InkWell(onTap: onTap, child: content);
  }
}
