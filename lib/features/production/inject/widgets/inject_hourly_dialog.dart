import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/inject_hourly_model.dart';

const _kPrimary = Color(0xFF0277BD);
const _kBorder = Color(0xFFE2E6EA);

class InjectHourlyDialog extends StatefulWidget {
  final String noProduksi;
  final String? initialJam;
  final String? jamLabel;

  const InjectHourlyDialog({
    super.key,
    required this.noProduksi,
    this.initialJam,
    this.jamLabel,
  });

  @override
  State<InjectHourlyDialog> createState() => _InjectHourlyDialogState();
}

class _InjectHourlyDialogState extends State<InjectHourlyDialog> {
  final _beratCtrl = TextEditingController();
  final _cycleCtrl = TextEditingController();
  final _counterCtrl = TextEditingController();

  @override
  void dispose() {
    _beratCtrl.dispose();
    _cycleCtrl.dispose();
    _counterCtrl.dispose();
    super.dispose();
  }

  bool get _formValid {
    final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
    final cycle = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
    final counter = int.tryParse(_counterCtrl.text);
    return berat != null &&
        berat > 0 &&
        cycle != null &&
        cycle > 0 &&
        counter != null &&
        counter > 0;
  }

  void _submitForm() {
    if (!_formValid) return;
    // TODO: kirim ke API
    final entry = InjectHourlyEntry(
      noProduksi: widget.noProduksi,
      jam: widget.initialJam ?? '',
      berat: double.tryParse(_beratCtrl.text.replaceAll(',', '.')),
      cycleTime: double.tryParse(_cycleCtrl.text.replaceAll(',', '.')),
      counter: int.tryParse(_counterCtrl.text),
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: _kBorder),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.timer_outlined, color: _kPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Input QC Per Jam',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  widget.noProduksi,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final displayLabel = widget.jamLabel?.isNotEmpty == true
        ? widget.jamLabel!
        : (widget.initialJam ?? '-');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Jam — read-only label
          Text(
            'Jam',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              displayLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3 input fields
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Berat (kg)',
                  controller: _beratCtrl,
                  hint: '0.0',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  label: 'Cycle Time (detik)',
                  controller: _cycleCtrl,
                  hint: '0.0',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  label: 'Counter',
                  controller: _counterCtrl,
                  hint: '0',
                  decimal: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _formValid ? _submitForm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool decimal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'^\d*[,.]?\d*') : RegExp(r'\d+'),
            ),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: _inputDecoration(hint),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
