// lib/features/shared/bj_jual/widgets/bj_jual_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/app_date_field.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../core/utils/date_formatter.dart';

import '../../pembeli/model/pembeli_model.dart';
import '../../pembeli/widgets/pembeli_dropdown.dart';
import '../model/bj_jual_model.dart';
import '../view_model/bj_jual_view_model.dart';

class BJJualFormDialog extends StatefulWidget {
  final BJJual? header;
  final Function(BJJual)? onSave;

  const BJJualFormDialog({
    super.key,
    this.header,
    this.onSave,
  });

  @override
  State<BJJualFormDialog> createState() => _BJJualFormDialogState();
}

class _BJJualFormDialogState extends State<BJJualFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController noCtrl;
  late final TextEditingController tanggalCtrl;
  late final TextEditingController remarkCtrl;

  DateTime _selectedDate = DateTime.now();
  MstPembeli? _selectedPembeli;

  bool get isEdit => widget.header != null;

  @override
  void initState() {
    super.initState();

    noCtrl = TextEditingController(text: widget.header?.noBJJual ?? '');

    final seededDate =
        parseAnyToDateTime(widget.header?.tanggal) ?? DateTime.now();
    _selectedDate = seededDate;

    tanggalCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    remarkCtrl = TextEditingController(text: widget.header?.remark ?? '');
  }

  @override
  void dispose() {
    noCtrl.dispose();
    tanggalCtrl.dispose();
    remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    debugPrint('📝 [BJ_JUAL_FORM] _submit() started');

    if (!_formKey.currentState!.validate()) return;

    final pembeliId = _selectedPembeli?.idPembeli ?? widget.header?.idPembeli;
    if (pembeliId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembeli wajib dipilih')),
      );
      return;
    }

    final vm = context.read<BJJualViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    BJJual? result;

    try {
      if (isEdit) {
        // UPDATE (partial) - kirim string ('' = clear remark)
        result = await vm.updateBJJual(
          noBJJual: widget.header!.noBJJual,
          tanggal: _selectedDate,
          idPembeli: pembeliId,
          remark: remarkCtrl.text.trim(),
        );
      } else {
        // CREATE - remark optional (kalau kosong -> null)
        final r = remarkCtrl.text.trim();
        result = await vm.createBJJual(
          tanggal: _selectedDate,
          idPembeli: pembeliId,
          remark: r.isEmpty ? null : r,
        );
      }
    } catch (e) {
      debugPrint('❌ [BJ_JUAL_FORM] Exception during save: $e');
    } finally {
      if (mounted) Navigator.of(context).pop(); // close loading
    }

    if (!mounted) return;

    if (result != null) {
      widget.onSave?.call(result);

      if (isEdit) {
        Navigator.of(context).pop(result);
      } else {
        Navigator.of(context).pop(true);
      }
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
    // PembeliViewModel sudah global di main.dart,
    // jadi dialog tidak perlu ChangeNotifierProvider pembeli lagi.
    return Consumer<BJJualViewModel>(
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
                      onPressed: saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEdit
                            ? const Color(0xFFF57C00)
                            : const Color(0xFF3F51B5),
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
          isEdit ? 'Edit BJ Jual' : 'Tambah BJ Jual',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

              AppTextField(
                controller: noCtrl,
                label: 'No. BJ Jual',
                icon: Icons.label,
                readOnly: true,
                hintText: 'BJ.XXXXXXXXXX',
              ),
              const SizedBox(height: 16),

              AppDateField(
                controller: tanggalCtrl,
                label: 'Tanggal',
                format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
                initialDate: _selectedDate,
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

              PembeliDropdown(
                preselectId: widget.header?.idPembeli,
                label: 'Pembeli',
                hint: 'Pilih pembeli',
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => v == null ? 'Wajib pilih pembeli' : null,
                onChanged: (p) {
                  _selectedPembeli = p;
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: remarkCtrl,
                label: 'Remark (opsional)',
                icon: Icons.notes_outlined,
                hintText: 'Catatan / keterangan',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
