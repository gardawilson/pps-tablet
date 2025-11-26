// lib/features/production/crusher/widgets/crusher_production_row_popover.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/pdf_print_service.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../model/crusher_production_model.dart';

class CrusherProductionRowPopover extends StatelessWidget {
  final CrusherProduction row;
  final VoidCallback onClose;
  final VoidCallback onInput;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const CrusherProductionRowPopover({
    super.key,
    required this.row,
    required this.onClose,
    required this.onInput,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  });

  void _runAndClose(VoidCallback action) {
    onClose();
    action();
  }

  Future<void> _copyOnly(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: row.noCrusherProduksi));
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      SnackBar(
        content: Text('NoCrusherProduksi "${row.noCrusherProduksi}" disalin'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);

    // Permissions (adjust keys to match your backend ACL if needed)
    final perm = context.watch<PermissionViewModel>();
    final canEdit   = perm.can('label_crusher:update');
    final canDelete = perm.can('label_crusher:delete');

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600], // ⬅️ CHANGED: color theme
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: const Icon(Icons.construction_outlined, color: Colors.white, size: 20), // ⬅️ CHANGED: icon
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NoCrusherProduksi
                          Text(
                            row.noCrusherProduksi, // ⬅️ CHANGED
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          // Mesin / Operator
                          Text(
                            '${row.namaMesin} • ${row.namaOperator}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          // ⬅️ NEW: Show outputs count if available
                          if (row.outputNoCrusherList.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Output: ${row.outputNoCrusherList.length} item',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Copy NoCrusherProduksi (no tooltip)
                    IconButton(
                      icon: Icon(Icons.copy_outlined, color: Colors.white.withOpacity(0.9)),
                      onPressed: () => _copyOnly(context),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              divider,

              // Input
              _MenuTile(
                icon: Icons.input,
                label: 'Input',
                enabled: canEdit,
                disabledHint: 'Tidak punya izin edit',
                onTap: () => _runAndClose(onInput),
              ),
              divider,

              // Edit
              _MenuTile(
                icon: Icons.edit_outlined,
                label: 'Edit',
                enabled: canEdit,
                disabledHint: 'Tidak punya izin edit',
                onTap: () => _runAndClose(onEdit),
              ),
              divider,

              // Delete
              _MenuTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                enabled: canDelete,
                disabledHint: 'Tidak punya izin hapus',
                iconColor: canDelete ? Colors.red.shade600 : null,
                textStyle: TextStyle(
                  color: canDelete ? Colors.red.shade600 : Colors.grey,
                ),
                onTap: () => _runAndClose(onDelete),
              ),
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
    final effectiveIconColor = enabled ? (iconColor ?? theme.iconTheme.color) : Colors.grey;
    final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
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
      // No Tooltip here; show a brief SnackBar if user taps a disabled action.
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