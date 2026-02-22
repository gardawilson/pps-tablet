// lib/features/shared/bongkar_susun/widgets/bongkar_susun_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/app_date_field.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/bongkar_susun_model.dart';
import '../view_model/bongkar_susun_view_model.dart';
import 'bongkar_susun_text_field.dart';

class BongkarSusunFormDialog extends StatefulWidget {
  final BongkarSusun? header;
  final Function(BongkarSusun)? onSave;

  const BongkarSusunFormDialog({
    super.key,
    this.header,
    this.onSave,
  });

  @override
  State<BongkarSusunFormDialog> createState() =>
      _BongkarSusunFormDialogState();
}

class _BongkarSusunFormDialogState extends State<BongkarSusunFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noBsCtrl;
  late final TextEditingController tanggalCtrl;
  late final TextEditingController noteCtrl;

  // State
  DateTime _selectedDate = DateTime.now();

  bool get isEdit => widget.header != null;

  @override
  void initState() {
    super.initState();

    noBsCtrl = TextEditingController(
      text: widget.header?.noBongkarSusun ?? '',
    );

    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.tanggal) ?? DateTime.now())
        : DateTime.now();

    _selectedDate = seededDate;
    tanggalCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    noteCtrl = TextEditingController(
      text: widget.header?.note ?? '',
    );
  }

  @override
  void dispose() {
    noBsCtrl.dispose();
    tanggalCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prodVm = context.read<BongkarSusunViewModel>();

    final rawNote = noteCtrl.text.trim();
    final note = rawNote.isEmpty ? null : rawNote;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    BongkarSusun? result;

    try {
      if (isEdit) {
        result = await prodVm.updateBongkarSusun(
          noBongkarSusun: widget.header!.noBongkarSusun,
          tanggal: _selectedDate,
          note: note,
        );
      } else {
        result = await prodVm.createBongkarSusun(
          tanggal: _selectedDate,
          note: note,
        );
      }
    } catch (e) {
      // error handled via prodVm.saveError
    } finally {
      if (mounted) Navigator.of(context).pop();
    }

    if (!mounted) return;

    if (result != null) {
      widget.onSave?.call(result);
      Navigator.of(context).pop(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prodVm.saveError ?? 'Gagal menyimpan data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildLeftColumn()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEdit ? Colors.orange.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isEdit ? Icons.edit : Icons.add,
            color: isEdit ? Colors.orange.shade700 : Colors.green.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEdit ? 'Edit Bongkar Susun' : 'Tambah Bongkar Susun',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Header',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              BongkarSusunTextField(
                controller: noBsCtrl,
                label: 'No Bongkar Susun',
                icon: Icons.label,
                asText: true,
                readOnly: true,
                placeholderText: 'BG.XXXXXXXXXX',
              ),

              const SizedBox(height: 16),

              AppDateField(
                controller: tanggalCtrl,
                label: 'Tanggal',
                format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
                initialDate: _selectedDate,
                onChanged: (d) {
                  if (d != null) {
                    setState(() {
                      _selectedDate = d;
                      tanggalCtrl.text = DateFormat(
                        'EEEE, dd MMM yyyy',
                        'id_ID',
                      ).format(d);
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: noteCtrl,
                label: 'Catatan',
                icon: Icons.notes,
                hintText: 'Catatan (opsional)',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    // ✅ Watch VM from PARENT Screen context for isSaving state
    final prodVm = context.watch<BongkarSusunViewModel>();
    final isSaving = prodVm.isSaving;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isEdit ? const Color(0xFFF57C00) : const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 14,
            ),
          ),
          child: Text(
            isSaving ? 'MENYIMPAN...' : 'SIMPAN',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}