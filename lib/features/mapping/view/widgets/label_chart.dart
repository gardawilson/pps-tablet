import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:pps_tablet/features/mapping/model/mapping_label_model.dart';

// ── Palette ──────────────────────────────────────────────────────────────────

const Color _primary = Color(0xFF1565C0);

const List<Color> chartColors = [
  Color(0xFF1565C0),
  Color(0xFF00897B),
  Color(0xFFE65100),
  Color(0xFF6A1B9A),
  Color(0xFF2E7D32),
  Color(0xFFC62828),
  Color(0xFF00838F),
  Color(0xFFF9A825),
  Color(0xFF4527A0),
  Color(0xFF558B2F),
];

// ── Entry point ───────────────────────────────────────────────────────────────

class LabelChart extends StatelessWidget {
  final MappingLabelResult result;

  const LabelChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final data = result.data;

    // ── Compute aggregates ────────────────────────────────────────────────
    final Map<String, List<MappingLabelItem>> byKategori = {};
    for (final item in data) {
      byKategori.putIfAbsent(item.kategori, () => []).add(item);
    }

    final totalJenis = <String>{for (final item in data) item.namaJenis}.length;

    final kategoriList = byKategori.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KPI cards
          _KpiRow(
            totalLabels: data.length,
            totalKategori: kategoriList.length,
            totalJenis: totalJenis,
          ),
          const SizedBox(height: 20),

          // 2. Donut summary
          _ChartSection(
            byKategori: byKategori,
            totalLabels: data.length,
            kategoriList: kategoriList,
          ),
          const SizedBox(height: 20),

          // 3. Per-kategori ranking cards
          const _SectionTitle('Detail per Kategori'),
          const SizedBox(height: 10),
          ...byKategori.entries.toList().asMap().entries.map((e) {
            final colorIdx = e.key;
            final kat = e.value.key;
            final items = e.value.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryCard(
                kategori: kat,
                items: items,
                accentColor: chartColors[colorIdx % chartColors.length],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── KPI Row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final int totalLabels;
  final int totalKategori;
  final int totalJenis;

  const _KpiRow({
    required this.totalLabels,
    required this.totalKategori,
    required this.totalJenis,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.inventory_2_rounded,
            label: 'Total Label',
            value: '$totalLabels',
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.category_rounded,
            label: 'Kategori',
            value: '$totalKategori',
            color: const Color(0xFF00897B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.layers_rounded,
            label: 'Jenis',
            value: '$totalJenis',
            color: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chart Section (Donut) ─────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final Map<String, List<MappingLabelItem>> byKategori;
  final int totalLabels;
  final List<String> kategoriList;

  const _ChartSection({
    required this.byKategori,
    required this.totalLabels,
    required this.kategoriList,
  });

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Distribusi Kategori'),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Donut
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        swapAnimationDuration: const Duration(
                          milliseconds: 900,
                        ),
                        swapAnimationCurve: Curves.easeInOutCubic,
                        PieChartData(
                          sections: [
                            for (int i = 0; i < kategoriList.length; i++)
                              PieChartSectionData(
                                value: byKategori[kategoriList[i]]!.length
                                    .toDouble(),
                                color: chartColors[i % chartColors.length],
                                title: '',
                                radius: 52,
                              ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 44,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalLabels',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                              height: 1,
                            ),
                          ),
                          Text(
                            'label',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < kategoriList.length; i++) ...[
                        _LegendItem(
                          color: chartColors[i % chartColors.length],
                          label: kategoriList[i],
                          count: byKategori[kategoriList[i]]!.length,
                          total: totalLabels,
                        ),
                        if (i < kategoriList.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legend Item ───────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${(count / total * 100).toStringAsFixed(0)}%)',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String kategori;
  final List<MappingLabelItem> items;
  final Color accentColor;

  const _CategoryCard({
    required this.kategori,
    required this.items,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final useBerat = items.first.uom.toUpperCase() != 'PCS';
    final uom = useBerat ? 'kg' : 'pcs';

    // Group by NamaJenis
    final Map<String, double> byJenis = {};
    for (final item in items) {
      final val = useBerat ? (item.berat ?? 0) : item.qty.toDouble();
      byJenis[item.namaJenis] = (byJenis[item.namaJenis] ?? 0) + val;
    }
    final sorted = byJenis.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (s, e) => s + e.value);
    final totalStr = useBerat
        ? '${total.toStringAsFixed(1)} $uom'
        : '${total.toInt()} $uom';
    final uniqueJenis = sorted.length;

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  kategori,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              // Stats chips
              _InfoChip(label: totalStr, color: accentColor),
              const SizedBox(width: 8),
              _InfoChip(
                label: '$uniqueJenis jenis',
                color: Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Progress items
          ...sorted.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProgressItem(
                label: e.value.key,
                value: e.value.value,
                total: total,
                uom: uom,
                useBerat: useBerat,
                color: accentColor,
                rank: e.key + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Item ─────────────────────────────────────────────────────────────

class _ProgressItem extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final String uom;
  final bool useBerat;
  final Color color;
  final int rank;

  const _ProgressItem({
    required this.label,
    required this.value,
    required this.total,
    required this.uom,
    required this.useBerat,
    required this.color,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    final pctStr = '${(pct * 100).toStringAsFixed(1)}%';
    final valStr = useBerat
        ? '${value.toStringAsFixed(1)} $uom'
        : '${value.toInt()} $uom';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Rank badge
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? color.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3 ? color : Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valStr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 42,
              child: Text(
                pctStr,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.75)),
          ),
        ),
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  final Widget child;

  const _DashCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: _primary,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

