import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/info_line.dart';
import '../model/bahan_baku_pallet_detail.dart';
import '../view_model/bahan_baku_view_model.dart';

class BahanBakuPalletDetailTable extends StatelessWidget {
  static const _colSakWidth = 50.0;
  static const _colKondisiWidth = 60.0;

  final ScrollController scrollController;

  const BahanBakuPalletDetailTable({super.key, required this.scrollController});

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
          final availableDetails = vm.details
              .where((d) => !_isUsed(d.dateUsage))
              .toList();

          final availableSak = availableDetails.length;
          final totalBerat = _sumBerat(vm.details);
          final availableBerat = _sumBerat(availableDetails);

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
                  child: AtlasDataTable<BahanBakuPalletDetail>(
                    columns: _buildColumns(),
                    items: vm.details,
                    scrollController: scrollController,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<AtlasTableColumn<BahanBakuPalletDetail>> _buildColumns() {
    return [
      AtlasTableColumn<BahanBakuPalletDetail>(
        title: 'SAK',
        width: _colSakWidth,
        cellBuilder: (context, item, rowState) {
          final used = _isUsed(item.dateUsage);
          return Text(
            item.noSak,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: used ? Colors.grey.shade500 : Colors.black87,
            ),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BahanBakuPalletDetail>(
        title: 'BERAT',
        cellBuilder: (context, item, rowState) {
          final partial = item.isPartial == 1;
          final lembab = item.isLembab == 1;
          final used = _isUsed(item.dateUsage);

          final baseColor = partial
              ? Colors.red
              : (lembab ? Colors.blue.shade700 : rowState.textColor);

          return Text(
            _kg(item.berat),
            style: TextStyle(
              fontSize: 13,
              fontWeight: partial || lembab ? FontWeight.w800 : FontWeight.w600,
              color: used ? Colors.grey.shade500 : baseColor,
            ),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BahanBakuPalletDetail>(
        title: 'KONDISI',
        width: _colKondisiWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          final partial = item.isPartial == 1;
          final lembab = item.isLembab == 1;
          final used = _isUsed(item.dateUsage);

          return Opacity(
            opacity: used ? 0.55 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (partial) _conditionBadge('P', Colors.red),
                if (partial && lembab) const SizedBox(width: 4),
                if (lembab) _conditionBadge('L', Colors.blue),
                if (!partial && !lembab)
                  Text(
                    '-',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
              ],
            ),
          );
        },
      ),
    ];
  }

  Widget _conditionBadge(String label, MaterialColor color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: color.shade300),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color.shade800,
          ),
        ),
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
                              Icon(
                                Icons.call_split,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
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
                              Icon(
                                Icons.water_drop,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
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
    return const Expanded(child: Center(child: CircularProgressIndicator()));
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
}
