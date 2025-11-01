// lib/view/widgets/broker_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pps_tablet/features/crusher_type/widgets/crusher_type_dropdown.dart';
import 'package:pps_tablet/features/production/crusher/widgets/crusher_production_dropdown.dart';
import 'package:provider/provider.dart';

import '../../../crusher_type/model/crusher_type_model.dart';
import 'crusher_text_field.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../common/widgets/app_date_field.dart';

import '../../../jenis_bonggolan/model/jenis_bonggolan_model.dart';
import 'package:pps_tablet/features/jenis_bonggolan/widgets/jenis_bonggolan_dropdown.dart';

import '../../../production/broker/widgets/broker_production_dropdown.dart';
import 'package:pps_tablet/features/production/inject/widgets/inject_production_dropdown.dart';
import '../../../shared/bongkar_susun/bongkar_susun_dropdown.dart';

import '../model/crusher_header_model.dart';
import '../view_model/crusher_view_model.dart';

class CrusherFormDialog extends StatefulWidget {
  final CrusherHeader? header;
  final Function(CrusherHeader)? onSave;

  const CrusherFormDialog({
    super.key,
    this.header,
    this.onSave,
  });

  @override
  State<CrusherFormDialog> createState() => _CrusherFormDialogState();
}

class _CrusherFormDialogState extends State<CrusherFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noCrusherCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController jenisCtrl;
  late final TextEditingController warehouseCtrl;
  late final TextEditingController noCrusherProduksiCtrl;
  late final TextEditingController noBongkarSusunCtrl;
  late final TextEditingController beratCtrl;

  // State
  CrusherType? _selectedJenis;
  InputMode? _selectedMode;
  DateTime _selectedDate = DateTime.now();

  // Inline error text under process dropdowns
  String? _crusherProductionError;
  String? _bongkarSusunError;

  @override
  void initState() {
    super.initState();
    noCrusherCtrl = TextEditingController(text: widget.header?.noCrusher ?? '');

    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.dateCreate) ?? DateTime.now())
        : DateTime.now();

    _selectedDate = seededDate;
    dateCreatedCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    jenisCtrl = TextEditingController(text: widget.header?.namaCrusher ?? '');
    warehouseCtrl = TextEditingController(text: widget.header?.namaWarehouse ?? '');

    noCrusherProduksiCtrl = TextEditingController(text: widget.header?.crusherNoProduksi ?? '');
    noBongkarSusunCtrl = TextEditingController(text: widget.header?.noBongkarSusun ?? '');

    beratCtrl = TextEditingController(
      text: (widget.header?.berat != null)
          ? widget.header!.berat!.toStringAsFixed(
          widget.header!.berat! % 1 == 0 ? 0 : 3)
          : '',
    );

    // Auto pick mode on edit (priority: broker → inject → bongkar)
    if ((noCrusherProduksiCtrl.text).trim().isNotEmpty) {
      _selectedMode = InputMode.crusherProduction;
    } else if ((noBongkarSusunCtrl.text).trim().isNotEmpty) {
      _selectedMode = InputMode.bongkarSusun;
    } else {
      _selectedMode = null;
    }

    // Clear inline error when user types
    noCrusherProduksiCtrl.addListener(() {
      if (_crusherProductionError != null && mounted) setState(() => _crusherProductionError = null);
    });
    noBongkarSusunCtrl.addListener(() {
      if (_bongkarSusunError != null && mounted) setState(() => _bongkarSusunError = null);
    });
  }

  @override
  void dispose() {
    noCrusherCtrl.dispose();
    dateCreatedCtrl.dispose();
    jenisCtrl.dispose();
    warehouseCtrl.dispose();
    noCrusherProduksiCtrl.dispose();
    noBongkarSusunCtrl.dispose();
    beratCtrl.dispose();
    super.dispose();
  }

  bool get isEdit => widget.header != null;

  void _selectMode(InputMode m) {
    setState(() {
      _selectedMode = m;
      // Keep previous values; just clear error messages for clean UX.
      _crusherProductionError = null;
      _bongkarSusunError = null;
    });
  }

  Future<void> _submit() async {
    // 1) Validate base form fields
    if (!_formKey.currentState!.validate()) return;

    // 2) In CREATE, mode is required; in EDIT it's optional (kept as-is)
    if (!isEdit && _selectedMode == null) {
      await DialogService.instance.showError(
        title: 'PILIH PROSES',
        message: 'Pilih salah satu dari Proses Crusher atau Bongkar Susun',
      );
      return;
    }

    // 3) In CREATE, validate process number for the chosen mode
    if (!isEdit && _selectedMode != null) {
      bool hasProcessError = false;
      switch (_selectedMode!) {
        case InputMode.crusherProduction:
          if (noCrusherProduksiCtrl.text.trim().isEmpty) {
            setState(() => _crusherProductionError = 'Pilih Nomor Proses Crusher');
            hasProcessError = true;
          }
          break;
        case InputMode.bongkarSusun:
          if (noBongkarSusunCtrl.text.trim().isEmpty) {
            setState(() => _bongkarSusunError = 'Pilih Nomor Bongkar Susun');
            hasProcessError = true;
          }
          break;
      }
      if (hasProcessError) return;
    }

    // 4) Build common values
    final vm = context.read<CrusherViewModel>();

    double? beratVal;
    final s = beratCtrl.text.trim().replaceAll(',', '.');
    if (s.isNotEmpty) beratVal = double.tryParse(s);

    try {
      if (isEdit) {
        // ===== UPDATE (PUT) =====
        DialogService.instance.showLoading(
          message: 'Menyimpan ${widget.header!.noCrusher}...',
        );

        await vm.updateFromForm(
          noCrusher: widget.header!.noCrusher,
          dateCreate: _selectedDate,                 // DateTime?
          idCrusher: _selectedJenis?.idCrusher,      // int? (null = keep)
          idWarehouse: widget.header?.idWarehouse,   // hook up real picker later
          berat: beratVal,                           // double?
          // Optional future fields:
          // idStatus: ...,
          // blok: ...,
          // idLokasi: ...,
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();
        await DialogService.instance.showSuccess(
          title: 'Tersimpan',
          message: 'Label ${widget.header!.noCrusher} berhasil diperbarui.',
        );
        if (mounted) Navigator.pop(context);
      } else {
        // ===== CREATE (POST) =====
        DialogService.instance.showLoading(message: 'Membuat label...');

        final res = await vm.createFromForm(
          idCrusher: _selectedJenis?.idCrusher,
          dateCreate: _selectedDate,
          idWarehouse: widget.header?.idWarehouse ?? 5, // TODO: ganti jika punya picker
          berat: beratVal,
          mode: _selectedMode,
          // processed codes:
          noCrusherProduksi: noCrusherProduksiCtrl.text.trim().isEmpty
              ? null
              : noCrusherProduksiCtrl.text.trim(),    // must start with "G."
          noBongkarSusun: noBongkarSusunCtrl.text.trim().isEmpty
              ? null
              : noBongkarSusunCtrl.text.trim(),       // must start with "BG."
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();

        final createdNo = res['data']?['header']?['NoCrusher']?.toString() ?? '-'; // ← PascalCase

        await DialogService.instance.showSuccess(
          title: 'Berhasil',
          message: 'Label Crusher berhasil dibuat.',
          extra: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              const Text('Nomor Crusher:', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(.35)),
                ),
                child: Text(
                  createdNo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
        );

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      DialogService.instance.hideLoading();
      await DialogService.instance.showError(title: 'Error', message: e.toString());
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
          isEdit ? 'Edit Label' : 'Tambah Label Baru',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    final bool isCrusherProductionEnabled = !isEdit && _selectedMode == InputMode.crusherProduction;
    final bool isBongkarEnabled = !isEdit && _selectedMode == InputMode.bongkarSusun;

    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text('Header', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            CrusherTextField(
              controller: noCrusherCtrl,
              label: 'No Crusher',
              icon: Icons.label,
              asText: true, // readonly text
            ),

            const SizedBox(height: 16),

            AppDateField(
              controller: dateCreatedCtrl,
              label: 'Date Created',
              format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
              initialDate: _selectedDate,
              // Date picker is always valid here; you can add extra rules if needed.
              onChanged: (d) {
                if (d != null) {
                  setState(() {
                    _selectedDate = d;
                    dateCreatedCtrl.text = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(d);
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Jenis Crusher (Required)
            CrusherTypeDropdown(
              preselectId: widget.header?.idCrusher,
              hintText: 'Pilih jenis crusher',                     // ← was bonggolan
              validator: (v) => v == null ? 'Wajib pilih jenis crusher' : null, // ← wording
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (ct) {
                _selectedJenis = ct;
                jenisCtrl.text = ct?.namaCrusher ?? '';
              },
            ),

            const SizedBox(height: 16),

            // Berat (Required, numeric > 0)
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: beratCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d{0,3})?$')),
                ],
                decoration: InputDecoration(
                  labelText: 'Berat (kg)',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  suffixText: 'kg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                validator: (val) {
                  final raw = (val ?? '').trim();
                  if (raw.isEmpty) return 'Berat wajib diisi.';
                  final s = raw.replaceAll(',', '.');
                  final d = double.tryParse(s);
                  if (d == null) return 'Format berat tidak valid.';
                  if (d <= 0) return 'Berat harus > 0.';
                  return null;
                },
                onEditingComplete: () {
                  final s = beratCtrl.text.trim().replaceAll(',', '.');
                  beratCtrl.text = s;
                  FocusScope.of(context).unfocus();
                },
              ),
            ),

            const SizedBox(height: 16),

            // ===== CRUSHER =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<InputMode>(
                  value: InputMode.crusherProduction,
                  groupValue: _selectedMode,
                  onChanged: isEdit ? null : (val) => _selectMode(val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isCrusherProductionEnabled,
                    child: Opacity(
                      opacity: isCrusherProductionEnabled ? 1 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CrusherProductionDropdown(
                            // ✅ use Crusher preselect props
                            preselectNoCrusherProduksi: widget.header?.crusherNoProduksi,
                            preselectNamaMesin: widget.header?.crusherNamaMesin,

                            // fetch mode needs a date
                            date: _selectedDate,

                            // optional extra filters if you have them:
                            // idMesinFilter: selectedIdMesin,
                            // shiftFilter: selectedShiftString,

                            enabled: isCrusherProductionEnabled,
                            onChanged: isCrusherProductionEnabled
                                ? (cp) {
                              if (_selectedMode != InputMode.crusherProduction) {
                                _selectMode(InputMode.crusherProduction);
                              }
                              setState(() {
                                // ✅ set controller with the Crusher produksi number
                                noCrusherProduksiCtrl.text = cp?.noCrusherProduksi ?? '';

                                // You can also capture outputs if needed:
                                // final outputs = cp?.outputNoCrusherList ?? [];

                                _crusherProductionError = null;
                              });
                            }
                                : null,
                          ),

                          if (_crusherProductionError != null) ...[
                            const SizedBox(height: 6),
                            Text(_crusherProductionError!, style: errorStyle),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== BONGKAR =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<InputMode>(
                  value: InputMode.bongkarSusun,
                  groupValue: _selectedMode,
                  onChanged: isEdit ? null : (val) => _selectMode(val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isBongkarEnabled,
                    child: Opacity(
                      opacity: isBongkarEnabled ? 1 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BongkarSusunDropdown(
                            preselectNoBongkarSusun: widget.header?.noBongkarSusun,
                            date: _selectedDate,
                            enabled: isBongkarEnabled,
                            onChanged: isBongkarEnabled
                                ? (bs) {
                              if (_selectedMode != InputMode.bongkarSusun) {
                                _selectMode(InputMode.bongkarSusun);
                              }
                              setState(() {
                                noBongkarSusunCtrl.text = bs?.noBongkarSusun ?? '';
                                _bongkarSusunError = null;
                              });
                            }
                                : null,
                          ),
                          if (_bongkarSusunError != null) ...[
                            const SizedBox(height: 6),
                            Text(_bongkarSusunError!, style: errorStyle),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEdit ? const Color(0xFFF57C00) : const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: const Text('SIMPAN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
