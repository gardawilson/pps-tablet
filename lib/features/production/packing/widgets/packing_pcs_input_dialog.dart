// lib/features/production/packing/widgets/packing_pcs_input_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../model/packing_production_inputs_model.dart';

const _kPrimary = Color(0xFF3730A3);

class PackingPcsInputResult {
  final int pcs;
  final bool isPartial;

  const PackingPcsInputResult({required this.pcs, required this.isPartial});
}

class PackingPcsInputDialog extends StatefulWidget {
  final FurnitureWipItem item;
  final int itemIndex;
  final int totalItems;

  const PackingPcsInputDialog({
    super.key,
    required this.item,
    required this.itemIndex,
    required this.totalItems,
  });

  @override
  State<PackingPcsInputDialog> createState() => _PackingPcsInputDialogState();
}

class _PackingPcsInputDialogState extends State<PackingPcsInputDialog> {
  late final TextEditingController _ctrl;
  late final int _maxPcs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _maxPcs = widget.item.pcsHeader ?? widget.item.pcs ?? 0;
    _ctrl = TextEditingController(text: '$_maxPcs');
    _ctrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _ctrl.text.length,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final val = int.tryParse(_ctrl.text.trim());
    if (val == null || val <= 0) {
      setState(() => _error = 'Masukkan angka yang valid');
      return;
    }
    if (val > _maxPcs) {
      setState(() => _error = 'Maksimal $_maxPcs pcs');
      return;
    }
    Navigator.of(context).pop(
      PackingPcsInputResult(pcs: val, isPartial: val < _maxPcs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelCode = _labelOf(widget.item);
    final namaJenis = widget.item.namaJenis ?? 'Furniture WIP';
    final currentVal = int.tryParse(_ctrl.text.trim()) ?? 0;
    final isPartialPreview = currentVal > 0 && currentVal < _maxPcs;
    final isFullPreview = currentVal == _maxPcs && _maxPcs > 0;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labelCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          namaJenis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.totalItems > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.itemIndex + 1} / ${widget.totalItems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),

            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: 'PCS Asli',
                    value: '$_maxPcs pcs',
                    color: _kPrimary,
                  ),
                ],
              ),
            ),

            // Input field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumlah PCS yang akan diinput',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      suffixText: 'pcs',
                      suffixStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      errorText: _error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: _kPrimary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),

            // Mode preview badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: isFullPreview
                    ? _ModeBadge(
                        key: const ValueKey('full'),
                        label: 'FULL',
                        description: 'Semua pcs akan diinput',
                        color: Colors.green.shade700,
                        icon: Icons.check_circle_outline,
                      )
                    : isPartialPreview
                        ? _ModeBadge(
                            key: const ValueKey('partial'),
                            label: 'PARTIAL',
                            description:
                                'Hanya $currentVal dari $_maxPcs pcs',
                            color: Colors.amber.shade700,
                            icon: Icons.content_cut,
                          )
                        : const SizedBox.shrink(key: ValueKey('none')),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E6EA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Lewati'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text(
                      isPartialPreview ? 'Tambah Partial' : 'Tambah Full',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isPartialPreview
                          ? Colors.amber.shade600
                          : _kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _labelOf(FurnitureWipItem item) {
    final partial = (item.noFurnitureWIPPartial ?? '').trim();
    return partial.isNotEmpty ? partial : (item.noFurnitureWIP ?? '-');
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const _ModeBadge({
    super.key,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
