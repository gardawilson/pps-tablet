import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/mapping/view_model/mapping_label_history_view_model.dart';

const Color _primary = Color(0xFF0D47A1);

class LabelHistoryDialog extends StatelessWidget {
  final String labelCode;

  const LabelHistoryDialog({super.key, required this.labelCode});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MappingLabelHistoryViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 480,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(vm)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
      decoration: const BoxDecoration(color: _primary),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Perpindahan Lokasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  labelCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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

  Widget _buildContent(MappingLabelHistoryViewModel vm) {
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
    if (vm.result == null || vm.result!.history.isEmpty) {
      return const Center(child: Text('Belum ada riwayat perpindahan lokasi'));
    }

    final history = vm.result!.history;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      itemCount: history.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return _buildNode(
            lokasi: _lokasiLabel(
              history.first.beforeBlok,
              history.first.beforeIdLokasi,
            ),
            caption: 'Lokasi Awal',
            isFirst: true,
            isLast: false,
          );
        }

        final item = history[i - 1];
        return _buildNode(
          lokasi: _lokasiLabel(item.afterBlok, item.afterIdLokasi),
          caption: _formatDate(item.eventTime),
          actor: item.actorUsername,
          isFirst: false,
          isLast: i == history.length,
        );
      },
    );
  }

  String _lokasiLabel(String blok, int? idLokasi) => '$blok${idLokasi ?? ''}';

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNode({
    required String lokasi,
    required String caption,
    String? actor,
    required bool isFirst,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 6,
                  color: isFirst ? Colors.transparent : Colors.grey.shade300,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? Colors.white : _primary,
                    border: Border.all(color: _primary, width: isFirst ? 2 : 0),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        caption,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      if (actor != null && actor.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          actor,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lokasi,
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
