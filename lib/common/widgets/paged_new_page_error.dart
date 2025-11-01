import 'package:flutter/material.dart';

/// Next-page error (appears at list bottom)
class PagedNewPageError extends StatelessWidget {
  final VoidCallback onRetry;

  const PagedNewPageError({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Text('Gagal memuat halaman berikutnya'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
