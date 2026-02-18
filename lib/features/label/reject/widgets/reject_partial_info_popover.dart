import 'package:flutter/material.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/interactive_popover.dart';
import '../view_model/reject_view_model.dart';

Future<void> showRejectPartialInfoPopover({
  required BuildContext context,
  required RejectViewModel vm,
  required String noReject,
  required InteractivePopover popover,
  required Offset globalPosition,
}) async {
  if (!context.mounted) return;

  final screenHeight = MediaQuery.of(context).size.height;
  final adaptiveMaxHeight = (screenHeight - 32).clamp(360.0, 700.0).toDouble();

  await popover.show(
    context: context,
    globalPosition: globalPosition,
    maxWidth: 300,
    maxHeight: adaptiveMaxHeight,
    backdropOpacity: 0.04,
    preferAbove: true,
    verticalGap: 10,
    startScale: 0.96,
    startOpacity: 0.0,
    child: ChangeNotifierProvider.value(
      value: vm,
      child: _RejectPartialInfoCard(
        noReject: noReject,
        onClose: () => popover.hide(),
      ),
    ),
  );

  await vm.loadPartialInfo(noReject: noReject);
}

class _RejectPartialInfoCard extends StatefulWidget {
  final String noReject;
  final VoidCallback onClose;

  const _RejectPartialInfoCard({
    required this.noReject,
    required this.onClose,
  });

  @override
  State<_RejectPartialInfoCard> createState() => _RejectPartialInfoCardState();
}

class _RejectPartialInfoCardState extends State<_RejectPartialInfoCard> {
  late RejectViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = context.read<RejectViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    const atlasBlue = Color(0xFF0C66E4);
    const atlasBlueSubtle = Color(0xFFE9F2FF);
    const atlasSurface = Color(0xFFF7F8F9);
    const atlasBorder = Color(0xFFDCDFE4);
    const atlasText = Color(0xFF172B4D);
    const atlasSubtleText = Color(0xFF44546F);

    final divider = const Divider(
      height: 0,
      thickness: 0.8,
      color: atlasBorder,
    );

    return Consumer<RejectViewModel>(
      builder: (ctx, vm, __) {
        final isLoading = vm.isPartialLoading;
        final hasError = vm.partialError != null;
        final info = vm.partialInfo;
        final isEmpty = info == null || info.rows.isEmpty;

        if (hasError && !isLoading) {
          return _ErrorState(error: vm.partialError!);
        }

        if (isEmpty && !isLoading) {
          return const _EmptyState();
        }

        final displayRows = isLoading ? <dynamic>[] : (info?.rows ?? []);
        final totalBerat = isLoading ? 0.0 : (info?.totalPartialBerat ?? 0.0);
        final rowCount = displayRows.length;

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: const BoxDecoration(
                    color: atlasBlueSubtle,
                    border: Border(bottom: BorderSide(color: atlasBorder)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: atlasBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: atlasBlue.withValues(alpha: 0.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: atlasBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Partial Reject',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: atlasText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.noReject,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: atlasSubtleText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.scale,
                                  size: 14,
                                  color: atlasSubtleText,
                                ),
                                const SizedBox(width: 6),
                                if (isLoading)
                                  const Text(
                                    'Memuat...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: atlasSubtleText,
                                    ),
                                  )
                                else
                                  Text(
                                    'Total: ${totalBerat.toStringAsFixed(2)} kg',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: atlasSubtleText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                divider,
                Container(
                  width: double.infinity,
                  color: atlasSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.list, size: 14, color: atlasBlue),
                      const SizedBox(width: 6),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          'Partials ($rowCount)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: atlasBlue,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                divider,
                Flexible(
                  child: isLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.8,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Memuat data...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: rowCount,
                          separatorBuilder: (_, __) => divider,
                          itemBuilder: (_, i) {
                            final r = displayRows[i];
                            return _PartialRowItem(
                              noRejectPartial: r.noRejectPartial,
                              sourceType: r.sourceType,
                              noProduksi: r.noProduksi,
                              tanggalProduksi: r.tanggalProduksi,
                              namaMesin: r.namaMesin,
                              jamProduksi: r.jamProduksi,
                              shift: r.shift,
                              berat: r.berat,
                            );
                          },
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

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tidak ada partial untuk Reject ini',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

class _PartialRowItem extends StatelessWidget {
  final String noRejectPartial;
  final String? sourceType;
  final String? noProduksi;
  final String? tanggalProduksi;
  final String? namaMesin;
  final String? jamProduksi;
  final String? shift;
  final double berat;

  const _PartialRowItem({
    required this.noRejectPartial,
    required this.sourceType,
    required this.noProduksi,
    required this.tanggalProduksi,
    required this.namaMesin,
    required this.jamProduksi,
    required this.shift,
    required this.berat,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final isConsumed = sourceType != null && sourceType!.trim().isNotEmpty;
    final mesin = (namaMesin ?? '').trim();
    final kodeProduksi = (noProduksi ?? '').trim();
    final tgl = (tanggalProduksi ?? '').trim();

    final labelTop = isConsumed
        ? (mesin.isNotEmpty ? mesin : 'Dipakai $sourceType')
        : 'Belum dipakai';

    final subtitleProduksi = kodeProduksi.isEmpty ? '-' : kodeProduksi;

    final tanggalDisplay = (tgl.isEmpty || tgl == '-') ? '-' : formatDateToFullId(tgl);

    final jamShiftParts = <String>[];
    if (jamProduksi != null && jamProduksi!.trim().isNotEmpty) {
      jamShiftParts.add(jamProduksi!.trim());
    }
    if (shift != null && shift!.trim().isNotEmpty) {
      jamShiftParts.add('Shift ${shift!.trim()}');
    }
    final jamShiftText = jamShiftParts.isEmpty ? '-' : jamShiftParts.join(' | ');

    return InkWell(
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              isConsumed ? Icons.link : Icons.inventory_outlined,
              color: isConsumed ? Colors.green.shade600 : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelTop,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$noRejectPartial -> $subtitleProduksi',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tanggalDisplay,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          jamShiftText,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                '${berat.isFinite ? berat.toStringAsFixed(2) : '-'} kg',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
