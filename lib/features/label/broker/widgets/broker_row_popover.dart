import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../model/broker_header_model.dart';

class BrokerRowPopover extends StatelessWidget {
  final BrokerHeader header;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const BrokerRowPopover({
    super.key,
    required this.header,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  });

  void _runAndClose(VoidCallback action) {
    onClose();
    action();
  }

  Future<void> _copyOnly(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: header.noBroker));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('NoBroker "${header.noBroker}" disalin'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);

    // ⬇️ ambil izin sekali
    final perm = context.watch<PermissionViewModel>();
    final canEdit   = perm.can('label_broker:update');
    final canDelete = perm.can('label_broker:delete');

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header info - Blue Gradient Design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(
                      Icons.label,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          header.noBroker,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          header.namaJenisPlastik,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Copy Button
                  IconButton(
                    tooltip: 'Salin NoBroker',
                    icon: Icon(Icons.copy_outlined, color: Colors.white.withOpacity(0.9)),
                    onPressed: () => _copyOnly(context),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            divider,

            // Edit (dikunci oleh permission)
            _MenuTile(
              icon: Icons.edit_outlined,
              label: 'Edit',
              enabled: canEdit,
              tooltipWhenDisabled: 'Tidak punya izin edit',
              onTap: () => _runAndClose(onEdit),
            ),
            divider,

            // Print (contoh tanpa izin)
            _MenuTile(
              icon: Icons.print_outlined,
              label: 'Print',
              enabled: true,
              onTap: () => _runAndClose(onPrint),
            ),
            divider,

            // Hapus (destruktif, dikunci permission)
            _MenuTile(
              icon: Icons.delete_outline,
              label: 'Delete',
              enabled: canDelete,
              tooltipWhenDisabled: 'Tidak punya izin hapus',
              iconColor: canDelete ? Colors.red.shade600 : null,
              textStyle: TextStyle(
                color: canDelete ? Colors.red.shade600 : Colors.grey,
              ),
              onTap: () => _runAndClose(onDelete),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile menu dengan state enabled/disabled yang jelas
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltipWhenDisabled;
  final Color? iconColor;
  final TextStyle? textStyle;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.tooltipWhenDisabled,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = enabled ? (iconColor ?? theme.iconTheme.color) : Colors.grey;
    final effectiveTextStyle = (textStyle ?? theme.textTheme.bodyMedium)?.copyWith(
      color: enabled ? (textStyle?.color ?? theme.textTheme.bodyMedium?.color) : Colors.grey,
    );

    final tile = InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
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
      ),
    );

    // Tooltip saat disabled (opsional)
    if (!enabled && (tooltipWhenDisabled?.isNotEmpty ?? false)) {
      return Tooltip(message: tooltipWhenDisabled!, child: Opacity(opacity: 0.55, child: tile));
    }
    return tile;
  }
}