import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/label_print_lock_api.dart';
import '../../../core/services/label_print_sync_queue.dart';
import '../../../core/utils/pdf_print_service.dart';
import '../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../label/bahan_baku/repository/bahan_baku_repository.dart';
import '../../label/bahan_baku/view_model/bahan_baku_view_model.dart';
import '../../label/bonggolan/repository/bonggolan_repository.dart';
import '../../label/broker/repository/broker_repository.dart';
import '../../label/crusher/repository/crusher_repository.dart';
import '../../label/furniture_wip/repository/furniture_wip_repository.dart';
import '../../label/gilingan/repository/gilingan_repository.dart';
import '../../label/mixer/repository/mixer_repository.dart';
import '../../label/packing/repository/packing_repository.dart';
import '../../label/washing/repository/washing_repository.dart';
import '../model/bs_v2_label_info.dart';
import '../model/bs_v2_transaction.dart';
import '../repository/bs_v2_repository.dart';
import '../utils/bs_v2_category_label.dart';
import '../../production/shared/shared.dart';
import 'bs_v2_sak_detail_dialog.dart';

// ─── Theme constants (mirroring create screen) ─────────────────────────────
const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);
const _kGreen = Color(0xFF0A7349);
const _kRadius = 12.0;

BoxDecoration _cardDecoration({Color? borderColor}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(_kRadius),
  border: Border.all(color: borderColor ?? _kBorder),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

// ─── Screen ────────────────────────────────────────────────────────────────

class BsV2DetailScreen extends StatefulWidget {
  final String noBongkarSusun;

  const BsV2DetailScreen({super.key, required this.noBongkarSusun});

  @override
  State<BsV2DetailScreen> createState() => _BsV2DetailScreenState();
}

class _BsV2DetailScreenState extends State<BsV2DetailScreen> {
  final BsV2Repository _repo = BsV2Repository();
  final NumberFormat _nf = NumberFormat('#,##0.###', 'id_ID');
  BsV2Transaction? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.fetchDetail(widget.noBongkarSusun);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category =
        _data?.category ??
        (_data?.inputs.isNotEmpty == true
            ? _data!.inputs.first.category
            : null);

    return Scaffold(backgroundColor: _kSurface, body: _buildBody());
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Gagal memuat: $_error',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_data == null) {
      return const Center(child: Text('Data tidak ditemukan'));
    }

    final trx = _data!;
    final category =
        trx.category ??
        (trx.inputs.isNotEmpty ? trx.inputs.first.category : null);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(trx: trx, category: category),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InputsCard(inputs: trx.inputs, nf: _nf),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OutputsCard(outputs: trx.outputs, nf: _nf),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Header Card ───────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final BsV2Transaction trx;
  final String? category;

  const _HeaderCard({required this.trx, required this.category});

  @override
  Widget build(BuildContext context) {
    final balanced = trx.balance;
    final inputCount = trx.inputLabelCount ?? trx.inputs.length;
    final outputCount = trx.outputLabelCount ?? trx.outputs.length;

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_kRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trx.noBongkarSusun,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        trx.tanggalText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                bsV2CategoryBadge(category),
              ],
            ),
          ),
          // ── Stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF0F7FF),
            child: Row(
              children: [
                // Operator
                Expanded(
                  child: _StatItem(
                    icon: Icons.person_rounded,
                    label: 'Dibuat oleh',
                    value: trx.username ?? '-',
                    iconColor: _kPrimary,
                  ),
                ),
                _VertDivider(),
                // Input → Output
                Expanded(
                  child: _FlowItem(
                    inputCount: inputCount,
                    outputCount: outputCount,
                  ),
                ),
                _VertDivider(),
                // Catatan
                Expanded(
                  child: _StatItem(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Catatan',
                    value: (trx.note != null && trx.note!.isNotEmpty)
                        ? trx.note!
                        : '—',
                    iconColor: const Color(0xFF8A94A6),
                    italic: (trx.note != null && trx.note!.isNotEmpty),
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

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFFD0E4FF),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool italic;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8A94A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D23),
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowItem extends StatelessWidget {
  final int inputCount;
  final int outputCount;

  const _FlowItem({required this.inputCount, required this.outputCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Input → Output',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF8A94A6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _Pill(count: inputCount, color: _kPrimary, label: 'Input'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: Colors.grey.shade400,
              ),
            ),
            _Pill(count: outputCount, color: _kGreen, label: 'Output'),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final int count;
  final Color color;
  final String label;

  const _Pill({required this.count, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final bool? balanced;

  const _BalanceItem({required this.balanced});

  @override
  Widget build(BuildContext context) {
    if (balanced == null) return const SizedBox.shrink();
    final ok = balanced!;
    final color = ok ? _kGreen : Colors.red.shade600;
    final bgColor = ok ? const Color(0xFFE8F5EE) : Colors.red.shade50;
    final icon = ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
    final text = ok ? 'Seimbang' : 'Tidak Seimbang';

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF8A94A6),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Inputs Card ───────────────────────────────────────────────────────────

class _InputsCard extends StatelessWidget {
  final List<BsV2LabelInfo> inputs;
  final NumberFormat nf;

  const _InputsCard({required this.inputs, required this.nf});

  @override
  Widget build(BuildContext context) {
    final totalPcs = inputs
        .where((e) => e.isPcsCategory)
        .fold(0.0, (s, e) => s + e.totalBerat);
    final totalBeratKg = inputs
        .where((e) => !e.isPcsCategory)
        .fold(0.0, (s, e) => s + e.totalBerat);

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.input_rounded,
                    size: 16,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Label Input',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                const Spacer(),
                if (inputs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${inputs.length} label',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          if (inputs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Tidak ada input',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: LayoutBuilder(
                builder: (_, c) => GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    mainAxisExtent: 80,
                  ),
                  children: inputs
                      .map((lbl) => _BsV2InputTile(lbl: lbl, nf: nf))
                      .toList(),
                ),
              ),
            ),
            // Total row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(_kRadius),
                ),
                border: const Border(top: BorderSide(color: _kBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (totalBeratKg > 0)
                    Row(
                      children: [
                        const Text(
                          'Total Berat Input',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${nf.format(totalBeratKg)} kg',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  if (totalBeratKg > 0 && totalPcs > 0)
                    const SizedBox(height: 4),
                  if (totalPcs > 0)
                    Row(
                      children: [
                        const Text(
                          'Total Pcs Input',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${totalPcs.toInt()} pcs',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Card tile untuk satu label input — format identik dengan tile input/output
// pada layar produksi (mis. broker): jenis sebagai judul, nomor label sebagai
// sub judul, metrics (sak/berat/pcs) di baris bawah, tap untuk detail sak.
class _BsV2InputTile extends StatelessWidget {
  final BsV2LabelInfo lbl;
  final NumberFormat nf;

  const _BsV2InputTile({required this.lbl, required this.nf});

  @override
  Widget build(BuildContext context) {
    final hasSakDetail = lbl.saks.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: hasSakDetail
            ? () => showDialog<void>(
                context: context,
                builder: (_) => BsV2SakDetailDialog(lbl: lbl, nf: nf),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                lbl.namaJenis.isNotEmpty ? lbl.namaJenis : lbl.labelCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D23),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                lbl.labelCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  if (lbl.jumlahSak > 0)
                    ProductionMiniMetric(
                      icon: Icons.inventory_2_outlined,
                      text: '${lbl.jumlahSak} sak',
                    ),
                  ProductionMiniMetric(
                    icon: lbl.isPcsCategory
                        ? Icons.category_outlined
                        : Icons.scale_outlined,
                    text: lbl.isPcsCategory
                        ? '${lbl.totalBerat.toInt()} pcs'
                        : '${nf.format(lbl.totalBerat)} kg',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Outputs Card ──────────────────────────────────────────────────────────

class _OutputsCard extends StatelessWidget {
  final List<BsV2OutputLabel> outputs;
  final NumberFormat nf;

  const _OutputsCard({required this.outputs, required this.nf});

  @override
  Widget build(BuildContext context) {
    final totalPcs = outputs
        .where((e) => e.isPcsCategory)
        .fold(0.0, (s, e) => s + e.totalBerat);
    final totalBeratKg = outputs
        .where((e) => !e.isPcsCategory)
        .fold(0.0, (s, e) => s + e.totalBerat);

    return Container(
      decoration: _cardDecoration(borderColor: _kGreen.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.output_rounded,
                    size: 16,
                    color: _kGreen,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Label Output',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                const Spacer(),
                if (outputs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${outputs.length} label',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          if (outputs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Tidak ada output',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: LayoutBuilder(
                builder: (_, c) => GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    mainAxisExtent: 80,
                  ),
                  children: [
                    for (var i = 0; i < outputs.length; i++)
                      _BsV2OutputTile(out: outputs[i], nf: nf, index: i),
                  ],
                ),
              ),
            ),
            // Total row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(_kRadius),
                ),
                border: const Border(top: BorderSide(color: _kBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (totalBeratKg > 0)
                    Row(
                      children: [
                        const Text(
                          'Total Berat Output',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kGreen,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${nf.format(totalBeratKg)} kg',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kGreen,
                          ),
                        ),
                      ],
                    ),
                  if (totalBeratKg > 0 && totalPcs > 0)
                    const SizedBox(height: 4),
                  if (totalPcs > 0)
                    Row(
                      children: [
                        const Text(
                          'Total Pcs Output',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kGreen,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${totalPcs.toInt()} pcs',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kGreen,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Card tile untuk satu label output — format identik dengan tile input/output
// pada layar produksi (mis. broker): jenis sebagai judul, nomor label sebagai
// sub judul, tombol print inline, metrics di baris bawah, tap untuk detail sak.
class _BsV2OutputTile extends StatelessWidget {
  final BsV2OutputLabel out;
  final NumberFormat nf;
  final int index;
  const _BsV2OutputTile({
    required this.out,
    required this.nf,
    required this.index,
  });

  bool get _canPrint {
    final labelCode = (out.labelCode ?? '').trim();
    return labelCode.startsWith('A') ||
        labelCode.startsWith('B') ||
        labelCode.startsWith('D') ||
        labelCode.startsWith('F') ||
        labelCode.startsWith('H') ||
        labelCode.startsWith('M') ||
        labelCode.startsWith('V');
  }

  String _deriveNoBahanBaku(String noPallet) {
    if (noPallet.contains('-')) {
      return noPallet.substring(0, noPallet.lastIndexOf('-'));
    }
    return noPallet;
  }

  Future<void> _handlePrint(BuildContext context, String labelCode) async {
    final rootCtx = Navigator.of(context, rootNavigator: true).context;
    final isBahanBakuLabel = labelCode.startsWith('A');
    final isPackingLabel = labelCode.startsWith('BA');
    final isFurnitureWipLabel = labelCode.startsWith('BB');
    final isBrokerLabel = labelCode.startsWith('D');
    final isCrusherLabel = labelCode.startsWith('F');
    final isMixerLabel = labelCode.startsWith('H');
    final isBonggolanLabel = labelCode.startsWith('M');
    final isGilinganLabel = labelCode.startsWith('V');
    final lockApi = LabelPrintLockApi();
    final noPallet = (out.noPallet?.trim().isNotEmpty ?? false)
        ? out.noPallet!.trim()
        : labelCode;
    final noBahanBaku = (out.noBahanBaku?.trim().isNotEmpty ?? false)
        ? out.noBahanBaku!.trim()
        : _deriveNoBahanBaku(noPallet);
    final bahanBakuRepo = isBahanBakuLabel
        ? BahanBakuRepository(api: ApiClient())
        : null;
    final bahanBakuVm = isBahanBakuLabel
        ? context.read<BahanBakuViewModel>()
        : null;
    final packingRepo = isPackingLabel
        ? PackingRepository(api: ApiClient())
        : null;
    final furnitureWipRepo = isFurnitureWipLabel
        ? FurnitureWipRepository()
        : null;
    final brokerRepo = isBrokerLabel
        ? BrokerRepository(api: ApiClient())
        : null;
    final crusherRepo = isCrusherLabel ? CrusherRepository() : null;
    final mixerRepo = isMixerLabel ? MixerRepository() : null;
    final bonggolanRepo = isBonggolanLabel ? BonggolanRepository() : null;
    final gilinganRepo = isGilinganLabel ? GilinganRepository() : null;
    final washingRepo =
        isBahanBakuLabel ||
            isPackingLabel ||
            isFurnitureWipLabel ||
            isBrokerLabel ||
            isCrusherLabel ||
            isMixerLabel ||
            isBonggolanLabel ||
            isGilinganLabel
        ? null
        : WashingRepository();
    final lockVm = context.read<LabelPrintLockSocketManager>();
    final queue = context.read<LabelPrintSyncQueue>();
    final feature = isBahanBakuLabel
        ? 'bahan_baku'
        : isPackingLabel
        ? 'packing'
        : isFurnitureWipLabel
        ? 'furniture_wip'
        : isBrokerLabel
        ? 'broker'
        : isCrusherLabel
        ? 'crusher'
        : isMixerLabel
        ? 'mixer'
        : isBonggolanLabel
        ? 'bonggolan'
        : isGilinganLabel
        ? 'gilingan'
        : 'washing';
    final pdfUrl = isBahanBakuLabel
        ? ApiConstants.bahanBakuPalletLabelPdf(noBahanBaku, noPallet)
        : isPackingLabel
        ? ApiConstants.packingLabelPdf(labelCode)
        : isFurnitureWipLabel
        ? ApiConstants.furnitureWipLabelPdf(labelCode)
        : isBrokerLabel
        ? ApiConstants.brokerLabelPdf(labelCode)
        : isCrusherLabel
        ? ApiConstants.crusherLabelPdf(labelCode)
        : isMixerLabel
        ? ApiConstants.mixerLabelPdf(labelCode)
        : isBonggolanLabel
        ? ApiConstants.bonggolanLabelPdf(labelCode)
        : isGilinganLabel
        ? ApiConstants.gilinganLabelPdf(labelCode)
        : ApiConstants.washingLabelPdf(labelCode);
    final title = isBahanBakuLabel
        ? '$noBahanBaku-$noPallet'
        : isPackingLabel ||
              isFurnitureWipLabel ||
              isBrokerLabel ||
              isCrusherLabel ||
              isMixerLabel ||
              isBonggolanLabel ||
              isGilinganLabel
        ? labelCode
        : 'Label $labelCode';
    var isLockAcquired = false;
    var isPrinted = false;

    try {
      await lockApi.acquire(isBahanBakuLabel ? noPallet : labelCode);
      isLockAcquired = true;

      await PdfPrintService(defaultSystem: 'pps').previewFromUrl(
        context: rootCtx,
        pdfUrl: Uri.parse(pdfUrl),
        title: title,
        onPrinted: () {
          isPrinted = true;
          () async {
            var needsIncrement = false;
            var needsRelease = false;

            try {
              final count = isBahanBakuLabel
                  ? await bahanBakuRepo!.markAsPrinted(
                      noBahanBaku: noBahanBaku,
                      noPallet: noPallet,
                    )
                  : isPackingLabel
                  ? await packingRepo!.markAsPrinted(labelCode)
                  : isFurnitureWipLabel
                  ? await furnitureWipRepo!.markAsPrinted(labelCode)
                  : isBrokerLabel
                  ? await brokerRepo!.markAsPrinted(labelCode)
                  : isCrusherLabel
                  ? await crusherRepo!.markAsPrinted(labelCode)
                  : isMixerLabel
                  ? await mixerRepo!.markAsPrinted(labelCode)
                  : isBonggolanLabel
                  ? await bonggolanRepo!.markAsPrinted(labelCode)
                  : isGilinganLabel
                  ? await gilinganRepo!.markAsPrinted(labelCode)
                  : await washingRepo!.markAsPrinted(labelCode);
              if (count != null) {
                lockVm.setPrintCount(
                  isBahanBakuLabel ? noPallet : labelCode,
                  count,
                );
                if (isBahanBakuLabel) {
                  bahanBakuVm!.setPalletPrintedCount(
                    noPallet: noPallet,
                    count: count,
                  );
                }
              }
            } catch (_) {
              needsIncrement = true;
            }

            try {
              await lockApi.release(isBahanBakuLabel ? noPallet : labelCode);
            } catch (_) {
              needsRelease = true;
            }

            if (needsIncrement || needsRelease) {
              await queue.enqueue(
                feature: feature,
                noLabel: isBahanBakuLabel ? noPallet : labelCode,
                extra: isBahanBakuLabel
                    ? {'noBahanBaku': noBahanBaku, 'noPallet': noPallet}
                    : null,
                needsIncrement: needsIncrement,
                needsReleaseLock: needsRelease,
              );
            }
          }().ignore();
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (isLockAcquired && !isPrinted) {
        () async {
          try {
            await lockApi.release(isBahanBakuLabel ? noPallet : labelCode);
          } catch (_) {
            await queue.enqueue(
              feature: feature,
              noLabel: isBahanBakuLabel ? noPallet : labelCode,
              extra: isBahanBakuLabel
                  ? {'noBahanBaku': noBahanBaku, 'noPallet': noPallet}
                  : null,
              needsReleaseLock: true,
            );
          }
        }().ignore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelCode = out.labelCode?.trim();
    final title = out.namaJenis.isNotEmpty
        ? out.namaJenis
        : (labelCode ?? '#${index + 1}');
    final subtitle = labelCode ?? '#${index + 1}';
    final hasSakDetail = out.saks.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: hasSakDetail
            ? () => showDialog<void>(
                context: context,
                builder: (_) => BsV2SakDetailDialog(
                  nf: nf,
                  lbl: BsV2LabelInfo(
                    labelCode: out.labelCode ?? '#${index + 1}',
                    category: out.category,
                    idJenis: out.idJenis,
                    namaJenis: out.namaJenis,
                    totalBerat: out.totalBerat,
                    jumlahSak: out.jumlahSak,
                    saks: out.saks
                        .map(
                          (s) => BsV2LabelSak(noSak: s.noSak, berat: s.berat),
                        )
                        .toList(),
                  ),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D23),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (labelCode != null && _canPrint) ...[
                    const SizedBox(width: 4),
                    _OutputPrintButton(
                      onPressed: () => _handlePrint(context, labelCode),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  if (out.jumlahSak > 0)
                    ProductionMiniMetric(
                      icon: Icons.inventory_2_outlined,
                      text: '${out.jumlahSak} sak',
                    ),
                  ProductionMiniMetric(
                    icon: out.isPcsCategory
                        ? Icons.category_outlined
                        : Icons.scale_outlined,
                    text: out.isPcsCategory
                        ? '${out.totalBerat.toInt()} pcs'
                        : '${nf.format(out.totalBerat)} kg',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutputPrintButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _OutputPrintButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Print',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 26,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kGreen.withValues(alpha: 0.18)),
          ),
          child: const Icon(Icons.print_outlined, size: 14, color: _kGreen),
        ),
      ),
    );
  }
}
