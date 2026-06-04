import 'package:flutter/material.dart';
import '../../shared/shared.dart';
import '../model/mixer_output_model.dart';

const _kMixerOutput = Color(0xFF1565C0);
const _kMixerBorder = Color(0xFFE2E6EA);

// ── Output tile ───────────────────────────────────────────────────────────────

class MixerOutputTile extends StatelessWidget {
  final MixerOutput output;
  final VoidCallback? onPrint;

  const MixerOutputTile({super.key, required this.output, this.onPrint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kMixerBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => MixerOutputDetailDialog(output: output, onPrint: onPrint),
        ),
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
                      output.noMixer,
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1D23),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.print_outlined, size: 11,
                      color: output.hasPrinted > 0 ? _kMixerOutput : Colors.grey.shade400),
                  const SizedBox(width: 2),
                  Text(
                    'x${output.hasPrinted}',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: output.hasPrinted > 0 ? _kMixerOutput : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(output.namaJenis,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6, runSpacing: 2,
                children: [
                  ProductionMiniMetric(icon: Icons.inventory_2_outlined, text: '${output.totalSak} sak'),
                  ProductionMiniMetric(icon: Icons.scale_outlined, text: '${num2(output.totalBerat)} kg'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary tile ──────────────────────────────────────────────────────────────

class MixerOutputSummaryTile extends StatelessWidget {
  final int totalLabel;
  final int totalSak;
  final double totalBerat;

  const MixerOutputSummaryTile({
    super.key,
    required this.totalLabel,
    required this.totalSak,
    required this.totalBerat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kMixerOutput.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kMixerOutput.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ProductionInlineStat(label: 'Label', value: '$totalLabel', color: _kMixerOutput),
          const SizedBox(width: 10),
          ProductionInlineStat(label: 'Sak', value: '$totalSak', color: _kMixerOutput),
          const SizedBox(width: 10),
          ProductionInlineStat(label: 'Berat', value: '${num2(totalBerat)} kg', color: _kMixerOutput),
        ],
      ),
    );
  }
}

// ── Grand total bar ───────────────────────────────────────────────────────────

class MixerOutputGrandTotalBar extends StatelessWidget {
  final int totalLabel;
  final int totalSak;
  final double totalBerat;

  const MixerOutputGrandTotalBar({
    super.key,
    required this.totalLabel,
    required this.totalSak,
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
              const Icon(Icons.summarize_outlined, size: 13, color: _kMixerOutput),
              const SizedBox(width: 5),
              const Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMixerOutput)),
              const SizedBox(width: 10),
              ProductionInlineStat(label: 'Label', value: '$totalLabel', color: _kMixerOutput),
              const SizedBox(width: 10),
              ProductionInlineStat(label: 'Sak', value: '$totalSak', color: _kMixerOutput),
              const SizedBox(width: 10),
              ProductionInlineStat(label: 'Berat', value: '${num2(totalBerat)} kg', color: _kMixerOutput),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Detail dialog ─────────────────────────────────────────────────────────────

class MixerOutputDetailDialog extends StatelessWidget {
  final MixerOutput output;
  final VoidCallback? onPrint;

  const MixerOutputDetailDialog({super.key, required this.output, this.onPrint});

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
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _kMixerOutput,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.blender_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(output.namaJenis,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(output.noMixer,
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
                        Text('x${output.hasPrinted}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
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
            const Divider(height: 1, color: _kMixerBorder),

            // Sak grid
            Flexible(
              child: output.detailSak.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Tidak ada detail sak',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7, crossAxisSpacing: 5, mainAxisSpacing: 5, childAspectRatio: 1.6,
                        ),
                        itemCount: output.detailSak.length,
                        itemBuilder: (_, i) {
                          final sak = output.detailSak[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: _kMixerOutput.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Sak ${sak.noSak}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kMixerOutput)),
                                const SizedBox(height: 2),
                                Text('${_fmt(sak.berat)} kg',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const Divider(height: 1, color: _kMixerBorder),

            // Footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onPrint != null)
                    TextButton.icon(
                      onPressed: () { Navigator.of(context).pop(); onPrint!(); },
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: const Text('Print'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kMixerBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
