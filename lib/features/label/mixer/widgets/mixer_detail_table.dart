// lib/view/widgets/mixer_detail_table.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/mixer_view_model.dart';

// ⬇️ interactive popover + our new partial-info popover
import './interactive_popover.dart';                 // adjust path if needed
import 'mixer_partial_info_popover.dart';           // <-- use this (not the sheet)

class MixerDetailTable extends StatefulWidget {
  final ScrollController scrollController;

  const MixerDetailTable({
    super.key,
    required this.scrollController,
  });

  @override
  State<MixerDetailTable> createState() => _MixerDetailTableState();
}

class _MixerDetailTableState extends State<MixerDetailTable> {
  final InteractivePopover _popover = InteractivePopover();

  @override
  void initState() {
    super.initState();
    // Optional: hide popover when user scrolls the list
    widget.scrollController.addListener(_hidePopoverOnScroll);
  }

  void _hidePopoverOnScroll() {
    if (_popover.isShown && widget.scrollController.position.isScrollingNotifier.value) {
      _popover.hide();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_hidePopoverOnScroll);
    _popover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Consumer<MixerViewModel>(
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
            Icon(Icons.inventory_2, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Pilih label untuk melihat detail',
              style: TextStyle(fontSize: 16, color: Colors.grey),
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

  Widget _buildTableBody(MixerViewModel vm) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: vm.details.length,
      itemBuilder: (context, index) {
        final d = vm.details[index];
        final isEven = index % 2 == 0;
        final isPartial = d.isPartial == true;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // klik baris → kalau partial, tampilkan popover
          onTapDown: (details) {
            if (isPartial) {
              showMixerPartialInfoPopover(
                context: context,
                vm: vm,
                noSak: d.noSak,
                popover: _popover,
                globalPosition: details.globalPosition,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isEven ? Colors.white : Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Kolom SAK
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

                // Kolom BERAT – merah kalau partial, tanpa icon
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      d.berat?.toStringAsFixed(2) ?? '-',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isPartial ? FontWeight.bold : FontWeight.w500,
                        color: isPartial
                            ? Colors.red              // 🔴 partial
                            : Colors.grey.shade800,   // normal
                      ),
                    ),
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
