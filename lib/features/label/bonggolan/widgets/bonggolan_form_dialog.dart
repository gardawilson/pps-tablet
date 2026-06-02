// lib/view/widgets/mixer_form_dialog.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'bonggolan_text_field.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../common/widgets/app_date_field.dart';

import '../../../jenis_bonggolan/model/jenis_bonggolan_model.dart';
import 'package:pps_tablet/features/jenis_bonggolan/widgets/jenis_bonggolan_dropdown.dart';

import '../../../production/broker/widgets/broker_production_dropdown.dart';
import 'package:pps_tablet/features/production/inject/widgets/inject_production_dropdown.dart';

import '../../../../common/widgets/label_output_panel.dart';
import '../model/bonggolan_header_model.dart';
import '../repository/bonggolan_repository.dart';
import '../view_model/bonggolan_view_model.dart';

class BonggolanFormDialog extends StatefulWidget {
  final BonggolanHeader? header;
  final Function(BonggolanHeader)? onSave;

  /// Jika diisi, broker production & date di-preselect dan dikunci.
  final String? preselectBrokerNoProduksi;
  final String? preselectBrokerNamaMesin;
  final DateTime? preselectDate;

  const BonggolanFormDialog({
    super.key,
    this.header,
    this.onSave,
    this.preselectBrokerNoProduksi,
    this.preselectBrokerNamaMesin,
    this.preselectDate,
  });

  @override
  State<BonggolanFormDialog> createState() => _BonggolanFormDialogState();
}

class _BonggolanFormDialogState extends State<BonggolanFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noBonggolanCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController jenisCtrl;
  late final TextEditingController warehouseCtrl;
  late final TextEditingController noBrokerProduksiCtrl;
  late final TextEditingController noInjectProduksiCtrl;
  late final TextEditingController beratCtrl;

  // State
  JenisBonggolan? _selectedJenis;
  InputMode? _selectedMode;
  DateTime _selectedDate = DateTime.now();

  // Inline error text under process dropdowns
  String? _brokerError;
  String? _injectError;

  // Output panel
  List<BonggolanOutputItem> _bonggolanOutputs = [];
  bool _loadingOutputs = false;

  @override
  void initState() {
    super.initState();
    noBonggolanCtrl = TextEditingController(
      text: widget.header?.noBonggolan ?? '',
    );

    final DateTime seededDate =
        widget.preselectDate ??
        (widget.header != null
            ? (parseAnyToDateTime(widget.header!.dateCreate) ?? DateTime.now())
            : DateTime.now());

    _selectedDate = seededDate;
    dateCreatedCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    jenisCtrl = TextEditingController(text: widget.header?.namaBonggolan ?? '');
    warehouseCtrl = TextEditingController(
      text: widget.header?.namaWarehouse ?? '',
    );

    noBrokerProduksiCtrl = TextEditingController(
      text:
          widget.preselectBrokerNoProduksi ??
          widget.header?.brokerNoProduksi ??
          '',
    );
    noInjectProduksiCtrl = TextEditingController(
      text: widget.header?.injectNoProduksi ?? '',
    );

    beratCtrl = TextEditingController(
      text: (widget.header?.berat != null)
          ? widget.header!.berat!.toStringAsFixed(
              widget.header!.berat! % 1 == 0 ? 0 : 3,
            )
          : '',
    );

    // Auto pick mode: preselect broker → edit priority → null
    if (widget.preselectBrokerNoProduksi != null) {
      _selectedMode = InputMode.brokerProduction;
    } else if ((noBrokerProduksiCtrl.text).trim().isNotEmpty) {
      _selectedMode = InputMode.brokerProduction;
    } else if ((noInjectProduksiCtrl.text).trim().isNotEmpty) {
      _selectedMode = InputMode.injectProduction;
    } else {
      _selectedMode = null;
    }

    // Clear inline error when user types
    noBrokerProduksiCtrl.addListener(() {
      if (_brokerError != null && mounted) setState(() => _brokerError = null);
    });
    noInjectProduksiCtrl.addListener(() {
      if (_injectError != null && mounted) setState(() => _injectError = null);
    });

    // Auto-fetch outputs on edit mode or preselect
    final preCode = noBrokerProduksiCtrl.text.trim().isNotEmpty
        ? noBrokerProduksiCtrl.text.trim()
        : noInjectProduksiCtrl.text.trim();
    if (widget.header != null || preCode.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (preCode.isNotEmpty) _fetchOutputs(preCode);
      });
    }
  }

  @override
  void dispose() {
    noBonggolanCtrl.dispose();
    dateCreatedCtrl.dispose();
    jenisCtrl.dispose();
    warehouseCtrl.dispose();
    noBrokerProduksiCtrl.dispose();
    noInjectProduksiCtrl.dispose();
    beratCtrl.dispose();
    super.dispose();
  }

  bool get isEdit => widget.header != null;

  bool get _isLocked =>
      widget.preselectBrokerNoProduksi != null || widget.preselectDate != null;
  bool get _forceBrokerOnly => widget.preselectBrokerNoProduksi != null;

  Future<void> _fetchOutputs(String code) async {
    if (code.trim().isEmpty) {
      setState(() => _bonggolanOutputs = []);
      return;
    }
    setState(() => _loadingOutputs = true);
    try {
      final repo = BonggolanRepository();
      List<BonggolanOutputItem> outputs;
      if (_selectedMode == InputMode.brokerProduction) {
        outputs = await repo.fetchOutputsByBrokerNoProduksi(code.trim());
      } else {
        outputs = await repo.fetchOutputsByInjectNoProduksi(code.trim());
      }
      if (mounted) setState(() => _bonggolanOutputs = outputs);
    } catch (_) {
      if (mounted) setState(() => _bonggolanOutputs = []);
    } finally {
      if (mounted) setState(() => _loadingOutputs = false);
    }
  }

  void _selectMode(InputMode m) {
    setState(() {
      _selectedMode = m;
      _brokerError = null;
      _injectError = null;
      _bonggolanOutputs = [];
    });
  }

  Future<void> _submit() async {
    // 1) Validate base form fields
    if (!_formKey.currentState!.validate()) return;

    // 2) In CREATE, mode is required; in EDIT it's optional (kept as-is)
    if (!isEdit && _selectedMode == null) {
      final processMessage = _forceBrokerOnly
          ? 'Pilih Proses Broker terlebih dahulu'
          : 'Pilih salah satu dari Proses Broker, Inject, atau Bongkar Susun';
      await DialogService.instance.showError(
        title: 'PILIH PROSES',
        message: processMessage,
      );
      return;
    }

    // 3) In CREATE, validate process number for the chosen mode
    if (!isEdit && _selectedMode != null) {
      bool hasProcessError = false;
      switch (_selectedMode!) {
        case InputMode.brokerProduction:
          if (noBrokerProduksiCtrl.text.trim().isEmpty) {
            setState(() => _brokerError = 'Pilih Nomor Proses Broker');
            hasProcessError = true;
          }
          break;
        case InputMode.injectProduction:
          if (noInjectProduksiCtrl.text.trim().isEmpty) {
            setState(() => _injectError = 'Pilih Nomor Proses Inject');
            hasProcessError = true;
          }
          break;
      }
      if (hasProcessError) return;
    }

    // 4) Build common values
    final vm = context.read<BonggolanViewModel>();

    double? beratVal;
    final s = beratCtrl.text.trim().replaceAll(',', '.');
    if (s.isNotEmpty) beratVal = double.tryParse(s);

    try {
      if (isEdit) {
        // ===== UPDATE (PUT) =====
        DialogService.instance.showLoading(
          message: 'Menyimpan ${widget.header!.noBonggolan}...',
        );

        await vm.updateFromForm(
          noBonggolan: widget.header!.noBonggolan,
          // Send only what user can edit in this form:
          dateCreate: _selectedDate, // DateTime?
          idBonggolan: _selectedJenis?.idBonggolan, // int? (null = keep)
          idWarehouse:
              widget.header?.idWarehouse, // you can wire a real picker later
          berat: beratVal, // double?
          // Optional status/location if you later add fields:
          // idStatus: ...,
          // blok: ...,
          // idLokasi: ...,
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();
        await DialogService.instance.showSuccess(
          title: 'Tersimpan',
          message: 'Label ${widget.header!.noBonggolan} berhasil diperbarui.',
        );
        if (mounted) Navigator.pop(context);
      } else {
        // ===== CREATE (POST) =====
        DialogService.instance.showLoading(message: 'Membuat label...');

        final res = await vm.createFromForm(
          idBonggolan: _selectedJenis?.idBonggolan,
          dateCreate: _selectedDate,
          idWarehouse:
              widget.header?.idWarehouse ?? 5, // TODO: ganti jika punya picker
          berat: beratVal,
          mode: _selectedMode,
          brokerNoProduksi: noBrokerProduksiCtrl.text.trim().isEmpty
              ? null
              : noBrokerProduksiCtrl.text.trim(),
          injectNoProduksi: noInjectProduksiCtrl.text.trim().isEmpty
              ? null
              : noInjectProduksiCtrl.text.trim(),
          noBongkarSusun: null,
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();

        final createdNo =
            res['data']?['header']?['NoBonggolan']?.toString() ?? '-';

        await DialogService.instance.showSuccess(
          title: 'Berhasil',
          message: 'Label Bonggolan berhasil dibuat.',
          extra: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Nomor Bonggolan:',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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

      String backendMsg = e.toString();
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(backendMsg);
      if (jsonMatch != null) {
        try {
          backendMsg =
              (jsonDecode(jsonMatch.group(0)!)['message'] as String?) ??
              backendMsg;
        } catch (_) {}
      }

      final inputMatch = RegExp(
        r'Input=(\d+(?:\.\d+)?)\s*kg',
        caseSensitive: false,
      ).firstMatch(backendMsg);
      final existingMatch = RegExp(
        r'OutputExisting=(\d+(?:\.\d+)?)\s*kg',
        caseSensitive: false,
      ).firstMatch(backendMsg);
      final newMatch = RegExp(
        r'OutputBaru=(\d+(?:\.\d+)?)\s*kg',
        caseSensitive: false,
      ).firstMatch(backendMsg);

      final String errorTitle;
      final String errorMessage;

      if (inputMatch != null && existingMatch != null && newMatch != null) {
        final inputKg = inputMatch.group(1)!;
        final existingKg = existingMatch.group(1)!;
        final newKg = newMatch.group(1)!;
        final remaining =
            (double.tryParse(inputKg) ?? 0) -
            (double.tryParse(existingKg) ?? 0);

        errorTitle = 'Berat Label Melebihi Input';
        errorMessage =
            'Berat label yang ditambahkan ($newKg kg) melebihi sisa kapasitas input yang tersedia.\n\n'
            '• Total berat input    : $inputKg kg\n'
            '• Total output saat ini: $existingKg kg\n'
            '• Sisa kapasitas       : ${remaining.toStringAsFixed(0)} kg\n'
            '• Berat label baru     : $newKg kg\n\n'
            'Kurangi berat label agar tidak melebihi sisa kapasitas.';
      } else {
        errorTitle = 'Gagal Membuat Label';
        errorMessage = backendMsg;
      }

      await DialogService.instance.showError(
        title: errorTitle,
        message: errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
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
                  Expanded(flex: 5, child: _buildLeftColumn()),
                  const SizedBox(width: 24),
                  Container(width: 1, color: Colors.grey.shade300),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildOutputPanel()),
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
    final bool isBrokerProductionEnabled =
        !isEdit && !_isLocked && _selectedMode == InputMode.brokerProduction;
    final bool isInjectProductionEnabled =
        !isEdit && !_isLocked && _selectedMode == InputMode.injectProduction;
    final bool showInjectOption = !_forceBrokerOnly;

    final errorStyle = TextStyle(
      color: Theme.of(context).colorScheme.error,
      fontSize: 12,
    );

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
              IgnorePointer(
                ignoring: _isLocked,
                child: Opacity(
                  opacity: _isLocked ? 0.6 : 1,
                  child: AppDateField(
                    controller: dateCreatedCtrl,
                    label: 'Date Created',
                    format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
                    initialDate: _selectedDate,
                    onChanged: _isLocked
                        ? null
                        : (d) {
                            if (d != null) {
                              setState(() {
                                _selectedDate = d;
                                dateCreatedCtrl.text = DateFormat(
                                  'EEEE, dd MMM yyyy',
                                  'id_ID',
                                ).format(d);
                              });
                            }
                          },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== BROKER =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!_isLocked)
                    Radio<InputMode>(
                      value: InputMode.brokerProduction,
                      groupValue: _selectedMode,
                      onChanged: isEdit ? null : (val) => _selectMode(val!),
                    ),
                  if (!_isLocked) const SizedBox(width: 8),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: !isBrokerProductionEnabled,
                      child: Opacity(
                        opacity: isBrokerProductionEnabled ? 1 : 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BrokerProductionDropdown(
                              preselectNoProduksi:
                                  widget.preselectBrokerNoProduksi ??
                                  widget.header?.brokerNoProduksi,
                              preselectNamaMesin:
                                  widget.preselectBrokerNamaMesin ??
                                  widget.header?.brokerNamaMesin,
                              date: _selectedDate,
                              enabled: isBrokerProductionEnabled,
                              onChanged: isBrokerProductionEnabled
                                  ? (bp) {
                                      if (_selectedMode !=
                                          InputMode.brokerProduction) {
                                        _selectMode(InputMode.brokerProduction);
                                      }
                                      final code = bp?.noProduksi ?? '';
                                      setState(() {
                                        noBrokerProduksiCtrl.text = code;
                                        _brokerError = null;
                                        _bonggolanOutputs = [];
                                      });
                                      if (code.isNotEmpty) _fetchOutputs(code);
                                    }
                                  : null,
                            ),
                            if (_brokerError != null) ...[
                              const SizedBox(height: 6),
                              Text(_brokerError!, style: errorStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (showInjectOption) ...[
                // ===== INJECT =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Radio<InputMode>(
                      value: InputMode.injectProduction,
                      groupValue: _selectedMode,
                      onChanged: isEdit ? null : (val) => _selectMode(val!),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: IgnorePointer(
                        ignoring: !isInjectProductionEnabled,
                        child: Opacity(
                          opacity: isInjectProductionEnabled ? 1 : 0.6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InjectProductionDropdown(
                                preselectNoProduksi:
                                    widget.header?.injectNoProduksi,
                                preselectNamaMesin:
                                    widget.header?.injectNamaMesin,
                                date: _selectedDate,
                                enabled: isInjectProductionEnabled,
                                onChanged: isInjectProductionEnabled
                                    ? (ip) {
                                        if (_selectedMode !=
                                            InputMode.injectProduction) {
                                          _selectMode(
                                            InputMode.injectProduction,
                                          );
                                        }
                                        final code = ip?.noProduksi ?? '';
                                        setState(() {
                                          noInjectProduksiCtrl.text = code;
                                          _injectError = null;
                                          _bonggolanOutputs = [];
                                        });
                                        if (code.isNotEmpty) _fetchOutputs(code);
                                      }
                                    : null,
                              ),
                              if (_injectError != null) ...[
                                const SizedBox(height: 6),
                                Text(_injectError!, style: errorStyle),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Jenis Bonggolan (Required)
              JenisBonggolanDropdown(
                preselectId: widget.header?.idBonggolan,
                hintText: 'Pilih jenis bonggolan',
                validator: (v) =>
                    v == null ? 'Wajib pilih jenis bonggolan' : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (jp) {
                  _selectedJenis = jp;
                  jenisCtrl.text = jp?.namaBonggolan ?? '';
                },
              ),

              const SizedBox(height: 16),

              // Berat (Required, numeric > 0)
              SizedBox(
                width: 300,
                child: TextFormField(
                  controller: beratCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*([.,]\d{0,3})?$'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Berat (kg)',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    suffixText: 'kg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  // ===== RIGHT COLUMN: OUTPUT PANEL =====
  Widget _buildOutputPanel() {
    final String noSourceMessage;
    final String sourceCode;

    switch (_selectedMode) {
      case InputMode.brokerProduction:
        noSourceMessage = 'Pilih No Produksi Broker\nuntuk melihat output';
        sourceCode = noBrokerProduksiCtrl.text.trim();
        break;
      case InputMode.injectProduction:
        noSourceMessage = 'Pilih No Produksi Inject\nuntuk melihat output';
        sourceCode = noInjectProduksiCtrl.text.trim();
        break;
      default:
        noSourceMessage = 'Pilih sumber\nuntuk melihat output';
        sourceCode = '';
    }

    return LabelOutputPanel(
      title: 'Output Bonggolan',
      items: _bonggolanOutputs
          .map(
            (o) => LabelOutputItem(code: o.noBonggolan, isPrinted: o.isPrinted),
          )
          .toList(),
      isLoading: _loadingOutputs,
      hasSource: sourceCode.isNotEmpty,
      noSourceMessage: noSourceMessage,
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
            backgroundColor: isEdit
                ? const Color(0xFFF57C00)
                : const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: const Text(
            'SIMPAN',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
