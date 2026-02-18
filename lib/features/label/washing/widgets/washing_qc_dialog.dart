import 'package:flutter/material.dart';

import '../../../../common/widgets/qc_dialog_components.dart';
import '../model/washing_header_model.dart';

class WashingQcResult {
  final double? density1;
  final double? density2;
  final double? density3;
  final double? moisture1;
  final double? moisture2;
  final double? moisture3;

  const WashingQcResult({
    required this.density1,
    required this.density2,
    required this.density3,
    required this.moisture1,
    required this.moisture2,
    required this.moisture3,
  });
}

class WashingQcDialog extends StatefulWidget {
  final WashingHeader header;

  const WashingQcDialog({super.key, required this.header});

  @override
  State<WashingQcDialog> createState() => _WashingQcDialogState();
}

class _WashingQcDialogState extends State<WashingQcDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _density1Ctrl;
  late final TextEditingController _density2Ctrl;
  late final TextEditingController _density3Ctrl;
  late final TextEditingController _moisture1Ctrl;
  late final TextEditingController _moisture2Ctrl;
  late final TextEditingController _moisture3Ctrl;

  @override
  void initState() {
    super.initState();
    _density1Ctrl = TextEditingController(text: _toText(widget.header.density));
    _density2Ctrl = TextEditingController(
      text: _toText(widget.header.density2),
    );
    _density3Ctrl = TextEditingController(
      text: _toText(widget.header.density3),
    );
    _moisture1Ctrl = TextEditingController(
      text: _toText(widget.header.moisture),
    );
    _moisture2Ctrl = TextEditingController(
      text: _toText(widget.header.moisture2),
    );
    _moisture3Ctrl = TextEditingController(
      text: _toText(widget.header.moisture3),
    );
  }

  @override
  void dispose() {
    _density1Ctrl.dispose();
    _density2Ctrl.dispose();
    _density3Ctrl.dispose();
    _moisture1Ctrl.dispose();
    _moisture2Ctrl.dispose();
    _moisture3Ctrl.dispose();
    super.dispose();
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
    final value = _parseNullableDecimal(raw);
    if (value == null) return 'Angka tidak valid';
    if (value < 0) return 'Tidak boleh negatif';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      WashingQcResult(
        density1: _parseNullableDecimal(_density1Ctrl.text),
        density2: _parseNullableDecimal(_density2Ctrl.text),
        density3: _parseNullableDecimal(_density3Ctrl.text),
        moisture1: _parseNullableDecimal(_moisture1Ctrl.text),
        moisture2: _parseNullableDecimal(_moisture2Ctrl.text),
        moisture3: _parseNullableDecimal(_moisture3Ctrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QcDialogShell(
      title: 'Quality Control',
      subtitle: widget.header.noWashing,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submit,
      content: SizedBox(
        width: 520,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const QcSectionTitle(
                    icon: Icons.science_outlined,
                    text: 'Density (g/cm3)',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: QcDecimalField(
                          label: 'Density 1',
                          controller: _density1Ctrl,
                          validator: _validateDecimal,
                          suffix: 'g/cm3',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: QcDecimalField(
                          label: 'Density 2',
                          controller: _density2Ctrl,
                          validator: _validateDecimal,
                          suffix: 'g/cm3',
                        ),
                      ),
                      const SizedBox(width: 10),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: QcDialogPalette.border),
                  ),
                  const QcSectionTitle(
                    icon: Icons.opacity_outlined,
                    text: 'Moisture (g/cm3)',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: QcDecimalField(
                          label: 'Moisture 1',
                          controller: _moisture1Ctrl,
                          validator: _validateDecimal,
                          suffix: 'g/cm3',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: QcDecimalField(
                          label: 'Moisture 2',
                          controller: _moisture2Ctrl,
                          validator: _validateDecimal,
                          suffix: 'g/cm3',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: QcDecimalField(
                          label: 'Moisture 3',
                          controller: _moisture3Ctrl,
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
