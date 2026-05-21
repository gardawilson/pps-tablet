// lib/features/label/bonggolan/widgets/bonggolan_production_output_form_dialog.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../jenis_bonggolan/model/jenis_bonggolan_model.dart';
import '../../../jenis_bonggolan/widgets/jenis_bonggolan_dropdown.dart';
import '../repository/bonggolan_repository.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);

class BonggolanProductionOutputFormDialog extends StatefulWidget {
  final String noProduksi;
  final DateTime? tglProduksi;
  final String? namaMesin;

  const BonggolanProductionOutputFormDialog({
    super.key,
    required this.noProduksi,
    this.tglProduksi,
    this.namaMesin,
  });

  @override
  State<BonggolanProductionOutputFormDialog> createState() =>
      _BonggolanProductionOutputFormDialogState();
}

class _BonggolanProductionOutputFormDialogState
    extends State<BonggolanProductionOutputFormDialog> {
  final _beratCtrl = TextEditingController();
  JenisBonggolan? _selectedJenis;
  String? _beratErr;
  String? _jenisErr;

  bool _isSaving = false;
  String? _saveError;

  @override
  void dispose() {
    _beratCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final berat = double.tryParse(_beratCtrl.text.trim());

    // ignore: avoid_print
    print('🔵 [BonggolanForm] _save called | jenis=$_selectedJenis | berat=$berat');

    setState(() {
      _jenisErr = _selectedJenis == null ? 'Pilih jenis bonggolan' : null;
      _beratErr = (berat == null || berat <= 0) ? 'Harus > 0' : null;
      _saveError = null;
    });

    if (_jenisErr != null || _beratErr != null) {
      // ignore: avoid_print
      print('🔴 [BonggolanForm] validation failed | jenisErr=$_jenisErr | beratErr=$_beratErr');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = BonggolanRepository();
      final tglStr = widget.tglProduksi != null
          ? DateFormat('yyyy-MM-dd').format(widget.tglProduksi!)
          : DateFormat('yyyy-MM-dd').format(DateTime.now());

      final body = {
        'header': {
          'IdBonggolan': _selectedJenis!.idBonggolan,
          'IdWarehouse': 5,
          'DateCreate': tglStr,
          'Berat': berat,
        },
        'ProcessedCode': widget.noProduksi,
      };

      // ignore: avoid_print
      print('➡️ [BonggolanForm] POST createBonggolan body=$body');

      final result = await repo.createBonggolan(body);

      // ignore: avoid_print
      print('✅ [BonggolanForm] POST success result=$result');

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      // ignore: avoid_print
      print('❌ [BonggolanForm] POST error: $e');
      if (!mounted) return;
      String msg = e.toString().replaceFirst('Exception: ', '');
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(msg);
      if (jsonMatch != null) {
        try {
          msg = (jsonDecode(jsonMatch.group(0)!)['message'] as String?) ?? msg;
        } catch (_) {}
      }
      setState(() {
        _isSaving = false;
        _saveError = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tglText = widget.tglProduksi == null
        ? '-'
        : DateFormat('dd MMM yyyy', 'id_ID')
            .format(widget.tglProduksi!.toLocal());

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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_box_outlined,
                      color: _kPrimary,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tambah Label Bonggolan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),

            // Info bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.receipt_long_outlined,
                    label: 'No Produksi',
                    value: widget.noProduksi,
                  ),
                  if (widget.namaMesin != null &&
                      widget.namaMesin!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.precision_manufacturing_outlined,
                      label: 'Mesin',
                      value: widget.namaMesin!,
                    ),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal',
                    value: tglText,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),

            // Form fields
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JenisBonggolanDropdown(
                    onChanged: (jb) => setState(() {
                      _selectedJenis = jb;
                      _jenisErr = null;
                    }),
                    validator: (_) => _jenisErr,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _beratCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => setState(() => _beratErr = null),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: 'Berat (kg)',
                      prefixIcon:
                          const Icon(Icons.scale_outlined, size: 15),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
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
                        borderSide: const BorderSide(
                          color: _kPrimary,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide:
                            BorderSide(color: Colors.red.shade400),
                      ),
                    ),
                  ),
                  if (_saveError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 15, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _saveError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Footer
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontSize: 13),
                    ),
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
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
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
}

// ── small widgets ─────────────────────────────────────────────────────────────

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
