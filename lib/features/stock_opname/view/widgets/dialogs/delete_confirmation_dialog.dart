import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String nomorLabel;

  const DeleteConfirmationDialog({
    Key? key,
    required this.nomorLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2196F3);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Konfirmasi Hapus',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Apakah Anda yakin ingin menghapus label\n'),
            TextSpan(
              text: nomorLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const TextSpan(text: '?'),
          ],
        ),
        style: const TextStyle(fontSize: 14.5),
      ),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 10),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: primaryBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.delete_forever, size: 18),
          label: const Text('Hapus'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
