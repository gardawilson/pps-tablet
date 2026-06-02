import 'package:flutter/material.dart';
import '../../shared/shared.dart';
import '../model/gilingan_output_model.dart';

const _kGilinganOutput = Color(0xFF00796B);
const _kGilinganBorder = Color(0xFFE2E6EA);

class GilinganOutputTile extends StatelessWidget {
  final GilinganOutput output;

  const GilinganOutputTile({super.key, required this.output});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGilinganBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => GilinganOutputDetailDialog(output: output),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      output.noGilingan,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D23),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.print_outlined,
                    size: 11,
                    color: output.hasBeenPrinted
                        ? _kGilinganOutput
                        : Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                output.namaJenis,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  ProductionMiniMetric(
                    icon: Icons.scale_outlined,
                    text: '${num2(output.berat)} kg',
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

class GilinganOutputSummaryTile extends StatelessWidget {
  final int totalLabel;
  final double totalBerat;

  const GilinganOutputSummaryTile({
    super.key,
    required this.totalLabel,
    required this.totalBerat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kGilinganOutput.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGilinganOutput.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ProductionInlineStat(
            label: 'Label',
            value: '$totalLabel',
            color: _kGilinganOutput,
          ),
          const SizedBox(width: 10),
          ProductionInlineStat(
            label: 'Berat',
            value: '${num2(totalBerat)} kg',
            color: _kGilinganOutput,
          ),
        ],
      ),
    );
  }
}

class GilinganOutputGrandTotalBar extends StatelessWidget {
  final int totalLabel;
  final double totalBerat;

  const GilinganOutputGrandTotalBar({
    super.key,
    required this.totalLabel,
    required this.totalBerat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              const Icon(Icons.summarize_outlined, size: 13, color: _kGilinganOutput),
              const SizedBox(width: 5),
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kGilinganOutput,
                ),
              ),
              const SizedBox(width: 10),
              ProductionInlineStat(label: 'Label', value: '$totalLabel', color: _kGilinganOutput),
              const SizedBox(width: 10),
              ProductionInlineStat(
                label: 'Berat',
                value: '${num2(totalBerat)} kg',
                color: _kGilinganOutput,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GilinganOutputDetailDialog extends StatelessWidget {
  final GilinganOutput output;

  const GilinganOutputDetailDialog({super.key, required this.output});

  static String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _kGilinganOutput,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.precision_manufacturing_outlined,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          output.namaJenis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          output.noGilingan,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.print_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          output.hasBeenPrinted ? 'Printed' : 'Belum Print',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kGilinganBorder),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(child: _InfoCell(label: 'No Gilingan', value: output.noGilingan)),
                  Expanded(child: _InfoCell(label: 'Berat', value: '${_fmt(output.berat)} kg')),
                  Expanded(child: _InfoCell(label: 'Jenis', value: output.namaJenis)),
                ],
              ),
            ),
            const Divider(height: 1, color: _kGilinganBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kGilinganBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
