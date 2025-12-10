import 'package:flutter/material.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';
import 'package:provider/provider.dart';

import '../view_model/reject_view_model.dart';
import './interactive_popover.dart';

/// Show the partial info for Reject
/// as an InteractivePopover with instant display
Future<void> showRejectPartialInfoPopover({
  required BuildContext context,
  required RejectViewModel vm,
  required String noReject,
  required InteractivePopover popover,
  required Offset globalPosition,
}) async {
  if (!context.mounted) return;

  // 🟦 Tampilkan popover dulu (state loading)
  await popover.show(
    context: context,
    globalPosition: globalPosition,
    maxWidth: 300,
    maxHeight: 360,
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

  // 🟦 Baru fetch data (popover sudah tampil)
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
  State<_RejectPartialInfoCard> createState() =>
      _RejectPartialInfoCardState();
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
    final divider =
    Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);

    return Consumer<RejectViewModel>(
      builder: (ctx, vm, __) {
        final isLoading = vm.isPartialLoading;
        final hasError = vm.partialError != null;
        final info = vm.partialInfo;
        final isEmpty = info == null || info.rows.isEmpty;

        // Error state
        if (hasError && !isLoading) {
          return _ErrorState(error: vm.partialError!);
        }

        // Empty state
        if (isEmpty && !isLoading) {
          return const _EmptyState();
        }

        // Data / loading state
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
                // HEADER (blue gradient)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon box
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Partial Reject',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.noReject,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.scale,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 6),
                                if (isLoading)
                                  Text(
                                    'Memuat...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                  )
                                else
                                  Text(
                                    'Total: ${totalBerat.toStringAsFixed(2)} kg',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.95),
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

                // SMALL HEADER
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.list,
                          size: 14, color: Colors.blue.shade600),
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
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                divider,

                // LIST
                Flexible(
                  child: isLoading
                      ? Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.8),
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

// ERROR STATE
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

// EMPTY STATE
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

// ROW ITEM
class _PartialRowItem extends StatelessWidget {
  final String noRejectPartial;
  final String? sourceType;       // 'BROKER' / null
  final String? noProduksi;
  final String? tanggalProduksi;  // yyyy-MM-dd
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

    final isConsumed =
        sourceType != null && sourceType!.trim().isNotEmpty;

    final mesin = (namaMesin ?? '').trim();
    final kodeProduksi = (noProduksi ?? '').trim();
    final tgl = (tanggalProduksi ?? '').trim();

    final labelTop = isConsumed
        ? (mesin.isNotEmpty ? mesin : 'Dipakai $sourceType')
        : 'Belum dipakai';

    final subtitleProduksi =
    kodeProduksi.isEmpty ? '-' : kodeProduksi;

    String tanggalDisplay;
    if (tgl.isEmpty || tgl == '-') {
      tanggalDisplay = '-';
    } else {
      // tanggalProduksi sudah yyyy-MM-dd dari API
      tanggalDisplay = formatDateToFullId(tgl);
    }

    final jamShiftParts = <String>[];
    if (jamProduksi != null && jamProduksi!.trim().isNotEmpty) {
      jamShiftParts.add(jamProduksi!.trim());
    }
    if (shift != null && shift!.trim().isNotEmpty) {
      jamShiftParts.add('Shift ${shift!.trim()}');
    }
    final jamShiftText =
    jamShiftParts.isEmpty ? '-' : jamShiftParts.join(' • ');

    return InkWell(
      onTap: null, // read-only
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              isConsumed
                  ? Icons.link
                  : Icons.inventory_outlined,
              color:
              isConsumed ? Colors.green.shade600 : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mesin / status konsumsi
                  Text(
                    labelTop,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // NoRejectPartial + NoProduksi
                  Row(
                    children: [
                      const Icon(Icons.tag,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$noRejectPartial → $subtitleProduksi',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Tanggal produksi
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey),
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

                  // Jam + shift
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
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

            // BERAT tag
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
