// lib/features/shared/return_production/widgets/return_production_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/app_date_field.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../core/utils/date_formatter.dart';

import '../../../pembeli/model/pembeli_model.dart';
import '../../../pembeli/widgets/pembeli_dropdown.dart';
import '../model/return_production_model.dart';
import '../view_model/return_production_view_model.dart';

class ReturnProductionFormDialog extends StatefulWidget {
  final ReturnProduction? header;
  final Function(ReturnProduction)? onSave;

  const ReturnProductionFormDialog({
    super.key,
    this.header,
    this.onSave,
  });

  @override
  State<ReturnProductionFormDialog> createState() =>
      _ReturnProductionFormDialogState();
}

class _ReturnProductionFormDialogState extends State<ReturnProductionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController noCtrl;
  late final TextEditingController tanggalCtrl;
  late final TextEditingController invoiceCtrl;
  late final TextEditingController noBJSortirCtrl;

  DateTime _selectedDate = DateTime.now();
  MstPembeli? _selectedPembeli;

  bool get isEdit => widget.header != null;
  bool get isLocked => widget.header?.isLocked == true;

  @override
  void initState() {
    super.initState();

    noCtrl = TextEditingController(text: widget.header?.noRetur ?? '');

    final seededDate =
        parseAnyToDateTime(widget.header?.tanggal) ?? DateTime.now();
    _selectedDate = seededDate;

    tanggalCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    invoiceCtrl = TextEditingController(text: widget.header?.invoice ?? '');

    noBJSortirCtrl = TextEditingController(text: widget.header?.noBJSortir ?? '');
  }

  @override
  void dispose() {
    noCtrl.dispose();
    tanggalCtrl.dispose();
    invoiceCtrl.dispose();
    noBJSortirCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.header?.lockStatusMessage ?? 'Data terkunci'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final pembeliId = _selectedPembeli?.idPembeli ?? widget.header?.idPembeli;
    if (pembeliId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembeli wajib dipilih')),
      );
      return;
    }

    final vm = context.read<ReturnProductionViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    ReturnProduction? result;

    try {
      final inv = invoiceCtrl.text.trim();
      final bj = noBJSortirCtrl.text.trim();

      if (isEdit) {
        result = await vm.updateReturn(
          noRetur: widget.header!.noRetur,
          tanggal: _selectedDate,
          invoice: inv.isEmpty ? null : inv,
          idPembeli: pembeliId,
          noBJSortir: bj.isEmpty ? null : bj,
        );
      } else {
        result = await vm.createReturn(
          tanggal: _selectedDate,
          idPembeli: pembeliId,
          invoice: inv.isEmpty ? null : inv,
          noBJSortir: bj.isEmpty ? null : bj,
        );
      }
    } catch (e) {
      debugPrint('❌ [RETURN_FORM] Exception during save: $e');
    } finally {
      if (mounted) Navigator.of(context).pop(); // close loading
    }

    if (!mounted) return;

    if (result != null) {
      widget.onSave?.call(result);
      Navigator.of(context).pop(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.saveError ?? 'Gagal menyimpan data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReturnProductionViewModel>(
      builder: (_, vm, __) {
        final saving = vm.isSaving;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                Expanded(child: _buildFormBody()),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child:
                      const Text('BATAL', style: TextStyle(fontSize: 15)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: (saving || isLocked) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEdit
                            ? const Color(0xFFF57C00)
                            : Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                      ),
                      child: Text(
                        saving ? 'MENYIMPAN...' : 'SIMPAN',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.red.shade100
                : (isEdit ? Colors.orange.shade100 : Colors.green.shade100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isLocked ? Icons.lock : (isEdit ? Icons.edit : Icons.add),
            color: isLocked
                ? Colors.red.shade700
                : (isEdit ? Colors.orange.shade700 : Colors.green.shade700),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Return' : 'Tambah Return',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (isLocked) ...[
                const SizedBox(height: 4),
                Text(
                  widget.header?.lockInfoText ?? 'Locked',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormBody() {
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
              if (isLocked) ...[
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data terkunci, perubahan tidak diperbolehkan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              AppTextField(
                controller: noCtrl,
                label: 'No. Retur',
                icon: Icons.label,
                readOnly: true,
                hintText: 'RET.XXXXXXXXXX',
              ),
              const SizedBox(height: 16),

              AppDateField(
                controller: tanggalCtrl,
                label: 'Tanggal',
                format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
                initialDate: _selectedDate,
                enabled: !isLocked,
                onChanged: (d) {
                  if (d == null) return;
                  setState(() {
                    _selectedDate = d;
                    tanggalCtrl.text =
                        DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(d);
                  });
                },
              ),
              const SizedBox(height: 16),

              // ✅ SAME FORMAT AS BJ JUAL
              PembeliDropdown(
                preselectId: widget.header?.idPembeli,
                label: 'Pembeli',
                hint: 'Pilih pembeli',
                enabled: !isLocked,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => v == null ? 'Wajib pilih pembeli' : null,
                onChanged: (p) {
                  _selectedPembeli = p;
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: invoiceCtrl,
                label: 'Invoice (opsional)',
                icon: Icons.receipt_long_outlined,
                enabled: !isLocked,
                hintText: 'INV-XXXX / kosongkan jika tidak ada',
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: noBJSortirCtrl,
                label: 'No BJ Sortir (opsional)',
                icon: Icons.rule_folder_outlined,
                enabled: !isLocked,
                hintText: 'J.0000000123 / kosongkan jika tidak ada',
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
