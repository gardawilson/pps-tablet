// lib/features/production/crusher/widgets/crusher_production_output_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../repository/crusher_production_input_repository.dart';

const _kOutput = Color(0xFF00796B);
const _kBorder = Color(0xFFE2E6EA);

class CrusherProductionOutputFormDialog extends StatefulWidget {
  final String noProduksi;
  final int idJenis;
  final String namaJenis;
  final DateTime? tglProduksi;
  final CrusherProductionInputRepository repository;

  const CrusherProductionOutputFormDialog({
    super.key,
    required this.noProduksi,
    required this.idJenis,
    required this.namaJenis,
    required this.repository,
    this.tglProduksi,
  });

  @override
  State<CrusherProductionOutputFormDialog> createState() =>
      _CrusherProductionOutputFormDialogState();
}

class _CrusherProductionOutputFormDialogState
    extends State<CrusherProductionOutputFormDialog> {
  final _beratCtrl = TextEditingController();
  String? _beratErr;

  bool _isSaving = false;
  String? _saveError;

  @override
  void dispose() {
    _beratCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final berat = double.tryParse(_beratCtrl.text.trim());
    setState(() {
      _beratErr = (berat == null || berat <= 0) ? 'Harus > 0' : null;
    });
    if (_beratErr != null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.repository.createOutputs(
        noProduksi: widget.noProduksi,
        idJenis: widget.idJenis,
        berat: berat!,
        tglProduksi: widget.tglProduksi ?? DateTime.now(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tglText = widget.tglProduksi == null
        ? '-'
        : DateFormat('dd MMM yyyy', 'id_ID').format(
            widget.tglProduksi!.toLocal(),
          );

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: _kBorder),
            _buildInfoBar(tglText),
            const Divider(height: 1, color: _kBorder),
            _buildBody(),
            if (_saveError != null) _buildErrorBanner(),
            const Divider(height: 1, color: _kBorder),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kOutput.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.precision_manufacturing_outlined,
              color: _kOutput,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Tambah Output Crusher',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(String tglText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Wrap(
        spacing: 18,
        runSpacing: 6,
        children: [
          _InfoChip(
            icon: Icons.receipt_long_outlined,
            label: 'No Produksi',
            value: widget.noProduksi,
          ),
          _InfoChip(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            value: tglText,
          ),
          _InfoChip(
            icon: Icons.category_outlined,
            label: 'Jenis',
            value: widget.namaJenis,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: TextField(
        controller: _beratCtrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        autofocus: true,
        onChanged: (_) => setState(() => _beratErr = null),
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: 'Berat (kg)',
          prefixIcon: const Icon(Icons.scale_outlined, size: 16),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          errorText: _beratErr,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _kOutput, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 15, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _saveError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
            ),
            child: const Text('Batal', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 15),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOutput,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
