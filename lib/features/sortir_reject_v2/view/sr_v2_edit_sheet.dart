import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../warehouse/model/warehouse_model.dart';
import '../../warehouse/repository/warehouse_repository.dart';
import '../model/sr_v2_transaction.dart';
import '../repository/sr_v2_repository.dart';

// ─── Theme ──────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);

// ─── Public entry-point ─────────────────────────────────────────────────────

Future<bool> showSrV2EditSheet(
  BuildContext context, {
  required SrV2Transaction transaction,
  required SrV2Repository repository,
  VoidCallback? onUpdated,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _SrV2EditDialog(transaction: transaction, repository: repository),
  );
  if (result == true) onUpdated?.call();
  return result == true;
}

// ─── Dialog ─────────────────────────────────────────────────────────────────

class _SrV2EditDialog extends StatefulWidget {
  final SrV2Transaction transaction;
  final SrV2Repository repository;

  const _SrV2EditDialog({required this.transaction, required this.repository});

  @override
  State<_SrV2EditDialog> createState() => _SrV2EditDialogState();
}

class _SrV2EditDialogState extends State<_SrV2EditDialog> {
  List<MstWarehouse> _warehouses = [];
  bool _loadingWarehouses = true;

  MstWarehouse? _selectedWarehouse;
  late DateTime _selectedDate;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.transaction.tanggal ?? DateTime.now();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      final items = await WarehouseRepository().fetchAll();
      if (!mounted) return;
      setState(() {
        _warehouses = items;
        _loadingWarehouses = false;
        if (widget.transaction.idWarehouse != null) {
          _selectedWarehouse = items.firstWhere(
            (w) => w.idWarehouse == widget.transaction.idWarehouse,
            orElse: () => items.first,
          );
        } else if (items.isNotEmpty) {
          _selectedWarehouse = items.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingWarehouses = false;
        _error = 'Gagal memuat warehouse: $e';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedWarehouse == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.repository.update(
        noSortir: widget.transaction.noSortir,
        idWarehouse: _selectedWarehouse!.idWarehouse,
        tglBJSortir: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: SizedBox(
        width: 440,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                decoration: const BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: _kPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubah Sortir Reject',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D23),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            widget.transaction.noSortir,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A94A6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF8A94A6),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal
                    const _Label('Tanggal'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _submitting ? null : _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Color(0xFF8A94A6),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1D23),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Color(0xFF8A94A6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Warehouse
                    const _Label('Warehouse'),
                    const SizedBox(height: 6),
                    if (_loadingWarehouses)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<MstWarehouse>(
                            isExpanded: true,
                            value: _selectedWarehouse,
                            onChanged: _submitting
                                ? null
                                : (v) => setState(() => _selectedWarehouse = v),
                            items: _warehouses
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w,
                                    child: Text(
                                      w.namaWarehouse,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1A1D23),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1D23),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 13,
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

              // ── Footer / Actions ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: _kBorder),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed:
                            (_submitting ||
                                _selectedWarehouse == null ||
                                _loadingWarehouses)
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.2,
      ),
    );
  }
}
