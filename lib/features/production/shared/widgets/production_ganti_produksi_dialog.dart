import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductionGantiProduksiDialog<TResult, TJenis> extends StatefulWidget {
  const ProductionGantiProduksiDialog({
    super.key,
    required this.tanggal,
    required this.shift,
    required this.primaryColor,
    required this.borderColor,
    required this.jenisRequiredMessage,
    required this.dropdownBuilder,
    required this.jenisNameOf,
    required this.onSubmit,
    this.submitLabel = 'Ganti Produksi',
  });

  final DateTime tanggal;
  final int shift;
  final Color primaryColor;
  final Color borderColor;
  final String jenisRequiredMessage;
  final String submitLabel;
  final Widget Function(TJenis? selected, ValueChanged<TJenis?> onChanged)
  dropdownBuilder;
  final String Function(TJenis jenis) jenisNameOf;
  final Future<TResult> Function(String hourStart, TJenis selectedJenis) onSubmit;

  @override
  State<ProductionGantiProduksiDialog<TResult, TJenis>> createState() =>
      _ProductionGantiProduksiDialogState<TResult, TJenis>();
}

class _ProductionGantiProduksiDialogState<TResult, TJenis>
    extends State<ProductionGantiProduksiDialog<TResult, TJenis>> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hourCtrl = TextEditingController(
    text: () {
      final now = DateTime.now();
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }(),
  );
  TJenis? _selectedJenis;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _hourCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    _hourCtrl.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = _selectedJenis;
    if (selected == null) {
      setState(() => _errorMsg = widget.jenisRequiredMessage);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final result = await widget.onSubmit(_hourCtrl.text.trim(), selected);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tglLabel = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(widget.tanggal.toLocal());

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ganti Produksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$tglLabel  ·  Shift ${widget.shift}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _hourCtrl,
                            readOnly: true,
                            onTap: _pickTime,
                            decoration: InputDecoration(
                              labelText: 'Jam Mulai',
                              hintText: '08:00',
                              suffixIcon: const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(color: widget.borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(
                                  color: widget.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: widget.dropdownBuilder(
                            _selectedJenis,
                            (v) => setState(() => _selectedJenis = v),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Divider(height: 1, color: widget.borderColor),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: BorderSide(color: widget.borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isLoading
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
                        _isLoading ? 'Menyimpan...' : widget.submitLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
