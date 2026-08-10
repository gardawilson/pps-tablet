import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/features/mapping/model/mapping_label_model.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_label_view_model.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_label_history_view_model.dart';
import 'package:pps_tablet/features/mapping/view/widgets/label_chart.dart';
import 'package:pps_tablet/features/mapping/view/widgets/label_history_dialog.dart';

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
                if (widget.lokasi.jenisList.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.lokasi.jenisList.length} jenis',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showJenisListDialog(context),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showHistoryDialog(item.labelCode),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 84,
                  child: Center(
                    child: Text(
                      item.dateCreate,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.namaJenis,
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.labelCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Align(
                  alignment: Alignment.topRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          valueText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: _primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJenisListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                decoration: const BoxDecoration(color: _primary),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Jenis di Lokasi Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.lokasi.jenisList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final jenis = widget.lokasi.jenisList[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        jenis.namaJenis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDialog(String labelCode) {
    final vm = MappingLabelHistoryViewModel(
      repository: MappingRepository(api: ApiClient()),
    )..load(labelCode);

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: LabelHistoryDialog(labelCode: labelCode),
      ),
    ).whenComplete(() => vm.dispose());
  }
}
