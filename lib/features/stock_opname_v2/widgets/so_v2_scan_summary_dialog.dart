// lib/features/stock_opname_v2/widgets/so_v2_scan_summary_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/so_v2_scan_summary.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);
const _kInk = Color(0xFF1A1D23);
const _kMuted = Color(0xFF6B7280);

const _kGold = Color(0xFFF59E0B);
const _kSilver = Color(0xFF94A3B8);
const _kBronze = Color(0xFFB45309);

/// Dialog "siapa scan berapa banyak" — leaderboard performa scan per user
/// untuk satu stock opname yang sudah selesai. Dipicu dari tombol di
/// samping badge "Selesai" pada header panel blok.
Future<void> showSoV2ScanSummaryDialog(
  BuildContext context, {
  required SoV2ScanSummary summary,
  required int totalLabelCount,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => SoV2ScanSummaryDialog(
      summary: summary,
      totalLabelCount: totalLabelCount,
    ),
  );
}

class SoV2ScanSummaryDialog extends StatefulWidget {
  final SoV2ScanSummary summary;

  /// Total label keseluruhan di kategori/section ini (bukan cuma yang
  /// sudah di-scan) — dari panel blok, karena endpoint scan-summary sendiri
  /// tidak membawa angka ini.
  final int totalLabelCount;

  const SoV2ScanSummaryDialog({
    super.key,
    required this.summary,
    required this.totalLabelCount,
  });

  @override
  State<SoV2ScanSummaryDialog> createState() => _SoV2ScanSummaryDialogState();
}

class _SoV2ScanSummaryDialogState extends State<SoV2ScanSummaryDialog> {
  final Set<String> _expanded = {};

  void _toggle(String username) {
    setState(() {
      if (!_expanded.remove(username)) _expanded.add(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = [...widget.summary.data]
      ..sort((a, b) => b.labelCount.compareTo(a.labelCount));

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: users.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Belum ada user yang melakukan scan.',
                          style: TextStyle(color: _kMuted, fontSize: 12.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (_, i) => _UserRow(
                        rank: i + 1,
                        user: users[i],
                        expanded: _expanded.contains(users[i].username),
                        onTap: () => _toggle(users[i].username),
                      ),
                    ),
            ),
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kMuted,
                    side: const BorderSide(color: _kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FB),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.leaderboard_rounded,
              color: _kPrimary,
              size: 18,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Scan User',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.summary.stockOpnameNo} · ${widget.summary.totalUsers} user · ${widget.summary.totalScanned}/${widget.totalLabelCount} label',
                  style: const TextStyle(fontSize: 11.5, color: _kMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: _kMuted),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final int rank;
  final SoV2ScanSummaryUser user;
  final bool expanded;
  final VoidCallback onTap;

  const _UserRow({
    required this.rank,
    required this.user,
    required this.expanded,
    required this.onTap,
  });

  Color? get _rankColor {
    switch (rank) {
      case 1:
        return _kGold;
      case 2:
        return _kSilver;
      case 3:
        return _kBronze;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Rank badge: medali untuk 3 besar, angka polos sisanya.
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (rankColor ?? _kMuted).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: rankColor != null
                      ? Icon(Icons.emoji_events_rounded,
                          size: 14, color: rankColor)
                      : Text(
                          '$rank',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kMuted,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${user.labelCount} label',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, left: 36),
                      child: _buildTimeDetail(),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDetail() {
    final timeFmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final first = user.firstScanAt != null
        ? timeFmt.format(user.firstScanAt!.toLocal())
        : '-';
    final last = user.lastScanAt != null
        ? timeFmt.format(user.lastScanAt!.toLocal())
        : '-';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timeLine(Icons.play_circle_outline_rounded, 'Scan pertama', first),
          const SizedBox(height: 4),
          _timeLine(Icons.flag_outlined, 'Scan terakhir', last),
        ],
      ),
    );
  }

  Widget _timeLine(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _kMuted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10.5, color: _kMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
      ],
    );
  }
}
