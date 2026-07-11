import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/stok_item_data.dart';

/// Header bar untuk section "Stok Item", konsisten dengan
/// [ProductionRiwayatHeader] pada riwayat produksi.
class StokItemHeader extends StatelessWidget {
  const StokItemHeader({
    super.key,
    this.onRefresh,
    this.title = 'Bahan Baku Proses',
  });

  final VoidCallback? onRefresh;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
          const Spacer(),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              color: const Color(0xFF9CA3AF),
              hoverColor: const Color(0xFFEFF6FF),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

/// List stok sisa (sak & berat) untuk section "Stok Item".
/// Generik atas [StokItemData] agar bisa dipakai untuk stok bahan baku
/// proses, stok washing, dsb.
class StokItemList<T extends StokItemData> extends StatelessWidget {
  const StokItemList({
    super.key,
    required this.items,
    required this.isLoading,
    this.errorMessage,
    this.onTap,
    this.oldestDateOf,
  });

  final List<T> items;
  final bool isLoading;
  final String? errorMessage;

  /// Dipanggil saat sebuah item stok di-tap — biasanya untuk menampilkan
  /// rincian label (per pallet/sak) dari item tersebut.
  final ValueChanged<T>? onTap;

  /// Jika disediakan, tanggal item tertua ditampilkan sebagai subtitle di
  /// bawah nama — mis. untuk stok yang butuh perhatian karena sudah lama
  /// mengendap (bonggolan, dsb).
  final DateTime? Function(T item)? oldestDateOf;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Gagal memuat stok item\n$errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data stok item',
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    final sortedItems = [...items]..sort((a, b) {
      final aEmpty = a.beratSisa <= 0;
      final bEmpty = b.beratSisa <= 0;
      if (aEmpty == bEmpty) return 0;
      return aEmpty ? 1 : -1;
    });

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: sortedItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        final isEmpty = item.sakSisa <= 0 && item.beratSisa <= 0;
        final oldestDate = isEmpty ? null : oldestDateOf?.call(item);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap == null ? null : () => onTap!(item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isEmpty ? const Color(0xFFF9FAFB) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEmpty ? const Color(0xFFE5E7EB) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nama,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (oldestDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Tertua sejak '
                              '${DateFormat('dd MMM yyyy', 'id_ID').format(oldestDate.toLocal())}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.beratSisa.toStringAsFixed(2)} kg',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isEmpty ? const Color(0xFF9CA3AF) : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
