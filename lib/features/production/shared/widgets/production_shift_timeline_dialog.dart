import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductionShiftTimelineEntry {
  final String noProduksi;
  final String? hourStart;
  final String? hourEnd;
  final bool isLocked;
  final String? subtitle;

  const ProductionShiftTimelineEntry({
    required this.noProduksi,
    this.hourStart,
    this.hourEnd,
    this.isLocked = false,
    this.subtitle,
  });
}

class ProductionShiftTimelineDialog extends StatefulWidget {
  const ProductionShiftTimelineDialog({
    super.key,
    required this.namaMesin,
    required this.tanggal,
    required this.shift,
    required this.currentNoProduksi,
    required this.primaryColor,
    required this.borderColor,
    required this.loadTimeline,
    this.emptyMessage = 'Tidak ada produksi untuk shift ini.',
  });

  final String? namaMesin;
  final DateTime tanggal;
  final int shift;
  final String currentNoProduksi;
  final Color primaryColor;
  final Color borderColor;
  final Future<List<ProductionShiftTimelineEntry>> Function() loadTimeline;
  final String emptyMessage;

  @override
  State<ProductionShiftTimelineDialog> createState() =>
      _ProductionShiftTimelineDialogState();
}

class _ProductionShiftTimelineDialogState extends State<ProductionShiftTimelineDialog> {
  late Future<List<ProductionShiftTimelineEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadTimeline();
  }

  void _reload() {
    setState(() {
      _future = widget.loadTimeline();
    });
  }

  Widget _buildTimeline(List<ProductionShiftTimelineEntry> list) {
    final sorted = [...list]
      ..sort((a, b) {
        int toMin(String? hhmm) {
          if (hhmm == null || hhmm.isEmpty) return 0;
          final p = hhmm.split(':');
          return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
        }
        return toMin(a.hourStart).compareTo(toMin(b.hourStart));
      });
    final lastEnd = (sorted.isEmpty ? '' : sorted.last.hourEnd ?? '').trim();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length + 1,
      itemBuilder: (_, i) {
        if (i == sorted.length) {
          return Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  lastEnd,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Selesai',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        }

        final prod = sorted[i];
        final isCurrent = prod.noProduksi == widget.currentNoProduksi;
        final isLast = i == sorted.length - 1;
        final jamStart = (prod.hourStart ?? '').trim();
        final nodeColor = isCurrent
            ? widget.primaryColor
            : prod.isLocked
                ? const Color(0xFFF97316)
                : Colors.grey.shade400;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    jamStart.isNotEmpty ? jamStart : '--:--',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? widget.primaryColor : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? widget.primaryColor : Colors.white,
                      border: Border.all(color: nodeColor, width: 2),
                    ),
                    child: isCurrent
                        ? Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 1.5, color: Colors.grey.shade200),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              prod.noProduksi,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? widget.primaryColor
                                    : const Color(0xFF1A1D23),
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Sedang berlangsung',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: widget.primaryColor,
                                ),
                              ),
                            )
                          else if (prod.isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Locked',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF97316),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if ((prod.subtitle ?? '').trim().isNotEmpty)
                        Text(
                          prod.subtitle!.trim(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tglLabel = DateFormat('dd MMM yyyy', 'id_ID').format(widget.tanggal.toLocal());

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.view_list_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Produksi ${widget.namaMesin ?? ''} (Shift ${widget.shift})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          tglLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<ProductionShiftTimelineEntry>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snap.error.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  final list = snap.data ?? [];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: list.isEmpty
                        ? Text(
                            widget.emptyMessage,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          )
                        : _buildTimeline(list),
                  );
                },
              ),
            ),
            Divider(height: 1, color: widget.borderColor),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
