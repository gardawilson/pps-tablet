import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/mapping/model/mapping_label_model.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_label_view_model.dart';
import 'package:pps_tablet/features/mapping/view/widgets/label_chart.dart';

const Color _primary = Color(0xFF0D47A1);

class LabelDialog extends StatefulWidget {
  final MappingLokasi lokasi;

  const LabelDialog({super.key, required this.lokasi});

  @override
  State<LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<LabelDialog> {
  bool _showChart = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MappingLabelViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 520,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            _buildHeader(vm),
            Expanded(child: _buildContent(vm)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MappingLabelViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
      decoration: const BoxDecoration(color: _primary),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lokasi.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (widget.lokasi.namaJenis.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.lokasi.namaJenis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (vm.result != null) ...[
            _statChip('${vm.result!.totalData} label'),
            const SizedBox(width: 4),
          ],
          if (vm.result != null && vm.result!.data.isNotEmpty)
            Tooltip(
              message: _showChart ? 'Daftar Label' : 'Statistik',
              child: IconButton(
                onPressed: () => setState(() => _showChart = !_showChart),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _showChart
                        ? Icons.list_alt_rounded
                        : Icons.bar_chart_rounded,
                    key: ValueKey(_showChart),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _buildContent(MappingLabelViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vm.error, textAlign: TextAlign.center),
        ),
      );
    }
    if (vm.result == null || vm.result!.data.isEmpty) {
      return const Center(child: Text('Tidak ada label di lokasi ini'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _showChart
          ? LabelChart(key: const ValueKey('chart'), result: vm.result!)
          : _buildList(vm.result!.data),
    );
  }

  Widget _buildList(List<MappingLabelItem> data) {
    return ListView.separated(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildLabelItem(data[i]),
    );
  }

  Widget _buildLabelItem(MappingLabelItem item) {
    final isKg = item.uom.toUpperCase() == 'KG';
    final String valueText;
    if (isKg) {
      final b = item.berat ?? 0;
      valueText =
          '${b == b.truncateToDouble() ? b.toInt() : b.toStringAsFixed(1)} kg';
    } else {
      valueText = '${item.qty} ${item.uom}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tanggal
          SizedBox(
            width: 78,
            child: Text(
              item.dateCreate,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nomor label + jenis
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.labelCode,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.namaJenis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Nilai berdasarkan UOM
          Text(
            valueText,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
