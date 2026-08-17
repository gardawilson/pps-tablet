// lib/features/production/penerimaan_bahan_baku/widgets/pbb_sak_list.dart
//
// Varian tablet-friendly dari `BahanBakuPalletDetailTable` — kartu besar,
// state dari `BahanBakuViewModel` yang sama.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../label/bahan_baku/model/bahan_baku_pallet_detail.dart';
import '../../../label/bahan_baku/view_model/bahan_baku_view_model.dart';

class PbbSakList extends StatelessWidget {
  final ScrollController scrollController;

  const PbbSakList({super.key, required this.scrollController});

  bool _isUsed(String? dateUsage) {
    final s = (dateUsage ?? '').trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return false;
    return true;
  }

  double _sumBerat(Iterable<BahanBakuPalletDetail> items) {
    double total = 0;
    for (final d in items) {
      total += d.berat;
    }
    return total;
  }

  String _kg(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Consumer<BahanBakuViewModel>(
      builder: (context, vm, _) {
        final totalSak = vm.details.length;
        final availableDetails = vm.details.where((d) => !_isUsed(d.dateUsage)).toList();
        final availableSak = availableDetails.length;
        final totalBerat = _sumBerat(vm.details);
        final availableBerat = _sumBerat(availableDetails);
        final partialCount = vm.details.where((d) => d.isPartial == 1).length;
        final lembabCount = vm.details.where((d) => d.isLembab == 1).length;

        return Column(
          children: [
            _buildSummaryHeader(
              availableSak: availableSak,
              totalSak: totalSak,
              availableBerat: availableBerat,
              totalBerat: totalBerat,
              partialCount: partialCount,
              lembabCount: lembabCount,
            ),
            if (vm.isDetailLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (vm.details.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Pilih pallet untuk melihat detail sak',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: vm.details.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _SakCard(item: vm.details[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader({
    required int availableSak,
    required int totalSak,
    required double availableBerat,
    required double totalBerat,
    required int partialCount,
    required int lembabCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAIL SAK',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _stat(Icons.inventory_2_outlined, 'Sak', '$availableSak / $totalSak'),
              _stat(Icons.monitor_weight_outlined, 'Berat (kg)', '${_kg(availableBerat)} / ${_kg(totalBerat)}'),
              if (partialCount > 0) _stat(Icons.call_split, 'Partial', '$partialCount', color: Colors.red.shade700),
              if (lembabCount > 0) _stat(Icons.water_drop, 'Lembab', '$lembabCount', color: Colors.blue.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value, {Color? color}) {
    final c = color ?? Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 6),
        Text('$label ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? const Color(0xFF172B4D))),
      ],
    );
  }
}

class _SakCard extends StatelessWidget {
  final BahanBakuPalletDetail item;

  const _SakCard({required this.item});

  bool get _used {
    final s = (item.dateUsage ?? '').trim();
    return s.isNotEmpty && s.toLowerCase() != 'null';
  }

  @override
  Widget build(BuildContext context) {
    final partial = item.isPartial == 1;
    final lembab = item.isLembab == 1;
    final used = _used;

    return Opacity(
      opacity: used ? 0.55 : 1,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.noSak,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF172B4D)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${item.berat.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: partial || lembab ? FontWeight.w800 : FontWeight.w600,
                  color: partial ? Colors.red : (lembab ? Colors.blue.shade700 : const Color(0xFF172B4D)),
                ),
              ),
            ),
            if (partial) _conditionBadge('Partial', Colors.red),
            if (partial && lembab) const SizedBox(width: 6),
            if (lembab) _conditionBadge('Lembab', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _conditionBadge(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color.shade800),
      ),
    );
  }
}
