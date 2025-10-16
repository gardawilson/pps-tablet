  // lib/view/widgets/broker_detail_table.dart

  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../view_model/washing_view_model.dart';

  class WashingDetailTable extends StatelessWidget {
    final ScrollController scrollController;

    const WashingDetailTable({
      super.key,
      required this.scrollController,
    });

    @override
    Widget build(BuildContext context) {
      return Container(
        color: Colors.white,
        child: Consumer<WashingViewModel>(
          builder: (context, vm, _) {
            return Column(
              children: [
                _buildHeader(),
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

    Widget _buildHeader() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DETAIL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
        ),
        child: Row(
          children: const [
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

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isEven ? Colors.white : Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    d.noSak.toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    d.berat?.toStringAsFixed(2) ?? '-',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }