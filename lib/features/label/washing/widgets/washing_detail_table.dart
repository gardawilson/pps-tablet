import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/info_line.dart';
import '../view_model/washing_view_model.dart';

class WashingDetailTable extends StatelessWidget {
  final ScrollController scrollController;

  const WashingDetailTable({
    super.key,
    required this.scrollController,
  });

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
      child: Consumer<WashingViewModel>(
        builder: (context, vm, _) {
          final totalSak = vm.details.length;
          final usedDetails = vm.details.where((d) => _isUsed(d.dateUsage)).toList();

          final usedSak = usedDetails.length;
          final availSak = totalSak - usedSak;

          final totalBerat = _sumBerat(vm.details);
          final usedBerat = _sumBerat(usedDetails);
          final availBerat = totalBerat - usedBerat;

          return Column(
            children: [
              _buildHeader(
                availableSak: availSak,
                totalSak: totalSak,
                availableBerat: availBerat,
                totalBerat: totalBerat,
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
            'DETAIL',
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
                  value: '$availableSak/$totalSak',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                InfoLine(
                  label: 'Total Berat (kg)',
                  value: '${_kg(availableBerat)}/${_kg(totalBerat)}',
                  icon: Icons.monitor_weight_outlined,
                ),
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
              'Pilih label untuk melihat detail',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'SAK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'BERAT (KG)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody(WashingViewModel vm) {
    return ListView.builder(
      controller: scrollController,
      itemCount: vm.details.length,
      itemBuilder: (context, index) {
        final d = vm.details[index];
        final isEven = index % 2 == 0;
        final used = _isUsed(d.dateUsage);

        final bg = used
            ? Colors.grey.shade100
            : (isEven ? Colors.white : Colors.grey.shade50);

        final textColor = used ? Colors.grey.shade500 : Colors.grey.shade800;
        final sakColor = used ? Colors.grey.shade600 : Colors.black87;

        return Opacity(
          opacity: used ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    d.noSak.toString(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: sakColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    (d.berat ?? 0).toStringAsFixed(2),
                    style: TextStyle(fontSize: 15, color: textColor),
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