// lib/features/verifikasi/view/verifikasi_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/error_status_dialog.dart';
import '../../../core/view_model/permission_view_model.dart';
import '../model/verifikasi_models.dart';
import '../view_model/verifikasi_view_model.dart';

const _kVerifikasiPrimary = Color(0xFF6D28D9);

class VerifikasiDetailScreen extends StatefulWidget {
  final VerifikasiItem item;

  const VerifikasiDetailScreen({super.key, required this.item});

  @override
  State<VerifikasiDetailScreen> createState() => _VerifikasiDetailScreenState();
}

class _VerifikasiDetailScreenState extends State<VerifikasiDetailScreen> {
  late Future<ProductionCrossCheckSummary> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final vm = context.read<VerifikasiViewModel>();
    _future = vm.fetchCrossCheck(widget.item);
  }

  Future<void> _handleVerify() async {
    final noteCtl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verifikasi Produksi?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfirmasi bahwa input & output untuk ${widget.item.noProduksi} sudah dicek dan sesuai.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _kVerifikasiPrimary),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final vm = context.read<VerifikasiViewModel>();
    final ok = await vm.verify(widget.item, note: noteCtl.text.trim());
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Produksi berhasil diverifikasi'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorStatusDialog(
          title: 'Gagal Verifikasi',
          message: vm.actionError ?? 'Kesalahan tidak diketahui',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tgl = item.tglProduksi != null
        ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(item.tglProduksi!.toLocal())
        : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(item.noProduksi),
        backgroundColor: _kVerifikasiPrimary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ProductionCrossCheckSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat data:\n${snapshot.error}'),
              ),
            );
          }

          final summary = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderCard(item, tgl),
              const SizedBox(height: 16),
              _buildInputCard(summary),
              const SizedBox(height: 16),
              _buildOutputCard(summary),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final canVerify =
                      context.watch<PermissionViewModel>().can('verifikasi:verify');
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canVerify ? _handleVerify : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kVerifikasiPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Verifikasi Produksi Ini'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(VerifikasiItem item, String tgl) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.jenisLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _kVerifikasiPrimary,
              ),
            ),
            const SizedBox(height: 6),
            _infoRow(Icons.precision_manufacturing_outlined, item.namaMesin ?? '-'),
            _infoRow(Icons.calendar_today_outlined, tgl),
            _infoRow(Icons.access_time, 'Shift ${item.shift ?? '-'}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInputCard(ProductionCrossCheckSummary summary) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Label Input', style: TextStyle(fontWeight: FontWeight.w700)),
            const Divider(height: 16),
            if (summary.inputCounts.isEmpty)
              const Text('Tidak ada data input', style: TextStyle(color: Colors.grey))
            else
              ...summary.inputCounts.entries.map(
                (e) => _kvRow(e.key, '${e.value} label'),
              ),
            const Divider(height: 20),
            _kvRow(
              'Total Berat Input',
              '${summary.totalInputBerat.toStringAsFixed(2)} kg',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputCard(ProductionCrossCheckSummary summary) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Label Output', style: TextStyle(fontWeight: FontWeight.w700)),
            const Divider(height: 16),
            if (summary.outputs.isEmpty)
              const Text('Tidak ada data output', style: TextStyle(color: Colors.grey))
            else
              ...summary.outputs.map(
                (o) => _kvRow(
                  '${o.namaJenis} (${o.totalSak} label)',
                  '${o.totalBerat.toStringAsFixed(2)} kg',
                ),
              ),
            const Divider(height: 20),
            _kvRow(
              'Total Berat Output',
              '${summary.totalOutputBerat.toStringAsFixed(2)} kg',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
