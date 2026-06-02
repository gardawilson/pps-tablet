import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductionWorkspaceToolbar extends StatelessWidget {
  final String noProduksi;
  final bool isLocked;
  final int? idMesin;
  final int? shift;
  final DateTime? tglProduksi;
  final String? hourStart;
  final String? hourEnd;
  final String? namaJenis;
  final Color primaryColor;

  final VoidCallback? onGanti;
  final VoidCallback? onRiwayat;
  final VoidCallback? onRefresh;

  const ProductionWorkspaceToolbar({
    super.key,
    required this.noProduksi,
    required this.isLocked,
    required this.primaryColor,
    this.idMesin,
    this.shift,
    this.tglProduksi,
    this.hourStart,
    this.hourEnd,
    this.namaJenis,
    this.onGanti,
    this.onRiwayat,
    this.onRefresh,
  });

  bool _isWithinTimeRange() {
    final now = DateTime.now();
    final hStart = (hourStart ?? '').trim();
    final hEnd = (hourEnd ?? '').trim();
    if (tglProduksi == null) return false;

    final isToday =
        tglProduksi!.year == now.year &&
        tglProduksi!.month == now.month &&
        tglProduksi!.day == now.day;
    if (!isToday) return false;
    if (hStart.isEmpty && hEnd.isEmpty) return false;

    int toMin(String hhmm) {
      final p = hhmm.split(':');
      if (p.length < 2) return -1;
      final h = int.tryParse(p[0]) ?? -1;
      final m = int.tryParse(p[1]) ?? -1;
      if (h < 0 || m < 0) return -1;
      return h * 60 + m;
    }

    final nowMin = now.hour * 60 + now.minute;
    final startMin = hStart.isNotEmpty ? toMin(hStart) : 0;
    final endMin = hEnd.isNotEmpty ? toMin(hEnd) : 23 * 60 + 59;
    if (startMin < 0 || endMin < 0) return false;
    if (endMin < startMin) return nowMin >= startMin || nowMin <= endMin;
    return nowMin >= startMin && nowMin <= endMin;
  }

  @override
  Widget build(BuildContext context) {
    const activeAccent = Color(0xFF00897B);
    const pastAccent = Color(0xFFF59E0B);
    const lockedAccent = Color(0xFFF97316);
    const borderColor = Color(0xFFE2E6EA);

    final tglText = tglProduksi == null
        ? null
        : DateFormat('dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());

    final hStart = (hourStart ?? '').trim();
    final hEnd = (hourEnd ?? '').trim();
    final isActive = !isLocked && _isWithinTimeRange();
    final hasJenis = (namaJenis ?? '').trim().isNotEmpty;
    final canGanti = idMesin != null && shift != null && tglProduksi != null;

    final accentColor = isLocked
        ? lockedAccent
        : (isActive ? activeAccent : pastAccent);
    final statusLabel = isLocked
        ? 'Locked'
        : (isActive ? 'Real-Time' : 'Backdate');
    final statusIcon = isLocked
        ? Icons.lock_outline
        : (isActive ? Icons.play_circle_outline : Icons.history_rounded);
    final jamText = (hStart.isNotEmpty || hEnd.isNotEmpty)
        ? '${hStart.isNotEmpty ? hStart : "--:--"} – ${hEnd.isNotEmpty ? hEnd : "--:--"}'
        : '-- : --';

    Widget infoTag(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.grey.shade400),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    Widget dot() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade300,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    Widget vline() => Container(
      width: 1,
      height: 18,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: accentColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 10, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              vline(),
              Flexible(
                child: Text(
                  hasJenis ? namaJenis!.trim() : 'Belum ada jenis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hasJenis ? accentColor : Colors.grey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canGanti) ...[
                const SizedBox(width: 4),
                Material(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: onGanti,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Ganti',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Material(
                color: primaryColor,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: onRiwayat,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Riwayat',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              vline(),
              if (tglText != null) ...[
                infoTag(Icons.calendar_today_outlined, tglText),
                dot(),
              ],
              if (shift != null) ...[
                infoTag(Icons.group_outlined, 'Shift $shift'),
                dot(),
              ],
              infoTag(Icons.schedule_outlined, jamText),
              const Spacer(),
              Text(
                noProduksi,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 26,
                height: 26,
                child: IconButton(
                  tooltip: 'Refresh',
                  padding: EdgeInsets.zero,
                  onPressed: onRefresh,
                  icon: Icon(
                    Icons.refresh,
                    size: 15,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
