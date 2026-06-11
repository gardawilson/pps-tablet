// lib/features/production/inject/widgets/inject_formula_dialog.dart

import 'package:flutter/material.dart';

import '../model/inject_formula_model.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _formatOutputCategory(String? kode) {
  switch (kode?.toLowerCase()) {
    case 'barangjadi':
      return 'Barang Jadi';
    case 'furniturewip':
      return 'Furniture WIP';
    default:
      return 'Output';
  }
}

// ── Palette ──────────────────────────────────────────────────────────────────

const _kSurface   = Color(0xFFF8F9FB);
const _kBorder    = Color(0xFFE5E7EB);
const _kOutput    = Color(0xFF00695C);
const _kPrimary   = Color(0xFF0277BD);
const _kText1     = Color(0xFF111827);
const _kText2     = Color(0xFF6B7280);
const _kText3     = Color(0xFF9CA3AF);

// Warna dan ikon per kategori
_KategoriMeta _meta(String kode) {
  switch (kode.toLowerCase()) {
    case 'furniturewip':
      return _KategoriMeta(
        color: const Color(0xFF0277BD),
        icon: Icons.inventory_2_outlined,
      );
    case 'mixer':
      return _KategoriMeta(
        color: const Color(0xFF6D28D9),
        icon: Icons.blender_outlined,
      );
    case 'broker':
      return _KategoriMeta(
        color: const Color(0xFFD97706),
        icon: Icons.local_shipping_outlined,
      );
    case 'gilingan':
      return _KategoriMeta(
        color: const Color(0xFF059669),
        icon: Icons.settings_outlined,
      );
    default:
      return _KategoriMeta(
        color: const Color(0xFF64748B),
        icon: Icons.category_outlined,
      );
  }
}

class _KategoriMeta {
  final Color color;
  final IconData icon;
  const _KategoriMeta({required this.color, required this.icon});
}

// ── Dialog ───────────────────────────────────────────────────────────────────

class InjectFormulaDialog extends StatelessWidget {
  const InjectFormulaDialog({super.key, required this.data});

  final InjectFormulaData data;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 660),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DialogHeader(noProduksi: data.noProduksi),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: data.outputs.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                      itemCount: data.outputs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _FormulaCard(
                            output: data.outputs[i],
                            index: i + 1,
                            outputCategory: data.outputCategory,
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.noProduksi});
  final String noProduksi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kPrimary.withValues(alpha: 0.15),
                  _kPrimary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: _kPrimary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.science_outlined,
                color: _kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formula Produksi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kText1,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 11, color: _kText3),
                    const SizedBox(width: 4),
                    Text(
                      noProduksi,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _kText3,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: _kText3),
            visualDensity: VisualDensity.compact,
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }
}

// ── Formula Card (satu output + semua input-nya) ──────────────────────────────

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({
    required this.output,
    required this.index,
    this.outputCategory,
  });
  final InjectFormulaOutput output;
  final int index;
  final String? outputCategory;

  Map<String, List<InjectFormulaInput>> _grouped() {
    final map = <String, List<InjectFormulaInput>>{};
    for (final f in output.formulas) {
      (map[f.inputKategoriKode] ??= []).add(f);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Kiri: Input ──────────────────────────────────────
            Expanded(
              flex: 56,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section label
                    Row(
                      children: [
                        Icon(Icons.input_rounded,
                            size: 11,
                            color: _kPrimary.withValues(alpha: 0.7)),
                        const SizedBox(width: 5),
                        Text(
                          'DIBUTUHKAN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _kPrimary.withValues(alpha: 0.7),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Kategori + items
                    if (output.formulas.isEmpty)
                      const _NoFormula()
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: grouped.entries.map((entry) {
                          final meta = _meta(entry.key);
                          final items = entry.value;
                          final isLast =
                              entry.key == grouped.keys.last;
                          return _KategoriSection(
                            meta: meta,
                            namaKategori:
                                items.first.inputKategoriNama,
                            items: items,
                            isLast: isLast,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            // ── Tengah: Arrow ────────────────────────────────────
            _FlowArrow(),

            // ── Kanan: Output ─────────────────────────────────────
            Expanded(
              flex: 44,
              child: _OutputSection(
                namaJenis: output.namaJenis,
                index: index,
                outputCategory: outputCategory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kategori section ──────────────────────────────────────────────────────────

class _KategoriSection extends StatelessWidget {
  const _KategoriSection({
    required this.meta,
    required this.namaKategori,
    required this.items,
    required this.isLast,
  });

  final _KategoriMeta meta;
  final String namaKategori;
  final List<InjectFormulaInput> items;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = meta.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pill badge kategori
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: color.withValues(alpha: 0.22), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(meta.icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                namaKategori,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Item list dengan left border
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items.asMap().entries.map((e) {
              final f = e.value;
              return _ItemRow(
                formula: f,
                accentColor: color,
                number: e.key + 1,
              );
            }).toList(),
          ),
        ),
        if (!isLast) const SizedBox(height: 10),
      ],
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.formula,
    required this.accentColor,
    required this.number,
  });

  final InjectFormulaInput formula;
  final Color accentColor;
  final int number;

  @override
  Widget build(BuildContext context) {
    final hasName = formula.inputNama != null;
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: accentColor.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nomor urut
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              hasName
                  ? formula.inputNama!
                  : 'ID ${formula.inputId}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontStyle:
                    hasName ? FontStyle.normal : FontStyle.italic,
                color: hasName ? _kText1 : _kText3,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arrow connector ───────────────────────────────────────────────────────────

class _FlowArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical divider line
          Positioned.fill(
            child: Center(
              child: Container(
                width: 1,
                color: _kBorder,
              ),
            ),
          ),
          // Arrow circle
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.east_rounded,
              size: 13,
              color: _kText2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Output section ────────────────────────────────────────────────────────────

class _OutputSection extends StatelessWidget {
  const _OutputSection({
    required this.namaJenis,
    required this.index,
    this.outputCategory,
  });

  final String namaJenis;
  final int index;
  final String? outputCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kOutput.withValues(alpha: 0.04),
            _kOutput.withValues(alpha: 0.09),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(
          left: BorderSide(
              color: _kOutput.withValues(alpha: 0.18), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label
          Row(
            children: [
              Icon(Icons.output_rounded,
                  size: 11,
                  color: _kOutput.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              Text(
                'MENGHASILKAN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _kOutput.withValues(alpha: 0.8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Nama output
          Text(
            namaJenis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kText1,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          // Index badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _kOutput.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _kOutput.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kOutput.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _kOutput,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _formatOutputCategory(outputCategory),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kOutput.withValues(alpha: 0.85),
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

// ── Empty / no formula states ─────────────────────────────────────────────────

class _NoFormula extends StatelessWidget {
  const _NoFormula();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, size: 13, color: _kText3),
          const SizedBox(width: 6),
          Text(
            'Belum ada formula input terdaftar',
            style: TextStyle(fontSize: 11, color: _kText3),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 36, color: _kText3),
            SizedBox(height: 12),
            Text(
              'Tidak ada formula\nuntuk produksi ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: _kText3,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
