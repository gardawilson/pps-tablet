import 'package:flutter/material.dart';
import '../models/update_model.dart';
import '../widgets/update_progress.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  int _progress = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pembaruan Tersedia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Versi baru: ${widget.updateInfo.version}'),
          const SizedBox(height: 8),
          const Text('Perubahan:'),
          Text(widget.updateInfo.changelog),
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            UpdateProgress(progress: _progress),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            child: const Text('Nanti'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        TextButton(
          child: Text(_isDownloading ? 'Mengunduh...' : 'Perbarui'),
          onPressed: _isDownloading ? null : () => _startDownload(),
        ),
      ],
    );
  }

  void _startDownload() {
    setState(() => _isDownloading = true);
    // Implementasi download akan dipanggil dari sini
  }
}