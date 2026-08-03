import 'package:flutter/material.dart';

import '../model/so_v2_label_row.dart';

const _kBorder = Color(0xFFE2E6EA);
const _kSuccess = Color(0xFF0A7349);
const _kWarning = Color(0xFFB45309);
const _kWarningBg = Color(0xFFFFF7ED);

class SoV2LabelTile extends StatelessWidget {
  final SoV2LabelRow row;
  final String weightUnit;

  /// Non-null kalau user boleh menghapus hasil scan yang salah lokasi
  /// (permission `stockopname:create` & SO belum selesai) — tombol hapus
  /// hanya tampil untuk baris yang [SoV2LabelRow.isLocationMismatch].
  final VoidCallback? onDeleteMismatch;
  final bool isDeleting;

  const SoV2LabelTile({
    super.key,
    required this.row,
    this.weightUnit = 'kg',
    this.onDeleteMismatch,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final scanned = row.isScanned;
    final mismatch = scanned && row.isLocationMismatch;
    final value = row.weightOrCountDisplay(weightUnit: weightUnit);

    final IconData icon;
    final Color iconColor;
    final Color textColor;
    if (mismatch) {
      icon = Icons.help_rounded;
      iconColor = _kWarning;
      textColor = _kWarning;
    } else if (scanned) {
      icon = Icons.check_circle_rounded;
      iconColor = _kSuccess;
      textColor = _kSuccess;
    } else {
      icon = Icons.circle_outlined;
      iconColor = Colors.grey.shade400;
      textColor = const Color(0xFF1A1D23);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: mismatch
            ? _kWarningBg
            : (scanned ? const Color(0xFFF3FBF7) : Colors.white),
        border: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.primaryValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
          if (mismatch) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Discan dari lokasi ${_scannedLocationLabel(row)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _kWarning,
                      ),
                    ),
                  ),
                  if (onDeleteMismatch != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: isDeleting ? null : onDeleteMismatch,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                width: 11,
                                height: 11,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: _kWarning,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 13,
                                    color: _kWarning,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Hapus & scan ulang',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: _kWarning,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _scannedLocationLabel(SoV2LabelRow row) {
    final blok = row.scannedBlok;
    final locationId = row.scannedLocationId;
    if (blok == null || locationId == null) return 'lain';
    return '$blok$locationId';
  }
}
