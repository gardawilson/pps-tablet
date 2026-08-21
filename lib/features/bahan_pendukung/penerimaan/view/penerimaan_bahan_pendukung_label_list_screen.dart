// lib/features/bahan_pendukung/penerimaan/view/penerimaan_bahan_pendukung_label_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../production/shared/widgets/production_inline_stat.dart';
import '../model/penerimaan_bahan_pendukung_model.dart';
import '../repository/penerimaan_bahan_pendukung_repository.dart';

const _kAccent = Color(0xFF00897B);

/// Layar list barang ("label") bahan pendukung untuk satu NoPenerimaan —
/// dibuka saat tap tim yang sudah aktif / baris riwayat, MENGGANTIKAN
/// layar `PenerimaanBahanPendukungInputScreen` (generate barang) di alur
/// itu. Format kartu grid sama seperti section Label Output pada
/// `WashingProductionInputScreen` (lihat `WashingOutputTile`) — beda
/// dengan Penerimaan Bahan Baku, di sini HANYA SATU section (tidak ada
/// split Pakai/Proses/divider) karena bahan pendukung tidak punya
/// kategori. Tidak ada AppBar sendiri — chrome/breadcrumb global sudah
/// disediakan AppShell.
class PenerimaanBahanPendukungLabelListScreen extends StatefulWidget {
  final String noPenerimaan;

  const PenerimaanBahanPendukungLabelListScreen({
    super.key,
    required this.noPenerimaan,
  });

  @override
  State<PenerimaanBahanPendukungLabelListScreen> createState() =>
      _PenerimaanBahanPendukungLabelListScreenState();
}

class _PenerimaanBahanPendukungLabelListScreenState
    extends State<PenerimaanBahanPendukungLabelListScreen> {
  late final PenerimaanBahanPendukungRepository _repo;
  late Future<PenerimaanBahanPendukungDetail> _future;

  @override
  void initState() {
    super.initState();
    _repo = PenerimaanBahanPendukungRepository(api: context.read<ApiClient>());
    _future = _repo.fetchDetail(widget.noPenerimaan);
  }

  String _fmtQty(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<PenerimaanBahanPendukungDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat barang\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            );
          }

          final items = snapshot.data!.items;
          if (items.isEmpty) {
            return Center(
              child: Text('Belum ada barang', style: TextStyle(color: Colors.grey.shade500)),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (_, c) => GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 380 ? 2 : (c.maxWidth < 640 ? 3 : 4),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 84,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _buildItemTile(items[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemTile(PenerimaanBahanPendukungItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _ItemDetailDialog(item: item),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                item.namaBarang,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1D23)),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                item.namaSupplier.isEmpty ? '-' : item.namaSupplier,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  ProductionMiniMetric(
                    icon: Icons.numbers_outlined,
                    text: '${_fmtQty(item.qty)} ${item.satuan}',
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

class _ItemDetailDialog extends StatelessWidget {
  final PenerimaanBahanPendukungItem item;

  const _ItemDetailDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: _kAccent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.namaBarang,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _row('Supplier', item.namaSupplier.isEmpty ? '-' : item.namaSupplier),
              _row('Qty', '${item.qty.toStringAsFixed(2)} ${item.satuan}'),
              if ((item.keterangan ?? '').trim().isNotEmpty)
                _row('Keterangan', item.keterangan!.trim()),
              _row('No Urut', '${item.noPenerimaan}-${item.noUrut}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
