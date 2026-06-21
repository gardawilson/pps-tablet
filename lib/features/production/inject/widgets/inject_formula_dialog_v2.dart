// lib/features/production/inject/widgets/inject_formula_dialog_v2.dart

import 'package:flutter/material.dart';

import '../model/inject_formula_model.dart';

// ── Palette ───────────────────────────────────────────────────────────────────

const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE5E7EB);
const _kPrimary = Color(0xFF0277BD);
const _kText1 = Color(0xFF111827);
const _kText2 = Color(0xFF374151);
const _kText3 = Color(0xFF9CA3AF);

// ── Kategori meta ─────────────────────────────────────────────────────────────

class _KatMeta {
  final Color color;
  final IconData icon;
  const _KatMeta({required this.color, required this.icon});
}

_KatMeta _katMeta(String kode) {
  switch (kode.toLowerCase()) {
    case 'furniturewip':
      return const _KatMeta(
        color: Color(0xFF0277BD),
        icon: Icons.inventory_2_outlined,
      );
    case 'mixer':
      return const _KatMeta(
        color: Color(0xFF6D28D9),
        icon: Icons.blender_outlined,
      );
    case 'broker':
      return const _KatMeta(
        color: Color(0xFFD97706),
        icon: Icons.local_shipping_outlined,
      );
    case 'gilingan':
      return const _KatMeta(
        color: Color(0xFF059669),
        icon: Icons.settings_outlined,
      );
    default:
      return const _KatMeta(
        color: Color(0xFF64748B),
        icon: Icons.category_outlined,
      );
  }
}

// ── Dialog V2 ─────────────────────────────────────────────────────────────────

class InjectFormulaDialogV2 extends StatefulWidget {
  const InjectFormulaDialogV2({super.key, required this.data});

  final InjectFormulaData data;

  @override
  State<InjectFormulaDialogV2> createState() => _InjectFormulaDialogV2State();
}

class _InjectFormulaDialogV2State extends State<InjectFormulaDialogV2> {
  @override
  Widget build(BuildContext context) {
    final outputs = widget.data.outputs;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: outputs.isEmpty
                  ? const _EmptyState()
                  : _FormulaBody(outputs: outputs),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: _kPrimary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Formula Produksi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kText1,
                height: 1.2,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18, color: _kText3),
            visualDensity: VisualDensity.compact,
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }
}

// ── Formula Body ──────────────────────────────────────────────────────────────

class _FormulaBody extends StatelessWidget {
  const _FormulaBody({required this.outputs});

  final List<InjectFormulaOutput> outputs;

  Map<String, List<InjectFormulaInput>> _groupedFormulas(
    List<InjectFormulaInput> formulas,
  ) {
    final map = <String, List<InjectFormulaInput>>{};
    for (final f in formulas) {
      (map[f.inputKategoriKode] ??= []).add(f);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final hasAny = outputs.any((o) => o.formulas.isNotEmpty);
    if (!hasAny) return const _NoFormula();

    final items = <Widget>[];
    for (var oi = 0; oi < outputs.length; oi++) {
      final output = outputs[oi];
      final grouped = _groupedFormulas(output.formulas);
      final katEntries = grouped.entries.toList();

      // Output label
      items.add(
        Padding(
          padding: EdgeInsets.only(top: oi == 0 ? 0 : 16, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  output.namaJenis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00695C),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (output.formulas.isEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Belum ada formula untuk output ini.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        );
        continue;
      }

      for (var ki = 0; ki < katEntries.length; ki++) {
        final katKode = katEntries[ki].key;
        final katItems = katEntries[ki].value;
        final meta = _katMeta(katKode);
        final isLastKat = ki == katEntries.length - 1;
        items.add(
          _KategoriBlock(
            meta: meta,
            namaKategori: katItems.first.inputKategoriNama,
            items: katItems,
          ),
        );
        if (!isLastKat) items.add(const SizedBox(height: 8));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: items,
    );
  }
}

// ── Kategori block ────────────────────────────────────────────────────────────

class _KategoriBlock extends StatelessWidget {
  const _KategoriBlock({
    required this.meta,
    required this.namaKategori,
    required this.items,
  });

  final _KatMeta meta;
  final String namaKategori;
  final List<InjectFormulaInput> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Kategori header ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.06),
              border: Border(
                bottom: BorderSide(color: meta.color.withValues(alpha: 0.15)),
              ),
            ),
            child: Text(
              namaKategori,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: meta.color,
              ),
            ),
          ),

          // ── Item list ────────────────────────────────────────────
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return _ItemRow(
              formula: e.value,
              number: e.key + 1,
              accentColor: meta.color,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.formula,
    required this.number,
    required this.accentColor,
    required this.isLast,
  });

  final InjectFormulaInput formula;
  final int number;
  final Color accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final hasName = formula.inputNama != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nomor
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(5),
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
          const SizedBox(width: 10),
          // Nama
          Expanded(
            child: Text(
              hasName ? formula.inputNama! : 'ID ${formula.inputId}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontStyle: hasName ? FontStyle.normal : FontStyle.italic,
                color: hasName ? _kText2 : _kText3,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _NoFormula extends StatelessWidget {
  const _NoFormula();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_remove_rounded, size: 28, color: _kText3),
            const SizedBox(height: 8),
            const Text(
              'Belum ada formula input\nuntuk jenis output ini',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _kText3, height: 1.5),
            ),
          ],
        ),
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
              style: TextStyle(fontSize: 13, color: _kText3, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
