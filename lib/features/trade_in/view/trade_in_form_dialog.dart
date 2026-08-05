import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/dialog_service.dart';
import '../../reject_type/widgets/reject_type_dropdown.dart';
import '../view_model/trade_in_form_view_model.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);

/// Dialog tambah 1 penerimaan trade-in baru (header + 1 label reject
/// terkait). Return `true` lewat `Navigator.pop` kalau berhasil disimpan,
/// supaya caller tahu kapan harus refresh list.
class TradeInFormDialog extends StatefulWidget {
  const TradeInFormDialog({super.key});

  @override
  State<TradeInFormDialog> createState() => _TradeInFormDialogState();
}

class _TradeInFormDialogState extends State<TradeInFormDialog> {
  late final TradeInFormViewModel _vm;
  final _supplierCtl = TextEditingController();
  final _jenisCtl = TextEditingController();
  final _beratCtl = TextEditingController();
  DateTime _tanggal = DateTime.now();
  String? _salesPersonCode;
  int? _idReject;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _vm = TradeInFormViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    _supplierCtl.dispose();
    _jenisCtl.dispose();
    _beratCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
    );
    if (picked == null) return;
    setState(() => _tanggal = picked);
  }

  Future<void> _submit() async {
    final supplier = _supplierCtl.text.trim();
    final jenis = _jenisCtl.text.trim();
    final berat = _beratCtl.text.trim();
    if (supplier.isEmpty ||
        _salesPersonCode == null ||
        jenis.isEmpty ||
        _idReject == null ||
        berat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua field terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await _vm.submit(
      supplier: supplier,
      salesPersonCode: _salesPersonCode!,
      jenis: jenis,
      tanggal: _tanggal,
      idReject: _idReject!,
      berat: berat,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.errorMessage != null) {
      await DialogService.instance.showError(
        title: 'Gagal Menyimpan',
        message: result.errorMessage!,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.noPenerimaan} berhasil disimpan'),
        backgroundColor: Colors.green.shade700,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TradeInFormViewModel>.value(
      value: _vm,
      child: Consumer<TradeInFormViewModel>(
        builder: (context, vm, _) {
          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(vm),
                  const Divider(height: 1, color: _kBorder),
                  Flexible(child: _buildBody(vm)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(TradeInFormViewModel vm) {
    final noPenerimaanLabel = vm.previewNoPenerimaan ?? '...';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.assignment_return_outlined,
              color: _kPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Penerimaan Baru',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                Text(
                  noPenerimaanLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TradeInFormViewModel vm) {
    final masterEmpty = vm.salesPersons.isEmpty;
    if (vm.isLoading && masterEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (vm.error != null && masterEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 12),
            Text(vm.error!, style: TextStyle(color: Colors.red.shade700)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Tanggal'),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: _inputDecoration(),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_tanggal),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Sales Person'),
          DropdownButtonFormField<String>(
            initialValue: _salesPersonCode,
            decoration: _inputDecoration(hint: 'Pilih sales person'),
            items: vm.salesPersons
                .map(
                  (sp) => DropdownMenuItem(
                    value: sp.code,
                    child: Text(sp.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _salesPersonCode = v),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Supplier'),
          TextField(
            controller: _supplierCtl,
            decoration: _inputDecoration(hint: 'Nama supplier'),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Keterangan'),
          TextField(
            controller: _jenisCtl,
            decoration: _inputDecoration(hint: 'Mis. plastik, kardus'),
          ),
          const SizedBox(height: 20),
          const Divider(color: _kBorder),
          const SizedBox(height: 8),
          const Text(
            'Reject',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D23),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Jenis Reject'),
                    RejectTypeDropdown(
                      label: '',
                      preselectId: _idReject,
                      onChanged: (rt) =>
                          setState(() => _idReject = rt?.idReject),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Berat (kg)'),
                    TextField(
                      controller: _beratCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(hint: '5,25'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
      ),
    ),
  );

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
      filled: true,
      fillColor: _kSurface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
    );
  }
}
