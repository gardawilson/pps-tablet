// lib/view/widgets/broker_detail_table.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/info_line.dart';
import '../view_model/broker_view_model.dart';

import './interactive_popover.dart';
import 'broker_partial_info_popover.dart';

class BrokerDetailTable extends StatefulWidget {
  final ScrollController scrollController;

  const BrokerDetailTable({
    super.key,
    required this.scrollController,
  });

  @override
  State<BrokerDetailTable> createState() => _BrokerDetailTableState();
}

class _BrokerDetailTableState extends State<BrokerDetailTable> {
  final InteractivePopover _popover = InteractivePopover();

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_hidePopoverOnScroll);
  }

  void _hidePopoverOnScroll() {
    if (_popover.isShown &&
        widget.scrollController.position.isScrollingNotifier.value) {
      _popover.hide();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_hidePopoverOnScroll);
    _popover.dispose();
    super.dispose();
  }

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
      child: Consumer<BrokerViewModel>(
        builder: (context, vm, _) {
          final totalSak = vm.details.length;

          // ✅ available = DateUsage null
          final availableDetails =
          vm.details.where((d) => !_isUsed(d.dateUsage)).toList();

          final availableSak = availableDetails.length;

          final totalBerat = _sumBerat(vm.details);
          final availableBerat = _sumBerat(availableDetails);

          return Column(
            children: [
              _buildHeader(
                availableSak: availableSak,
                totalSak: totalSak,
                availableBerat: availableBerat,
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

  Widget _buildTableBody(BrokerViewModel vm) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: vm.details.length,
      itemBuilder: (context, index) {
        final d = vm.details[index];
        final isEven = index % 2 == 0;

        final partial = d.isPartial == true;
        final used = _isUsed(d.dateUsage);

        // ✅ Disable hanya berdasarkan DateUsage
        final bg = used
            ? Colors.grey.shade100
            : (isEven ? Colors.white : Colors.grey.shade50);

        final sakColor = used ? Colors.grey.shade600 : Colors.black87;

        // ✅ partial = merah, tapi kalau used tetap pudar via opacity
        final beratColor = partial ? Colors.red : Colors.grey.shade800;
        final beratTextColor = used ? Colors.grey.shade500 : beratColor;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            // popover hanya untuk partial (meskipun used, kamu boleh pilih disable tap)
            if (partial && !used) {
              showBrokerPartialInfoPopover(
                context: context,
                vm: vm,
                noSak: d.noSak,
                popover: _popover,
                globalPosition: details.globalPosition,
              );
            }
          },
          child: Opacity(
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
                      d.berat?.toStringAsFixed(2) ?? '-',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: partial ? FontWeight.w800 : FontWeight.w600,
                        color: beratTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
