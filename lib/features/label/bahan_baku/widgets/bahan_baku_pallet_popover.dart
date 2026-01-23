// lib/features/production/bahan_baku/widgets/bahan_baku_pallet_popover.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/pdf_print_service.dart';
import '../../../../core/services/token_storage.dart';
import '../model/bahan_baku_pallet.dart';

class BahanBakuPalletPopover extends StatelessWidget {
  final BahanBakuPallet pallet;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  /// kalau mau override dari luar (optional)
  final VoidCallback? onPrint;

  /// base URL API crystalreport kamu
  final String apiBaseUrl;

  /// username optional (kalau tidak diisi, coba ambil dari TokenStorage)
  final String? username;

  const BahanBakuPalletPopover({
    super.key,
    required this.pallet,
    required this.onClose,
    required this.onViewDetails,
    this.onPrint,
    this.apiBaseUrl = 'https://192.168.10.100:3000',
    this.username,
  });

  void _runAndClose(VoidCallback action) {
    onClose();
    action();
  }

  Future<void> _copyNoPallet(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: pallet.noPallet));
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      SnackBar(
        content: Text('NoPallet "${pallet.noPallet}" disalin'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _resolveUsername() async {
    if (username != null && username!.trim().isNotEmpty) return username!.trim();

    // Kalau TokenStorage kamu punya method getUsername(), pakai ini.
    // Jika beda namanya, sesuaikan.
    try {
      final u = "await TokenStorage.getUsername()";
      if (u != null && u.trim().isNotEmpty) return u.trim();
    } catch (_) {}

    return null; // biarkan null kalau memang tidak ada
  }

  Future<void> _defaultPrint(BuildContext context) async {
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    final u = await _resolveUsername();

    // ✅ siapkan query yang sama dengan endpoint contoh kamu
    final query = <String, String>{
      'reportName': 'LabelPalletBB',
      'NoBahanBaku': pallet.noBahanBaku,
      'NoPallet': pallet.noPallet,
      if (u != null) 'Username': u,
    };

    // ✅ build URL + log
    final base = apiBaseUrl.replaceAll(RegExp(r'\/+$'), ''); // trim trailing /
    final qs = query.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final urlToLog = '$base/api/crystalreport/pps/export-pdf?$qs';
    debugPrint('[BB-PRINT] $urlToLog');

    // (optional) log juga query object biar gampang compare
    debugPrint('[BB-PRINT] query=$query');

    final pdfService = PdfPrintService(
      baseUrl: base,
      defaultSystem: 'pps',
    );

    // ✅ panggil service kamu seperti biasa
    await pdfService.printReport80mm(
      context: rootCtx,
      reportName: 'LabelPalletBB',
      query: {
        'NoBahanBaku': pallet.noBahanBaku,
        'NoPallet': pallet.noPallet,
        if (u != null) 'Username': u,
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);

    final isPassed = pallet.idStatus == 1;
    final statusColor = isPassed ? Colors.green : Colors.orange;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(Icons.view_module, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pallet.noPallet,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pallet.namaJenisPlastik,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Salin NoPallet',
                    icon: Icon(Icons.copy_outlined, color: Colors.white.withOpacity(0.9)),
                    onPressed: () => _copyNoPallet(context),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Info Section (tetap seperti punyamu)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.category,
                    label: 'Jenis',
                    value: pallet.namaJenisPlastik,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.warehouse,
                    label: 'Warehouse',
                    value: pallet.namaWarehouse,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          icon: Icons.flag,
                          label: 'Status',
                          value: pallet.statusText,
                          valueColor: statusColor.shade700,
                        ),
                      ),
                      if (pallet.blok != null || pallet.idLokasi != null)
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.location_on,
                            label: 'Lokasi',
                            value: '${pallet.blok ?? ''}${pallet.idLokasi ?? ''}',
                          ),
                        ),
                    ],
                  ),
                  if (pallet.keterangan != null && pallet.keterangan!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.note,
                      label: 'Keterangan',
                      value: pallet.keterangan!,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),

            divider,

            // View Details
            _MenuTile(
              icon: Icons.info_outline,
              label: 'View Details',
              enabled: true,
              onTap: () => _runAndClose(onViewDetails),
            ),

            divider,

            // Print (SAMA seperti broker: klik -> tampilkan PDF)
            _MenuTile(
              icon: Icons.print_outlined,
              label: 'Print',
              enabled: true,
              onTap: () => _runAndClose(() async {
                if (onPrint != null) {
                  onPrint!();
                } else {
                  await _defaultPrint(context);
                }
              }),
            ),

            divider,

            if (_hasQCData())
              _MenuTile(
                icon: Icons.science_outlined,
                label: 'Info Quality Control',
                enabled: true,
                onTap: () => _runAndClose(() => _showQCInfo(context)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasQCData() {
    return pallet.moisture != null ||
        pallet.meltingIndex != null ||
        pallet.elasticity != null ||
        pallet.tenggelam != null ||
        pallet.density != null ||
        pallet.density2 != null ||
        pallet.density3 != null;
  }

  void _showQCInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.science, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Quality Control Data'),
          ],
        ),
        content: const Text('... (tetap seperti punyamu)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltipWhenDisabled;
  final Color? iconColor;
  final TextStyle? textStyle;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.tooltipWhenDisabled,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = enabled ? (iconColor ?? theme.iconTheme.color) : Colors.grey;
    final effectiveTextStyle = (textStyle ?? theme.textTheme.bodyMedium)?.copyWith(
      color: enabled ? (textStyle?.color ?? theme.textTheme.bodyMedium?.color) : Colors.grey,
    );

    final tile = InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: effectiveIconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: effectiveTextStyle, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );

    if (!enabled && (tooltipWhenDisabled?.isNotEmpty ?? false)) {
      return Tooltip(message: tooltipWhenDisabled!, child: Opacity(opacity: 0.55, child: tile));
    }
    return tile;
  }
}
