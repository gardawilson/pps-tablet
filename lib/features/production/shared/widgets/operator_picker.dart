// lib/features/production/shared/widgets/operator_picker.dart
//
// Picker operator-only (multi-select), tanpa Regu — dipakai modul yang
// sudah punya Tim sebagai identitas kelompok kerja (mis. Penerimaan Bahan
// Baku/Pendukung), sehingga Regu jadi redundan dan cukup operatornya saja
// yang perlu dipilih untuk header.
import 'package:flutter/material.dart';

import '../../../operator/model/operator_model.dart';
import '../../../operator/repository/operator_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Field: container berlabel OPERATOR — tap → buka dialog multi-select
// ─────────────────────────────────────────────────────────────────────────────
class OperatorPickerField extends StatelessWidget {
  const OperatorPickerField({
    super.key,
    required this.selectedOperators,
    required this.isLoading,
    required this.onTap,
  });

  final List<MstOperator> selectedOperators;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasOperator = selectedOperators.isNotEmpty;
    final operatorValue = hasOperator
        ? selectedOperators.map((o) => o.namaOperator).join(', ')
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasOperator
                  ? const Color(0xFF6B7280)
                  : const Color(0xFFD1D5DB),
              width: hasOperator ? 1.0 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline,
                            size: 10, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        const Text(
                          'OPERATOR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (hasOperator) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${selectedOperators.length} orang',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasOperator ? operatorValue! : 'Pilih operator',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            hasOperator ? FontWeight.w600 : FontWeight.w400,
                        color: hasOperator
                            ? const Color(0xFF374151)
                            : const Color(0xFFD1D5DB),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Icon(
                      hasOperator
                          ? Icons.edit_outlined
                          : Icons.chevron_right_rounded,
                      size: 16,
                      color: const Color(0xFF9CA3AF),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: load semua operator lalu buka dialog multi-select
// ─────────────────────────────────────────────────────────────────────────────
Future<List<MstOperator>?> showOperatorPicker(
  BuildContext context, {
  List<MstOperator> initialSelected = const [],
}) async {
  List<MstOperator> allOperators = [];
  try {
    allOperators = await OperatorRepository().fetchAll();
  } catch (_) {}

  if (!context.mounted) return null;

  return showDialog<List<MstOperator>>(
    context: context,
    builder: (_) => _OperatorPickerDialog(
      operators: allOperators,
      initialSelected: initialSelected,
    ),
  );
}

class _OperatorPickerDialog extends StatefulWidget {
  const _OperatorPickerDialog({
    required this.operators,
    required this.initialSelected,
  });

  final List<MstOperator> operators;
  final List<MstOperator> initialSelected;

  @override
  State<_OperatorPickerDialog> createState() => _OperatorPickerDialogState();
}

class _OperatorPickerDialogState extends State<_OperatorPickerDialog> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected.map((o) => o.idOperator).toSet();
  }

  bool get _allSelected =>
      widget.operators.isNotEmpty && _selected.length == widget.operators.length;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected.addAll(widget.operators.map((o) => o.idOperator));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Container(
        width: 420,
        height: 500,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Pilih Operator',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    if (widget.operators.isNotEmpty)
                      TextButton(
                        onPressed: _toggleAll,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _allSelected ? 'Hapus Semua' : 'Pilih Semua',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white),
                        ),
                      ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(null),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: widget.operators.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada operator',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.operators.length,
                        itemBuilder: (_, i) {
                          final op = widget.operators[i];
                          final isChecked = _selected.contains(op.idOperator);
                          return CheckboxListTile(
                            value: isChecked,
                            dense: true,
                            title: Text(
                              op.namaOperator,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(op.idOperator);
                                } else {
                                  _selected.remove(op.idOperator);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selected.length} operator dipilih',
                      style:
                          const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selected.isEmpty
                              ? null
                              : () {
                                  final ops = widget.operators
                                      .where((o) =>
                                          _selected.contains(o.idOperator))
                                      .toList();
                                  Navigator.of(context).pop(ops);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Pilih'),
                        ),
                      ],
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
