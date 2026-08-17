import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../reject_type/model/reject_type_model.dart';
import '../../reject_type/repository/reject_type_repository.dart';
import '../../reject_type/view_model/reject_type_view_model.dart';
import '../../reject_type/widgets/reject_type_dropdown.dart';

const _kPrimary = Color(0xFF1E6FD9);

class ReturV3RejectGenerateResult {
  final double berat;
  final int idReject;

  const ReturV3RejectGenerateResult({
    required this.berat,
    required this.idReject,
  });
}

/// Dialog input berat + jenis reject sebelum generate label untuk item
/// REJECT pada status TIDAK_DIGANTI.
class ReturV3RejectGenerateDialog extends StatefulWidget {
  final String namaJenis;
  final int pcs;

  const ReturV3RejectGenerateDialog({
    super.key,
    required this.namaJenis,
    required this.pcs,
  });

  @override
  State<ReturV3RejectGenerateDialog> createState() =>
      _ReturV3RejectGenerateDialogState();
}

class _ReturV3RejectGenerateDialogState
    extends State<ReturV3RejectGenerateDialog> {
  final _beratCtrl = TextEditingController();
  RejectType? _selectedReject;
  String? _error;

  @override
  void dispose() {
    _beratCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final berat = double.tryParse(_beratCtrl.text.trim().replaceAll(',', '.'));
    if (berat == null || berat <= 0) {
      setState(() => _error = 'Berat harus lebih dari 0');
      return;
    }
    if (_selectedReject == null) {
      setState(() => _error = 'Pilih jenis reject');
      return;
    }
    Navigator.of(context).pop(
      ReturV3RejectGenerateResult(
        berat: berat,
        idReject: _selectedReject!.idReject,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RejectTypeViewModel>(
      create: (_) => RejectTypeViewModel(
        repository: RejectTypeRepository(api: ApiClient()),
      ),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Generate Label Reject',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                Text(
                  '${widget.namaJenis} · ${widget.pcs} pcs',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _beratCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Berat (kg)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                RejectTypeDropdown(
                  onChanged: (v) => setState(() => _selectedReject = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Generate Label'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
