import 'package:flutter/material.dart';

import '../../../../common/widgets/qc_dialog_components.dart';
import '../model/bahan_baku_pallet.dart';

class BahanBakuQcResult {
  final double? tenggelam;
  final double? density1;
  final double? density2;
  final double? density3;

  const BahanBakuQcResult({
    required this.tenggelam,
    required this.density1,
    required this.density2,
    required this.density3,
  });
}

class BahanBakuQcDialog extends StatefulWidget {
  final BahanBakuPallet pallet;

  const BahanBakuQcDialog({super.key, required this.pallet});

  @override
  State<BahanBakuQcDialog> createState() => _BahanBakuQcDialogState();
}

class _BahanBakuQcDialogState extends State<BahanBakuQcDialog> {
  final _formKey = GlobalKey<FormState>();

  double? _selectedTenggelam;
  late final TextEditingController _density1Ctrl;
  late final TextEditingController _density2Ctrl;
  late final TextEditingController _density3Ctrl;

  @override
  void initState() {
    super.initState();
    _selectedTenggelam = _normalizeTenggelam(widget.pallet.tenggelam);
    _density1Ctrl = TextEditingController(text: _toText(widget.pallet.density));
    _density2Ctrl = TextEditingController(
      text: _toText(widget.pallet.density2),
    );
    _density3Ctrl = TextEditingController(
      text: _toText(widget.pallet.density3),
    );
  }

  @override
  void dispose() {
    _density1Ctrl.dispose();
    _density2Ctrl.dispose();
    _density3Ctrl.dispose();
    super.dispose();
  }

  double? _normalizeTenggelam(double? value) {
    if (value == null) return null;
    if ((value - 5).abs() < 0.0001 || (value - 0.05).abs() < 0.0001) return 5;
    if ((value - 10).abs() < 0.0001 || (value - 0.10).abs() < 0.0001) {
      return 10;
    }
    return null;
  }

  String _toText(double? value) =>
      value == null ? '' : value.toStringAsFixed(3);

  double? _parseNullableDecimal(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String? _validateDecimal(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = _parseNullableDecimal(raw);
    if (v == null) return 'Angka tidak valid';
    if (v < 0) return 'Tidak boleh negatif';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      BahanBakuQcResult(
        tenggelam: _selectedTenggelam,
        density1: _parseNullableDecimal(_density1Ctrl.text),
        density2: _parseNullableDecimal(_density2Ctrl.text),
        density3: _parseNullableDecimal(_density3Ctrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QcDialogShell(
      title: 'Quality Control',
      subtitle: widget.pallet.noPallet,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submit,
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: QcDialogPalette.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: QcSectionTitle(
                      icon: Icons.opacity_outlined,
                      text: 'QC Bahan Baku',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          initialValue: _selectedTenggelam,
                          decoration: qcInputDecoration(
                            label: 'Tenggelam',
                            suffix: '%',
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: QcDialogPalette.text,
                          ),
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5')),
                            DropdownMenuItem(value: 10, child: Text('10')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedTenggelam = value);
                          },
                          validator: (value) {
                            if (value == null) return 'Pilih tenggelam';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QcDecimalField(
                          label: 'Density 1',
                          controller: _density1Ctrl,
                          validator: _validateDecimal,
                          suffix: 'g/cm3',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: QcDecimalField(
                          label: 'Density 2',
                          controller: _density2Ctrl,
                          validator: _validateDecimal,
                          suffix: 'g/cm3',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QcDecimalField(
                          label: 'Density 3',
                          controller: _density3Ctrl,
                          validator: _validateDecimal,
                          suffix: 'g/cm3',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
