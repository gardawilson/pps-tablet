// lib/features/production/bahan_baku/widgets/bahan_baku_pallet_detail_table.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/info_line.dart';
import '../view_model/bahan_baku_view_model.dart';

class BahanBakuPalletDetailTable extends StatefulWidget {
  final ScrollController scrollController;

  const BahanBakuPalletDetailTable({
    super.key,
    required this.scrollController,
  });

  @override
  State<BahanBakuPalletDetailTable> createState() =>
      _BahanBakuPalletDetailTableState();
}

class _BahanBakuPalletDetailTableState
    extends State<BahanBakuPalletDetailTable> {
  bool _isUsed(String? dateUsage) {
    final s = (dateUsage ?? '').trim();
    if (s.isEmpty) return false;
    if (s.toLowerCase() == 'null') return false;
    return true;
  }

  double _sumBerat(Iterable items) {
    double total = 0;
    for (final d in items) {
      total += (d.berat as double?) ?? 0.0;
    }
    return total;
  }

  String _kg(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Consumer<BahanBakuViewModel>(
        builder: (context, vm, _) {
          final totalSak = vm.details.length;

          // ✅ available = DateUsage null
          final availableDetails =
          vm.details.where((d) => !_isUsed(d.dateUsage)).toList();

          final availableSak = availableDetails.length;

          final totalBerat = _sumBerat(vm.details);
          final availableBerat = _sumBerat(availableDetails);

          // Count partial & lembab items
          final partialCount = vm.details.where((d) => d.isPartial == 1).length;
          final lembabCount = vm.details.where((d) => d.isLembab == 1).length;

          return Column(
            children: [
              _buildHeader(
                availableSak: availableSak,
                totalSak: totalSak,
                availableBerat: availableBerat,
                totalBerat: totalBerat,
                partialCount: partialCount,
                lembabCount: lembabCount,
              ),
              if (vm.isDetailLoading) _buildLoadingState(),
              if (!vm.isDetailLoading && vm.details.isEmpty) _buildEmptyState(),
              if (!vm.isDetailLoading && vm.details.isNotEmpty)
                Expanded(
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      Expanded(child: _buildTableBody(vm)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required int availableSak,
    required int totalSak,
    required double availableBerat,
    required double totalBerat,
    required int partialCount,
    required int lembabCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAIL SAK',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                InfoLine(
                  label: 'Jumlah Sak',
                  value: '$availableSak / $totalSak',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                InfoLine(
                  label: 'Total Berat (kg)',
                  value: '${_kg(availableBerat)} / ${_kg(totalBerat)}',
                  icon: Icons.monitor_weight_outlined,
                ),
                if (partialCount > 0 || lembabCount > 0) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (partialCount > 0)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.call_split,
                                  size: 16, color: Colors.red.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Partial: $partialCount',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (lembabCount > 0)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.water_drop,
                                  size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Lembab: $lembabCount',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Expanded(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Pilih pallet untuk melihat detail sak',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 50, // ⬅️ dari 50 → 80 untuk NoSak yang lebih panjang
            child: Text(
              'SAK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'BERAT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 70, // ⬅️ kolom untuk badges
            child: Text(
              'KONDISI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody(BahanBakuViewModel vm) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: vm.details.length,
      itemBuilder: (context, index) {
        final d = vm.details[index];
        final isEven = index % 2 == 0;

        final partial = d.isPartial == 1;
        final lembab = d.isLembab == 1;
        final used = _isUsed(d.dateUsage);

        final bg = used
            ? Colors.grey.shade100
            : (isEven ? Colors.white : Colors.grey.shade50);

        final sakColor = used ? Colors.grey.shade600 : Colors.black87;

        final beratColor = partial
            ? Colors.red
            : (lembab ? Colors.blue.shade700 : Colors.grey.shade800);
        final beratTextColor = used ? Colors.grey.shade500 : beratColor;

        return Opacity(
          opacity: used ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    d.noSak,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sakColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    _kg(d.berat),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: partial || lembab ? FontWeight.w800 : FontWeight.w600,
                      color: beratTextColor,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (partial)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Center(
                            child: Text(
                              'P',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                        ),
                      if (partial && lembab) const SizedBox(width: 4),
                      if (lembab)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Center(
                            child: Text(
                              'L',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ),
                      if (!partial && !lembab)
                        Text(
                          '-',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}