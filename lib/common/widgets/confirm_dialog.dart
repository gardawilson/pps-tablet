import 'package:flutter/material.dart';

/// Dialog konfirmasi standar dengan tombol Batal + aksi.
///
/// Kembalikan `true` jika user menekan tombol konfirmasi, `false`/`null` jika batal.
///
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (_) => ConfirmDialog(
///     title: 'Keluarkan Label Input?',
///     message: 'Yakin ingin mengeluarkan 3 label dari proses ini?',
///     confirmLabel: 'Keluarkan',
///     confirmIcon: Icons.logout,
///   ),
/// );
/// if (confirmed != true) return;
/// ```
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final IconData? confirmIcon;

  /// Warna tombol konfirmasi. Default merah (aksi destruktif).
  final Color confirmColor;

  /// Label tombol batal. Default 'Batal'.
  final String cancelLabel;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Ya',
    this.confirmIcon,
    this.confirmColor = const Color(0xFFDC2626),
    this.cancelLabel = 'Batal',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + judul
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: confirmColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      confirmIcon ?? Icons.help_outline_rounded,
                      color: confirmColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Pesan
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 16),
              // Tombol
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: Icon(confirmIcon ?? Icons.check, size: 15),
                    label: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
