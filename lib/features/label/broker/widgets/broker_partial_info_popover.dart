// lib/view/widgets/broker_partial_info_popover.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';
import 'package:provider/provider.dart';

import '../view_model/broker_view_model.dart';
import './interactive_popover.dart';

/// Show the partial info as an InteractivePopover with instant display
Future<void> showBrokerPartialInfoPopover({
  required BuildContext context,
  required BrokerViewModel vm,
  required int noSak,
  required InteractivePopover popover,
  required Offset globalPosition,
}) async {
  // ⬇️ Tampilkan popover SEKARANG dengan loading state
  if (!context.mounted) return;

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
      child: _BrokerPartialInfoCard(
        noSak: noSak,
        onClose: () => popover.hide(),
      ),
    ),
  );

  // ⬇️ Fetch data di background (tidak block UI)
  await vm.loadPartialInfo(noSak: noSak);
}

class _BrokerPartialInfoCard extends StatefulWidget {
  final int noSak;
  final VoidCallback onClose;

  const _BrokerPartialInfoCard({
    required this.noSak,
    required this.onClose,
  });

  @override
  State<_BrokerPartialInfoCard> createState() => _BrokerPartialInfoCardState();
}

class _BrokerPartialInfoCardState extends State<_BrokerPartialInfoCard> {
  late BrokerViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = context.read<BrokerViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);

    return Consumer<BrokerViewModel>(
      builder: (ctx, vm, __) {
        // Determine what to show
        bool isLoading = vm.isPartialLoading;
        bool hasError = vm.partialError != null;
        final info = vm.partialInfo;
        bool isEmpty = info == null || info.rows.isEmpty;

        // Show error state
        if (hasError && !isLoading) {
          return _ErrorState(error: vm.partialError!);
        }

        // Show empty state
        if (isEmpty && !isLoading) {
          return _EmptyState();
        }

        // Default data untuk loading state
        final displayRows = isLoading ? <dynamic>[] : (info?.rows ?? []);
        final totalWeight = isLoading ? 0.0 : (info?.totalPartialWeight ?? 0.0);
        final rowCount = displayRows.length;

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header info - Blue Gradient Design
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon Box
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(
                          Icons.event_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Partial Sak ${widget.noSak}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.scale, size: 14, color: Colors.white.withOpacity(0.9)),
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
                                    'Total: ${totalWeight.toStringAsFixed(2)} kg',
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

                // Activities Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 14, color: Colors.blue.shade600),
                      const SizedBox(width: 6),
                      if (isLoading)
                        SizedBox(
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

                // Items List
                Flexible(
                  child: isLoading
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 2.8),
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
                        namaMesin: (r.namaMesin ?? '').isEmpty ? '-' : r.namaMesin!,
                        noProduksi: (r.noProduksi ?? '').isEmpty ? '-' : r.noProduksi!,
                        tglProduksi: (r.tglProduksi ?? '').isEmpty ? '-' : r.tglProduksi!,
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

// Loading State - Fixed Size
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320, minHeight: 360),
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat data...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Error State
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

// Empty State
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tidak ada partial untuk Sak ini',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

// Individual Row Item
class _PartialRowItem extends StatelessWidget {
  final String namaMesin;
  final String noProduksi;
  final String tglProduksi;
  final double berat;

  const _PartialRowItem({
    required this.namaMesin,
    required this.noProduksi,
    required this.tglProduksi,
    required this.berat,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: null, // read-only
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Leading icon
            Icon(Icons.remove_circle_outline, color: Colors.red.shade600, size: 18),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Machine name
                  Text(
                    namaMesin,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Meta row
                  Row(
                    children: [
                      Icon(Icons.tag, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          noProduksi,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Meta row
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          formatDateToFullId(tglProduksi),
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

            // Weight tag
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