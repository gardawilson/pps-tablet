import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton untuk kolom list vertikal bergaya picker (dot + bar teks).
/// Dipakai di dialog picker seperti cetakan/warna/material.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key, this.itemCount = 10});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: ListView.builder(
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
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

/// Skeleton untuk tabel panduan (4 kolom flex 5:3:2:3) dengan zebra striping.
class TableRowSkeleton extends StatelessWidget {
  const TableRowSkeleton({
    super.key,
    this.itemCount = 12,
    this.flexes = const [5, 3, 2, 3],
  });

  final int itemCount;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(
            children: [
              for (int idx = 0; idx < flexes.length; idx++) ...[
                if (idx > 0) const SizedBox(width: 12),
                Expanded(
                  flex: flexes[idx],
                  child: Container(
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
