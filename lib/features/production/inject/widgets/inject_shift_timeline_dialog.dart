// lib/features/production/inject/widgets/inject_shift_timeline_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Entry model ───────────────────────────────────────────────────────────────

class InjectShiftTimelineEntry {
  const InjectShiftTimelineEntry({
    required this.noProduksi,
    this.hourStart,
    this.hourEnd,
    this.isLocked = false,
    this.outputs = const [],
    this.namaCetakan,
    this.namaWarna,
    this.namaFurnitureMaterial,
  });

  final String noProduksi;
  final String? hourStart;
  final String? hourEnd;
  final bool isLocked;
  final List<String> outputs;
  final String? namaCetakan;
  final String? namaWarna;
  final String? namaFurnitureMaterial;
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class InjectShiftTimelineDialog extends StatefulWidget {
  const InjectShiftTimelineDialog({
    super.key,
    required this.namaMesin,
    required this.tanggal,
    required this.shift,
    required this.currentNoProduksi,
    required this.primaryColor,
    required this.borderColor,
    required this.loadTimeline,
    this.emptyMessage = 'Belum ada riwayat produksi pada shift ini.',
  });

  final String? namaMesin;
  final DateTime tanggal;
  final int shift;
  final String currentNoProduksi;
  final Color primaryColor;
  final Color borderColor;
  final Future<List<InjectShiftTimelineEntry>> Function() loadTimeline;
  final String emptyMessage;

  @override
  State<InjectShiftTimelineDialog> createState() =>
      _InjectShiftTimelineDialogState();
}

class _InjectShiftTimelineDialogState
    extends State<InjectShiftTimelineDialog> {
  late Future<List<InjectShiftTimelineEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadTimeline();
  }

  void _reload() => setState(() => _future = widget.loadTimeline());

  int _toMin(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return 0;
    final p = hhmm.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  Widget _buildTimeline(List<InjectShiftTimelineEntry> list) {
    final sorted = [...list]
      ..sort((a, b) => _toMin(a.hourStart).compareTo(_toMin(b.hourStart)));
    final lastEnd = (sorted.isEmpty ? '' : sorted.last.hourEnd ?? '').trim();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length + 1,
      itemBuilder: (_, i) {
        // ── Terminal node ──────────────────────────────────────
        if (i == sorted.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
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
                    border:
                        Border.all(color: Colors.grey.shade400, width: 1.5),
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
            ),
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
              // ── Jam ───────────────────────────────────────────
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    jamStart.isNotEmpty ? jamStart : '--:--',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? widget.primaryColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Node + vertical line ───────────────────────────
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
                      child: Container(
                        width: 1.5,
                        color: Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // ── Content card ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: _EntryCard(
                    entry: prod,
                    isCurrent: isCurrent,
                    primaryColor: widget.primaryColor,
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
    final tglLabel =
        DateFormat('dd MMM yyyy', 'id_ID').format(widget.tanggal.toLocal());

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.view_timeline_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
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

            // ── Body ─────────────────────────────────────────────
            Flexible(
              child: FutureBuilder<List<InjectShiftTimelineEntry>>(
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
                          Icon(Icons.error_outline,
                              color: Colors.red.shade400, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade600),
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: list.isEmpty
                        ? Text(
                            widget.emptyMessage,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500),
                          )
                        : _buildTimeline(list),
                  );
                },
              ),
            ),

            // ── Footer ───────────────────────────────────────────
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

// ── Entry card ────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.isCurrent,
    required this.primaryColor,
  });

  final InjectShiftTimelineEntry entry;
  final bool isCurrent;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final accentColor = isCurrent
        ? primaryColor
        : entry.isLocked
            ? const Color(0xFFF97316)
            : const Color(0xFF374151);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? primaryColor.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? primaryColor.withValues(alpha: 0.25)
              : entry.isLocked
                  ? const Color(0xFFF97316).withValues(alpha: 0.2)
                  : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── No produksi + badge ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.noProduksi,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
              if (isCurrent)
                _Chip(
                  label: 'Berlangsung',
                  color: primaryColor,
                )
              else if (entry.isLocked)
                const _Chip(
                  label: 'Locked',
                  color: Color(0xFFF97316),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Output jenis ─────────────────────────────────────
          if (entry.outputs.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Output',
              value: entry.outputs.join('\n'),
              valueStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ── Cetakan ──────────────────────────────────────────
          if ((entry.namaCetakan ?? '').trim().isNotEmpty) ...[
            _InfoRow(
              icon: Icons.view_in_ar_rounded,
              label: 'Cetakan',
              value: entry.namaCetakan!.trim(),
            ),
            const SizedBox(height: 4),
          ],

          // ── Warna ────────────────────────────────────────────
          if ((entry.namaWarna ?? '').trim().isNotEmpty) ...[
            _InfoRow(
              icon: Icons.palette_outlined,
              label: 'Warna',
              value: entry.namaWarna!.trim(),
            ),
            const SizedBox(height: 4),
          ],

          // ── Material ─────────────────────────────────────────
          if ((entry.namaFurnitureMaterial ?? '').trim().isNotEmpty)
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Material',
              value: entry.namaFurnitureMaterial!.trim(),
            ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF374151),
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
