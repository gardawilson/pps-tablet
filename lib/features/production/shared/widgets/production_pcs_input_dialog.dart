// lib/features/production/shared/widgets/production_pcs_input_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/furniture_wip_item.dart';

class ProductionPcsInputResult {
  final int pcs;
  final bool isPartial;

  const ProductionPcsInputResult({required this.pcs, required this.isPartial});
}

class ProductionPcsInputDialog extends StatefulWidget {
  final FurnitureWipItem item;
  final int itemIndex;
  final int totalItems;
  final Color primaryColor;

  const ProductionPcsInputDialog({
    super.key,
    required this.item,
    required this.itemIndex,
    required this.totalItems,
    this.primaryColor = const Color(0xFF3730A3),
  });

  @override
  State<ProductionPcsInputDialog> createState() =>
      _ProductionPcsInputDialogState();
}

class _ProductionPcsInputDialogState extends State<ProductionPcsInputDialog> {
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
    Navigator.of(
      context,
    ).pop(ProductionPcsInputResult(pcs: val, isPartial: val < _maxPcs));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor;
    final labelCode = _labelOf(widget.item);
    final namaJenis = widget.item.namaJenis ?? 'Furniture WIP';

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
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 18,
                  ),
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
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Input field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan jumlah yang akan diinput',
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
                      suffixText: '/ $_maxPcs pcs',
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
                        borderSide: BorderSide(color: color, width: 2),
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

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Tambah'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
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
