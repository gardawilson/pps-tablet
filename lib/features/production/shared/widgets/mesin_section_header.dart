import 'package:flutter/material.dart';

import 'production_stat_badge.dart';

/// Header section panel kiri (daftar mesin).
/// Menampilkan judul, badge aktif/nonaktif, dan tombol refresh.
/// Generic — bisa dipakai di semua modul production.
class MesinSectionHeader extends StatelessWidget {
  const MesinSectionHeader({
    super.key,
    required this.title,
    required this.activeCount,
    required this.inactiveCount,
    required this.isLoading,
    this.onToggleRiwayat,
    this.isRiwayatVisible = true,
  });

  final String title;
  final int activeCount;
  final int inactiveCount;
  final bool isLoading;
  final VoidCallback? onToggleRiwayat;
  final bool isRiwayatVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          if (!isLoading) ...[
            const SizedBox(width: 10),
            ProductionStatBadge(
              count: activeCount,
              label: 'Aktif',
              color: const Color(0xFF16A34A),
              bg: const Color(0xFFDCFCE7),
            ),
            const SizedBox(width: 6),
            ProductionStatBadge(
              count: inactiveCount,
              label: 'Tidak Aktif',
              color: const Color(0xFFDC2626),
              bg: const Color(0xFFFEE2E2),
            ),
          ],
          const Spacer(),
          if (onToggleRiwayat != null)
            IconButton(
              onPressed: onToggleRiwayat,
              icon: Icon(
                isRiwayatVisible
                    ? Icons.view_list_rounded
                    : Icons.view_list_outlined,
                size: 16,
                color: isRiwayatVisible
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF6B7280),
              ),
              tooltip: isRiwayatVisible
                  ? 'Sembunyikan Riwayat'
                  : 'Tampilkan Riwayat',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}
