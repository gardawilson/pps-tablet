library;

import 'package:flutter/material.dart';

import 'common/widgets/error_status_dialog.dart';
import 'common/widgets/scan_label_dialog.dart';
import 'common/widgets/success_status_dialog.dart';

void main() {
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Widget Preview',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E6FD9),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const _PreviewHome(),
    );
  }
}

class _PreviewHome extends StatelessWidget {
  const _PreviewHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6FD9),
        foregroundColor: Colors.white,
        title: const Text(
          'Widget Preview',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: 'Status Dialogs',
            children: [
              _PreviewTile(
                label: 'Success — default (1 tombol)',
                color: Colors.green,
                icon: Icons.check_circle_outline,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const SuccessStatusDialog(
                    title: 'Berhasil Disimpan',
                    message:
                        'Transaksi telah berhasil diproses dan disimpan ke sistem.',
                  ),
                ),
              ),
              _PreviewTile(
                label: 'Success — dengan extra content',
                color: Colors.green,
                icon: Icons.check_circle_outline,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => SuccessStatusDialog(
                    title: 'Transaksi Berhasil',
                    message: 'Data bongkar susun telah tersimpan.',
                    extraContent: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No. Transaksi: BS-20240428-001',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _PreviewTile(
                label: 'Success — 2 tombol (Buat Baru / Selesai)',
                color: Colors.green,
                icon: Icons.check_circle_outline,
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => SuccessStatusDialog(
                    title: 'Berhasil Disimpan',
                    message: 'Transaksi telah berhasil diproses.',
                    actions: [
                      StatusAction(
                        label: 'Buat Baru',
                        onPressed: () => Navigator.of(ctx).pop(),
                        isPrimary: false,
                      ),
                      StatusAction(
                        label: 'Selesai',
                        onPressed: () => Navigator.of(ctx).pop(),
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
              ),
              _PreviewTile(
                label: 'Error — gagal submit',
                color: Colors.redAccent,
                icon: Icons.error_outline,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const ErrorStatusDialog(
                    title: 'Gagal Submit',
                    message:
                        'Terjadi kesalahan pada server. Silakan coba lagi.',
                  ),
                ),
              ),
              _PreviewTile(
                label: 'Error — pesan panjang',
                color: Colors.redAccent,
                icon: Icons.error_outline,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const ErrorStatusDialog(
                    title: 'Gagal Menyimpan Data',
                    message:
                        'Koneksi ke server terputus saat menyimpan transaksi. '
                        'Pastikan perangkat terhubung ke jaringan dan coba ulangi. '
                        'Jika masalah berlanjut, hubungi administrator.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Scan Label Dialog',
            children: [
              _PreviewTile(
                label: 'Scan — tanpa accepted labels',
                color: const Color(0xFF1E6FD9),
                icon: Icons.qr_code_scanner,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => ScanLabelDialog(
                    onLookup: (code) async {
                      await Future.delayed(const Duration(milliseconds: 800));
                      return null; // selalu sukses di preview
                    },
                    manualHint: 'B.0000000001',
                  ),
                ),
              ),
              _PreviewTile(
                label: 'Scan — Sortir Reject (2 label)',
                color: const Color(0xFF1E6FD9),
                icon: Icons.qr_code_scanner,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => ScanLabelDialog(
                    onLookup: (code) async {
                      await Future.delayed(const Duration(milliseconds: 800));
                      return null;
                    },
                    manualHint: 'BA / BB.0000000001',
                    acceptedLabels: const [
                      (prefix: 'BB', label: 'Furniture WIP'),
                      (prefix: 'BA', label: 'Barang Jadi'),
                    ],
                  ),
                ),
              ),
              _PreviewTile(
                label: 'Scan — Bongkar Susun (8 label)',
                color: const Color(0xFF1E6FD9),
                icon: Icons.qr_code_scanner,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => ScanLabelDialog(
                    onLookup: (code) async {
                      await Future.delayed(const Duration(milliseconds: 800));
                      // simulasi error untuk kode "ERR"
                      if (code.toUpperCase() == 'ERR')
                        return 'Label tidak ditemukan';
                      return null;
                    },
                    manualHint: 'B.0000000001',
                    headerSubtitle: 'Bongkar',
                    acceptedLabels: const [
                      (prefix: 'A', label: 'Bahan Baku'),
                      (prefix: 'B', label: 'Washing'),
                      (prefix: 'D', label: 'Broker'),
                      (prefix: 'M', label: 'Bonggolan'),
                      (prefix: 'V', label: 'Gilingan'),
                      (prefix: 'F', label: 'Crusher'),
                      (prefix: 'BB', label: 'Furniture WIP'),
                      (prefix: 'BA', label: 'Barang Jadi'),
                    ],
                  ),
                ),
              ),
              _PreviewTile(
                label: 'Scan — simulasi error lookup (ketik "ERR")',
                color: Colors.orange,
                icon: Icons.qr_code_scanner,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => ScanLabelDialog(
                    onLookup: (code) async {
                      await Future.delayed(const Duration(milliseconds: 600));
                      return 'Label "$code" tidak ditemukan di sistem';
                    },
                    manualHint: 'Ketik apapun → selalu error',
                    acceptedLabels: const [
                      (prefix: 'BB', label: 'Furniture WIP'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6FD9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        ...children.map(
          (child) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
        ),
      ],
    );
  }
}

// ── Preview tile ──────────────────────────────────────────────────────────────

class _PreviewTile extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PreviewTile({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//flutter run -t lib/preview.dart
