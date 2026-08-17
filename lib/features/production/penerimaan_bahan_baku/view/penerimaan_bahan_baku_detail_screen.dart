// lib/features/production/penerimaan_bahan_baku/view/penerimaan_bahan_baku_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/info_line.dart';
import '../../../../core/network/api_client.dart';
import '../model/penerimaan_bahan_baku_model.dart';
import '../repository/penerimaan_bahan_baku_repository.dart';

/// Layar detail (read-only) satu transaksi penerimaan — format sama seperti
/// layar input produksi washing (No Penerimaan, Tim, Shift, Jam Mulai/
/// Selesai di atas), tapi tanpa aksi edit karena backend belum menyediakan
/// endpoint update. Untuk print/QC label, gunakan layar Label Bahan Baku
/// (data yang dibuat di sini otomatis muncul di sana).
class PenerimaanBahanBakuDetailScreen extends StatefulWidget {
  final String noPenerimaan;

  const PenerimaanBahanBakuDetailScreen({super.key, required this.noPenerimaan});

  @override
  State<PenerimaanBahanBakuDetailScreen> createState() =>
      _PenerimaanBahanBakuDetailScreenState();
}

class _PenerimaanBahanBakuDetailScreenState
    extends State<PenerimaanBahanBakuDetailScreen> {
  late final PenerimaanBahanBakuRepository _repo;
  late Future<PenerimaanBahanBakuDetail> _future;

  @override
  void initState() {
    super.initState();
    _repo = PenerimaanBahanBakuRepository(api: context.read<ApiClient>());
    _future = _repo.fetchDetail(widget.noPenerimaan);
  }

  String _fmtKg(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Penerimaan ${widget.noPenerimaan}'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<PenerimaanBahanBakuDetail>(
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
                  'Gagal memuat detail\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            );
          }
          final detail = snapshot.data!;
          final header = detail.header;
          final grouped = detail.outputsByPallet;
          final palletNos = grouped.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    InfoLine(
                      label: 'No Penerimaan',
                      value: header.noPenerimaan,
                      icon: Icons.assignment_outlined,
                    ),
                    InfoLine(
                      label: 'No Bahan Baku',
                      value: header.noBahanBaku ?? '-',
                      icon: Icons.qr_code_2_outlined,
                    ),
                    InfoLine(
                      label: 'Tim',
                      value: header.namaTim,
                      icon: Icons.groups_outlined,
                    ),
                    InfoLine(
                      label: 'Tanggal',
                      value: header.tglPenerimaanTextShort,
                      icon: Icons.calendar_today_outlined,
                    ),
                    InfoLine(
                      label: 'Shift',
                      value: 'Shift ${header.shift}',
                      icon: Icons.schedule_outlined,
                    ),
                    InfoLine(
                      label: 'Jam',
                      value: header.hourRangeText.isEmpty ? '-' : header.hourRangeText,
                      icon: Icons.access_time_outlined,
                    ),
                    InfoLine(
                      label: 'Supplier',
                      value: header.namaSupplier,
                      icon: Icons.local_shipping_outlined,
                    ),
                    InfoLine(
                      label: 'No Plat',
                      value: (header.noPlat ?? '').isEmpty ? '-' : header.noPlat!,
                      icon: Icons.directions_car_filled_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (palletNos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Belum ada pallet', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                for (final noPallet in palletNos) ...[
                  _buildPalletCard(noPallet, grouped[noPallet]!),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPalletCard(int noPallet, List<PenerimaanBahanBakuOutput> saks) {
    final totalBerat = saks.fold<double>(0, (sum, s) => sum + s.berat);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PALLET $noPallet',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${saks.length} sak — ${_fmtKg(totalBerat)} kg',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in saks)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sak ${s.noSak} — ${_fmtKg(s.berat)} kg',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
