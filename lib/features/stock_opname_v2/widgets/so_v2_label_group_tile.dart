import 'package:flutter/material.dart';

import '../model/so_v2_label_group.dart';
import '../utils/so_v2_number_format.dart';
import 'so_v2_label_tile.dart';

const _kBorder = Color(0xFFE2E6EA);
const _kSurface = Color(0xFFF8F9FB);
const _kSuccess = Color(0xFF0A7349);
const _kPrimary = Color(0xFF1E6FD9);

/// Satu jenis label (mis. "PP BONGGOL HITAM LEMARI") dengan baris-baris
/// label snapshot di dalamnya. Snapshot label sudah datang tergrup per
/// jenis dari backend, jadi ditampilkan sebagai section tabel, bukan
/// flat list — header section rata dengan header kolom pada tabel lokasi.
class SoV2LabelGroupTile extends StatelessWidget {
  final SoV2LabelGroup group;
  final String weightUnit;

  const SoV2LabelGroupTile({
    super.key,
    required this.group,
    this.weightUnit = 'kg',
  });

  @override
  Widget build(BuildContext context) {
    final complete =
        group.labelCount > 0 && group.scannedCount >= group.labelCount;
    final color = complete ? _kSuccess : _kPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: const BoxDecoration(
            color: _kSurface,
            border: Border(
              top: BorderSide(color: _kBorder),
              bottom: BorderSide(color: _kBorder),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group.typeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Color(0xFF1A1D23),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${group.scannedCount}/${group.labelCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${soV2FormatQty(group.totalWeight)} $weightUnit',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        for (final row in group.labels)
          SoV2LabelTile(row: row, weightUnit: weightUnit),
      ],
    );
  }
}
