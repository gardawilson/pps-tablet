import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../model/washing_header_model.dart';

class WashingRowPopover extends StatelessWidget {
  final WashingHeader header;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const WashingRowPopover({
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
    await Clipboard.setData(ClipboardData(text: header.noWashing));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('NoWashing "${header.noWashing}" disalin'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);

    // ⬇️ ambil izin sekali
    final perm = context.watch<PermissionViewModel>();
    final canEdit   = perm.can('label_washing:update');
    final canDelete = perm.can('label_washing:delete');
    // (opsional) print selalu boleh → tidak dibatasi permission
    // final canPrint  = perm.can('label_washing:print');

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header info + copy
            ListTile(
              dense: true,
              title: Text(
                header.noWashing,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                header.namaJenisPlastik,
                overflow: TextOverflow.ellipsis,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              trailing: IconButton(
                tooltip: 'Salin NoWashing',
                icon: const Icon(Icons.copy_outlined),
                onPressed: () => _copyOnly(context),
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
              iconColor: canDelete ? theme.colorScheme.error : null,
              textStyle: TextStyle(
                color: canDelete ? theme.colorScheme.error : Colors.grey,
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
