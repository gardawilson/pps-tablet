import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../label/reject/repository/reject_repository.dart';
import '../../../reject_type/model/reject_type_model.dart';
import '../../../reject_type/widgets/packing_type_dropdown.dart';

const _kRejectAccent = Color(0xFF0F766E);
const _kRejectBorder = Color(0xFFE2E6EA);

class SpannerRejectOutputFormDialog extends StatefulWidget {
  const SpannerRejectOutputFormDialog({
    super.key,
    required this.noProduksi,
    this.tglProduksi,
  });

  final String noProduksi;
  final DateTime? tglProduksi;

  @override
  State<SpannerRejectOutputFormDialog> createState() =>
      _SpannerRejectOutputFormDialogState();
}

class _SpannerRejectOutputFormDialogState
    extends State<SpannerRejectOutputFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _beratCtrl = TextEditingController();

  RejectType? _selectedType;
  String? _saveError;
  bool _isSaving = false;

  @override
  void dispose() {
    _beratCtrl.dispose();
    super.dispose();
  }

  String _currentJam() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final berat = double.tryParse(_beratCtrl.text.trim().replaceAll(',', '.'));
    if (berat == null || berat <= 0) {
      setState(() => _saveError = 'Berat harus > 0');
      return;
    }
    if (_selectedType == null) {
      setState(() => _saveError = 'Pilih jenis reject terlebih dahulu');
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final repo = RejectRepository(api: ApiClient());
      final response = await repo.createReject({
        'header': {
          'IdReject': _selectedType!.idReject,
          'Berat': berat,
          'DateCreate': toDbDateString(widget.tglProduksi ?? DateTime.now()),
          'Jam': _currentJam(),
        },
        'outputCode': widget.noProduksi,
      });

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final headers = (data['headers'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => (e['NoReject'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toList();
      if (headers.isEmpty) {
        final single = (data['header'] as Map?)?['NoReject']?.toString() ?? '';
        if (single.isNotEmpty) headers.add(single);
      }

      if (!mounted) return;
      Navigator.of(context).pop(headers);
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
    final tglText = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format((widget.tglProduksi ?? DateTime.now()).toLocal());

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const Divider(height: 1, color: _kRejectBorder),
              _buildInfoBar(tglText),
              const Divider(height: 1, color: _kRejectBorder),
              _buildBody(),
              if (_saveError != null) _buildErrorBanner(),
              const Divider(height: 1, color: _kRejectBorder),
              _buildFooter(),
            ],
          ),
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
              color: _kRejectAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.report_problem_outlined,
              color: _kRejectAccent,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Tambah Output Reject',
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
            icon: Icons.schedule_outlined,
            label: 'Jam',
            value: _currentJam(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RejectTypeDropdown(
            onChanged: (value) {
              setState(() {
                _selectedType = value;
                _saveError = null;
              });
            },
            validator: (value) =>
                value == null ? 'Pilih jenis reject terlebih dahulu' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _beratCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            autofocus: true,
            onChanged: (_) => setState(() => _saveError = null),
            onFieldSubmitted: (_) => _save(),
            validator: (value) {
              final raw = (value ?? '').trim();
              if (raw.isEmpty) return 'Berat harus diisi';
              final parsed = double.tryParse(raw.replaceAll(',', '.'));
              if (parsed == null) return 'Format berat tidak valid';
              if (parsed <= 0) return 'Berat harus > 0';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Berat (kg)',
              prefixIcon: const Icon(Icons.scale_outlined, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: _kRejectBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide:
                    const BorderSide(color: _kRejectAccent, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
            ),
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              backgroundColor: _kRejectAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
