// lib/features/label/washing/widgets/washing_history_dialog.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/washing_view_model.dart';
import '../model/washing_history_model.dart';

class WashingHistoryDialog extends StatelessWidget {
  final String noWashing;
  const WashingHistoryDialog({super.key, required this.noWashing});

  Color _badgeColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'DELETE':
        return Colors.red;
      case 'UPDATE':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WashingViewModel>();
    final items = vm.history;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950, maxHeight: 650),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Riwayat Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          noWashing,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),

            if (vm.isHistoryLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if ((vm.historyError).trim().isNotEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(
                          vm.historyError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_outlined, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _HistoryCard(
                      item: items[i],
                      badgeColor: _badgeColor,
                      index: i,
                      total: items.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final WashingHistorySession item;
  final Color Function(String action) badgeColor;
  final int index;
  final int total;

  const _HistoryCard({
    required this.item,
    required this.badgeColor,
    required this.index,
    required this.total,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool expanded = false;

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;

    final s = v.toString().trim();
    if (s.isEmpty) return null;

    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatDateTime(dynamic value) {
    final d = _parseDate(value);
    if (d == null) return '-';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(d.year, d.month, d.day);

    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    if (dateToCheck == today) {
      return 'Hari ini, $time';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Kemarin, $time';
    } else {
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year;
      return '$day/$month/$year, $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final badge = (it.sessionAction).toUpperCase();

    String actionLabel = '';
    IconData actionIcon = Icons.edit;

    switch (badge) {
      case 'CREATE':
        actionLabel = 'Dibuat';
        actionIcon = Icons.add_circle_outline;
        break;
      case 'UPDATE':
        actionLabel = 'Diubah';
        actionIcon = Icons.edit_outlined;
        break;
      case 'DELETE':
        actionLabel = 'Dihapus';
        actionIcon = Icons.delete_outline;
        break;
      default:
        actionLabel = badge;
        actionIcon = Icons.circle_outlined;
    }

    return Material(
      elevation: expanded ? 4 : 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => expanded = !expanded),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.badgeColor(badge).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Timeline indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.badgeColor(badge).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#${widget.index + 1}',
                          style: TextStyle(
                            color: widget.badgeColor(badge),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.badgeColor(badge),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(actionIcon, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      actionLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 13, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                it.actor,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Icon(Icons.access_time, size: 13, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(it.startTime),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              if (expanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: _buildDetailedComparison(it),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedComparison(WashingHistorySession item) {
    final badge = (item.sessionAction).toUpperCase();

    if (badge == 'CREATE') {
      return _DataCard(
        title: 'Data yang Dibuat',
        color: Colors.green,
        icon: Icons.add_circle,
        session: item,
        side: _Side.newSide,
        sessionAction: badge,
        diff: null,
      );
    }

    if (badge == 'DELETE') {
      return _DataCard(
        title: 'Data yang Dihapus',
        color: Colors.red,
        icon: Icons.remove_circle,
        session: item,
        side: _Side.old,
        sessionAction: badge,
        diff: null,
      );
    }

    // UPDATE
    final d = _computeDiff(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _DataCard(
            title: 'Data Sebelum',
            color: Colors.red,
            icon: Icons.history,
            session: item,
            side: _Side.old,
            sessionAction: badge,
            diff: d,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 40),
          child: Icon(Icons.arrow_forward, size: 24),
        ),
        Expanded(
          child: _DataCard(
            title: 'Data Sesudah',
            color: Colors.green,
            icon: Icons.update,
            session: item,
            side: _Side.newSide,
            sessionAction: badge,
            diff: d,
          ),
        ),
      ],
    );
  }
}

enum _Side { old, newSide }

class _DiffResult {
  final Set<String> changedHeaderKeys; // keys header yang berubah
  final Set<int> changedSakNos; // NoSak yang ada di old & new tapi berbeda (misal Berat beda)
  final Set<int> deletedSakNos; // NoSak yang ada di old tapi tidak ada di new
  final Set<int> addedSakNos; // NoSak yang ada di new tapi tidak ada di old (optional)
  const _DiffResult({
    required this.changedHeaderKeys,
    required this.changedSakNos,
    required this.deletedSakNos,
    required this.addedSakNos,
  });
}

String _norm(dynamic v) {
  if (v == null) return '';
  if (v is String) return v.trim();
  return v.toString().trim();
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  // handle "25,5" -> 25.5
  return double.tryParse(s.replaceAll(',', '.'));
}

List<dynamic> _parseJsonArraySafe(String? jsonStr) {
  if (jsonStr == null || jsonStr.trim().isEmpty || jsonStr == '-') return [];
  try {
    final decoded = jsonDecode(jsonStr);
    if (decoded is List) return decoded;
    if (decoded is Map) return [decoded];
    return [];
  } catch (_) {
    return [];
  }
}

Map<int, Map<String, dynamic>> _sakByNo(List<dynamic> arr) {
  final out = <int, Map<String, dynamic>>{};
  for (final e in arr) {
    if (e is Map) {
      final m = e.cast<String, dynamic>();
      final no = m['NoSak'];
      final noInt = (no is num) ? no.toInt() : int.tryParse('$no');
      if (noInt != null) out[noInt] = m;
    }
  }
  return out;
}

/// Hitung diff antara OLD vs NEW (header + detail sak)
_DiffResult _computeDiff(WashingHistorySession s) {
  // header values OLD vs NEW (yang ditampilkan di UI)
  final headerPairs = <String, List<dynamic>>{
    'Jenis Plastik': [s.oldNamaJenisPlastik, s.newNamaJenisPlastik],
    'Warehouse': [s.oldNamaWarehouse, s.newNamaWarehouse],
    'Blok': [s.oldBlok, s.newBlok],
    'ID Lokasi': [s.oldIdLokasi, s.newIdLokasi],
    'No. Produksi': [s.oldNoProduksi, s.newNoProduksi],
    'Mesin': [s.oldNamaMesin, s.newNamaMesin],
    'No. Bongkar Susun': [s.oldNoBongkarSusun, s.newNoBongkarSusun],
  };

  final changedHeaderKeys = <String>{};
  headerPairs.forEach((k, pair) {
    if (_norm(pair[0]) != _norm(pair[1])) changedHeaderKeys.add(k);
  });

  // details OLD vs NEW (sak)
  final oldDetails = _parseJsonArraySafe(s.detailsOldJson);
  final newDetails = _parseJsonArraySafe(s.detailsNewJson);

  final oldMap = _sakByNo(oldDetails);
  final newMap = _sakByNo(newDetails);

  final oldNos = oldMap.keys.toSet();
  final newNos = newMap.keys.toSet();

  final deleted = oldNos.difference(newNos);
  final added = newNos.difference(oldNos);

  final changedSakNos = <int>{};
  for (final no in oldNos.intersection(newNos)) {
    final o = oldMap[no]!;
    final n = newMap[no]!;
    // compare Berat (tambah field lain kalau perlu)
    final ob = _toDouble(o['Berat']);
    final nb = _toDouble(n['Berat']);
    if (ob != nb) changedSakNos.add(no);
  }

  return _DiffResult(
    changedHeaderKeys: changedHeaderKeys,
    changedSakNos: changedSakNos,
    deletedSakNos: deleted,
    addedSakNos: added,
  );
}

// Unified Data Card - pakai OLD/NEW fields dari session + marker diff
class _DataCard extends StatelessWidget {
  final String title;
  final MaterialColor color;
  final IconData icon;
  final WashingHistorySession session;
  final _Side side;

  final _DiffResult? diff;
  final String sessionAction; // CREATE/UPDATE/DELETE

  const _DataCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.session,
    required this.side,
    required this.sessionAction,
    this.diff,
  });

  bool get isOld => side == _Side.old;

  List<dynamic> _parseJsonArray(String? jsonStr) => _parseJsonArraySafe(jsonStr);

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Ya' : 'Tidak';
    return value.toString();
  }

  Widget _markerIcon({
    required bool show,
    required IconData icon,
    required Color color,
    String? tooltip,
  }) {
    if (!show) return const SizedBox(width: 18);
    return Tooltip(
      message: tooltip ?? '',
      child: Icon(icon, size: 16, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = sessionAction.toUpperCase() == 'UPDATE';
    final showMarkers = isUpdate && diff != null;

    // pick json arrays based on side
    final details = _parseJsonArray(isOld ? session.detailsOldJson : session.detailsNewJson);
    final bso = _parseJsonArray(isOld ? session.bsoOldJson : session.bsoNewJson);
    final wpo = _parseJsonArray(isOld ? session.wpoOldJson : session.wpoNewJson);

    // pick enrich fields based on side
    final namaJenis = isOld ? session.oldNamaJenisPlastik : session.newNamaJenisPlastik;
    final namaWh = isOld ? session.oldNamaWarehouse : session.newNamaWarehouse;

    final blok = isOld ? session.oldBlok : session.newBlok;
    final idLokasi = isOld ? session.oldIdLokasi : session.newIdLokasi;

    final noProduksi = isOld ? session.oldNoProduksi : session.newNoProduksi;
    final namaMesin = isOld ? session.oldNamaMesin : session.newNamaMesin;

    final noBso = isOld ? session.oldNoBongkarSusun : session.newNoBongkarSusun;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(icon, size: 18, color: color.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Header Info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, size: 14, color: color.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Informasi Washing',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: color.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _InfoRow(label: 'No. Washing', value: session.noWashing),

                if (namaJenis != null)
                  _InfoRow(
                    label: 'Jenis Plastik',
                    value: _formatValue(namaJenis),
                    trailing: _markerIcon(
                      show: showMarkers && isOld && diff!.changedHeaderKeys.contains('Jenis Plastik'),
                      icon: Icons.edit_outlined,
                      color: Colors.orange.shade700,
                      tooltip: 'Berubah',
                    ),
                  ),

                // if (namaWh != null)
                //   _InfoRow(
                //     label: 'Warehouse',
                //     value: _formatValue(namaWh),
                //     trailing: _markerIcon(
                //       show: showMarkers && isOld && diff!.changedHeaderKeys.contains('Warehouse'),
                //       icon: Icons.edit_outlined,
                //       color: Colors.orange.shade700,
                //       tooltip: 'Berubah',
                //     ),
                //   ),

                if (blok != null)
                  _InfoRow(
                    label: 'Blok',
                    value: _formatValue(blok),
                    trailing: _markerIcon(
                      show: showMarkers && isOld && diff!.changedHeaderKeys.contains('Blok'),
                      icon: Icons.edit_outlined,
                      color: Colors.orange.shade700,
                      tooltip: 'Berubah',
                    ),
                  ),

                if (idLokasi != null)
                  _InfoRow(
                    label: 'ID Lokasi',
                    value: _formatValue(idLokasi),
                    trailing: _markerIcon(
                      show: showMarkers && isOld && diff!.changedHeaderKeys.contains('ID Lokasi'),
                      icon: Icons.edit_outlined,
                      color: Colors.orange.shade700,
                      tooltip: 'Berubah',
                    ),
                  ),

                if (noProduksi != null)
                  _InfoRow(
                    label: 'No. Produksi',
                    value: _formatValue(noProduksi),
                    trailing: _markerIcon(
                      show: showMarkers && isOld && diff!.changedHeaderKeys.contains('No. Produksi'),
                      icon: Icons.edit_outlined,
                      color: Colors.orange.shade700,
                      tooltip: 'Berubah',
                    ),
                  ),

                if (namaMesin != null)
                  _InfoRow(
                    label: 'Mesin',
                    value: _formatValue(namaMesin),
                    trailing: _markerIcon(
                      show: showMarkers && isOld && diff!.changedHeaderKeys.contains('Mesin'),
                      icon: Icons.edit_outlined,
                      color: Colors.orange.shade700,
                      tooltip: 'Berubah',
                    ),
                  ),

                if (noBso != null)
                  _InfoRow(
                    label: 'No. Bongkar Susun',
                    value: _formatValue(noBso),
                    trailing: _markerIcon(
                      show: showMarkers && isOld && diff!.changedHeaderKeys.contains('No. Bongkar Susun'),
                      icon: Icons.edit_outlined,
                      color: Colors.orange.shade700,
                      tooltip: 'Berubah',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Details (Sak)
          if (details.isNotEmpty) ...[
            _SectionCard(
              color: color,
              icon: Icons.inventory_2,
              title: 'Data Sak (${details.length})',
              child: Column(
                children: details.asMap().entries.map((entry) {
                  final v = entry.value;
                  final sak = (v is Map) ? (v as Map).cast<String, dynamic>() : <String, dynamic>{};

                  final rawNoSak = sak['NoSak'] ?? (entry.key + 1);
                  final noSakInt =
                  (rawNoSak is num) ? rawNoSak.toInt() : int.tryParse('$rawNoSak') ?? (entry.key + 1);

                  final berat = sak['Berat'];

                  final isDeletedInNew = showMarkers && isOld && diff!.deletedSakNos.contains(noSakInt);
                  final isChanged = showMarkers && isOld && diff!.changedSakNos.contains(noSakInt);

                  // Optional marker on NEW side
                  final isAdded = showMarkers && !isOld && diff!.addedSakNos.contains(noSakInt);
                  final isChangedNewSide = showMarkers && !isOld && diff!.changedSakNos.contains(noSakInt);

                  IconData? marker;
                  Color? markerColor;
                  String? tip;

                  if (isDeletedInNew) {
                    marker = Icons.close; // silang
                    markerColor = Colors.red.shade700;
                    tip = 'Dihapus';
                  } else if (isChanged) {
                    marker = Icons.edit_outlined;
                    markerColor = Colors.orange.shade700;
                    tip = 'Berubah';
                  } else if (isAdded) {
                    marker = Icons.add_circle_outline;
                    markerColor = Colors.green.shade700;
                    tip = 'Baru';
                  } else if (isChangedNewSide) {
                    marker = Icons.edit_outlined;
                    markerColor = Colors.orange.shade700;
                    tip = 'Berubah';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '$noSakInt',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${berat ?? '-'} kg',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: isDeletedInNew ? TextDecoration.lineThrough : null,
                              color: isDeletedInNew ? Colors.red.shade700 : null,
                            ),
                          ),
                        ),
                        if (marker != null)
                          Tooltip(
                            message: tip ?? '',
                            child: Icon(marker, size: 16, color: markerColor),
                          )
                        else
                          const SizedBox(width: 16),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // (bso / wpo) kalau nanti ingin tampil, bisa tambah section serupa dengan konsep marker
          if (details.isEmpty && bso.isEmpty && wpo.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Tidak ada data detail',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final MaterialColor color;
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: color.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// Helper widget untuk menampilkan info row (dengan trailing icon marker)
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: valueColor ?? Colors.grey.shade900,
                fontWeight: valueColor != null ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}
