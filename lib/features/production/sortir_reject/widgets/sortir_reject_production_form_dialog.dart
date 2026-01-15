import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/app_date_field.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../core/utils/date_formatter.dart';

import '../../../warehouse/model/warehouse_model.dart';
import '../../../warehouse/widgets/warehouse_dropdown.dart';

import '../model/sortir_reject_production_model.dart';
import '../view_model/sortir_reject_production_view_model.dart';

class SortirRejectProductionFormDialog extends StatefulWidget {
  final SortirRejectProduction? header;
  final Function(SortirRejectProduction)? onSave;

  const SortirRejectProductionFormDialog({
    super.key,
    this.header,
    this.onSave,
  });

  @override
  State<SortirRejectProductionFormDialog> createState() =>
      _SortirRejectProductionFormDialogState();
}

class _SortirRejectProductionFormDialogState
    extends State<SortirRejectProductionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController noBJSortirCtrl;
  late final TextEditingController dateCtrl;

  DateTime _selectedDate = DateTime.now();

  MstWarehouse? _selectedWarehouse;

  bool get isEdit => widget.header != null;

  bool get isLocked => widget.header?.isLocked == true;

  @override
  void initState() {
    super.initState();

    noBJSortirCtrl =
        TextEditingController(text: widget.header?.noBJSortir ?? '');

    final seededDate = widget.header?.tanggal ?? DateTime.now();
    _selectedDate = seededDate;

    dateCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate.toLocal()),
    );
  }

  @override
  void dispose() {
    noBJSortirCtrl.dispose();
    dateCtrl.dispose();
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

    final warehouseId =
        _selectedWarehouse?.idWarehouse ?? widget.header?.idWarehouse;

    if (warehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warehouse wajib dipilih')),
      );
      return;
    }

    final vm = context.read<SortirRejectProductionViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    SortirRejectProduction? result;

    try {
      if (isEdit) {
        result = await vm.updateSortirReject(
          noBJSortir: widget.header!.noBJSortir,
          tglBJSortir: _selectedDate,
          idWarehouse: warehouseId,
          // idUsername tidak perlu dikirim (default token),
          // kecuali memang kamu mau allow edit username.
        );
      } else {
        result = await vm.createSortirReject(
          tglBJSortir: _selectedDate,
          idWarehouse: warehouseId,
        );
      }
    } catch (e) {
      debugPrint('❌ [SORTIR_REJECT_FORM] Exception during save: $e');
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
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
            color: isLocked
                ? Colors.red.shade100
                : (isEdit ? Colors.orange.shade100 : Colors.green.shade100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isLocked
                ? Icons.lock
                : (isEdit ? Icons.edit : Icons.add),
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
                isEdit ? 'Edit Sortir Reject' : 'Tambah Sortir Reject',
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildBody() {
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
                controller: noBJSortirCtrl,
                label: 'No. BJ Sortir',
                icon: Icons.label,
                readOnly: true,
                hintText: 'J.XXXXXXXXXX',
              ),
              const SizedBox(height: 16),

              AppDateField(
                controller: dateCtrl,
                label: 'Tanggal',
                format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
                initialDate: _selectedDate,
                enabled: !isLocked,
                onChanged: (d) {
                  if (d != null) {
                    setState(() {
                      _selectedDate = d;
                      dateCtrl.text =
                          DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(d);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Warehouse
              WarehouseDropdown(
                preselectId: widget.header?.idWarehouse,
                label: 'Warehouse',
                hint: 'Pilih warehouse',
                enabled: !isLocked,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => v == null ? 'Wajib pilih warehouse' : null,
                onChanged: (w) {
                  _selectedWarehouse = w;
                  setState(() {});
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Username akan diambil otomatis dari token login.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final vm = context.watch<SortirRejectProductionViewModel>();
    final saving = vm.isSaving;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: (saving || isLocked) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEdit ? const Color(0xFFF57C00) : Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: Text(
            saving ? 'MENYIMPAN...' : 'SIMPAN',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
