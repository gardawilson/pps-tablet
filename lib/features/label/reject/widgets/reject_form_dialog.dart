// lib/features/reject/widgets/reject_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dialog_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../common/widgets/app_date_field.dart';

import '../../../production/hot_stamp/widgets/hot_stamp_production_dropdown.dart';
import '../../../production/inject/widgets/inject_production_dropdown.dart';
import '../../../production/key_fitting/widgets/key_fitting_production_dropdown.dart';
import '../../../production/sortir_reject/widgets/sortir_reject_production_dropdown.dart';
import '../../../production/spanner/widgets/spanner_production_dropdown.dart';
import '../../../reject_type/model/reject_type_model.dart';
import '../../../reject_type/widgets/packing_type_dropdown.dart';

import '../model/reject_header_model.dart';
import '../view_model/reject_view_model.dart';
import 'reject_text_field.dart';

class RejectFormDialog extends StatefulWidget {
  final RejectHeader? header;

  const RejectFormDialog({
    super.key,
    this.header,
  });

  @override
  State<RejectFormDialog> createState() => _RejectFormDialogState();
}

class _RejectFormDialogState extends State<RejectFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noRejectCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController beratCtrl;

  // State
  DateTime _selectedDate = DateTime.now();
  RejectInputMode? _selectedMode;
  RejectType? _selectedType;

  // Controllers untuk masing-masing proses (menyimpan kode yang dipilih)
  late final TextEditingController injectCodeCtrl;
  late final TextEditingController hotStampCodeCtrl;
  late final TextEditingController keyFittingCodeCtrl;
  late final TextEditingController spannerCodeCtrl;
  late final TextEditingController sortirCodeCtrl;

  // Inline error untuk masing-masing proses
  String? _injectError;
  String? _hotStampError;
  String? _keyFittingError;
  String? _spannerError;
  String? _sortirError;

  bool get isEdit => widget.header != null;

  @override
  void initState() {
    super.initState();

    noRejectCtrl = TextEditingController(text: widget.header?.noReject ?? '');

    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.dateCreate) ?? DateTime.now())
        : DateTime.now();
    _selectedDate = seededDate;

    dateCreatedCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    beratCtrl = TextEditingController(
      text: (widget.header?.berat != null)
          ? widget.header!.berat!.toStringAsFixed(
        widget.header!.berat! % 1 == 0 ? 0 : 3,
      )
          : '',
    );

    // Initialize controllers untuk semua mode
    injectCodeCtrl = TextEditingController(text: '');
    hotStampCodeCtrl = TextEditingController(text: '');
    keyFittingCodeCtrl = TextEditingController(text: '');
    spannerCodeCtrl = TextEditingController(text: '');
    sortirCodeCtrl = TextEditingController(text: '');

    // Auto pick mode on edit berdasarkan OutputType / OutputCode
    if (isEdit && widget.header != null) {
      final code = (widget.header!.outputCode ?? '').trim();
      final type = (widget.header!.outputType ?? '').trim().toUpperCase();

      if (code.isNotEmpty) {
        if (type == 'INJECT' || code.startsWith('S.')) {
          _selectedMode = RejectInputMode.inject;
          injectCodeCtrl.text = code;
        } else if (type == 'HOT_STAMPING' || code.startsWith('BH.')) {
          _selectedMode = RejectInputMode.hotStamping;
          hotStampCodeCtrl.text = code;
        } else if (type == 'PASANG_KUNCI' || code.startsWith('BI.')) {
          _selectedMode = RejectInputMode.pasangKunci;
          keyFittingCodeCtrl.text = code;
        } else if (type == 'SPANNER' || code.startsWith('BJ.')) {
          _selectedMode = RejectInputMode.spanner;
          spannerCodeCtrl.text = code;
        } else if (type == 'BJ_SORTIR' || code.startsWith('J.')) {
          _selectedMode = RejectInputMode.bjSortir;
          sortirCodeCtrl.text = code;
        }
      }
    }

    // Clear inline error when user types
    injectCodeCtrl.addListener(() {
      if (_injectError != null && mounted) {
        setState(() => _injectError = null);
      }
    });
    hotStampCodeCtrl.addListener(() {
      if (_hotStampError != null && mounted) {
        setState(() => _hotStampError = null);
      }
    });
    keyFittingCodeCtrl.addListener(() {
      if (_keyFittingError != null && mounted) {
        setState(() => _keyFittingError = null);
      }
    });
    spannerCodeCtrl.addListener(() {
      if (_spannerError != null && mounted) {
        setState(() => _spannerError = null);
      }
    });
    sortirCodeCtrl.addListener(() {
      if (_sortirError != null && mounted) {
        setState(() => _sortirError = null);
      }
    });
  }

  @override
  void dispose() {
    noRejectCtrl.dispose();
    dateCreatedCtrl.dispose();
    beratCtrl.dispose();
    injectCodeCtrl.dispose();
    hotStampCodeCtrl.dispose();
    keyFittingCodeCtrl.dispose();
    spannerCodeCtrl.dispose();
    sortirCodeCtrl.dispose();
    super.dispose();
  }

  void _selectMode(RejectInputMode m) {
    setState(() {
      _selectedMode = m;
      // Clear semua error untuk clean UX
      _injectError = null;
      _hotStampError = null;
      _keyFittingError = null;
      _spannerError = null;
      _sortirError = null;
    });
  }

  Future<void> _submit() async {
    // 1) Validate base form fields
    if (!_formKey.currentState!.validate()) return;

    // 2) In CREATE, mode is required; in EDIT it's optional (kept as-is)
    if (!isEdit && _selectedMode == null) {
      await DialogService.instance.showError(
        title: 'PILIH PROSES',
        message: 'Pilih salah satu proses sumber (Inject / Hot Stamping / Pasang Kunci / Spanner / BJ Sortir)',
      );
      return;
    }

    // 3) In CREATE, validate process number for the chosen mode
    if (!isEdit && _selectedMode != null) {
      bool hasProcessError = false;
      switch (_selectedMode!) {
        case RejectInputMode.inject:
          if (injectCodeCtrl.text.trim().isEmpty) {
            setState(() => _injectError = 'Pilih Nomor Inject');
            hasProcessError = true;
          }
          break;
        case RejectInputMode.hotStamping:
          if (hotStampCodeCtrl.text.trim().isEmpty) {
            setState(() => _hotStampError = 'Pilih Nomor Hot Stamping');
            hasProcessError = true;
          }
          break;
        case RejectInputMode.pasangKunci:
          if (keyFittingCodeCtrl.text.trim().isEmpty) {
            setState(() => _keyFittingError = 'Pilih Nomor Pasang Kunci');
            hasProcessError = true;
          }
          break;
        case RejectInputMode.spanner:
          if (spannerCodeCtrl.text.trim().isEmpty) {
            setState(() => _spannerError = 'Pilih Nomor Spanner');
            hasProcessError = true;
          }
          break;
        case RejectInputMode.bjSortir:
          if (sortirCodeCtrl.text.trim().isEmpty) {
            setState(() => _sortirError = 'Pilih Nomor BJ Sortir');
            hasProcessError = true;
          }
          break;
      }
      if (hasProcessError) return;
    }

    // 4) Build common values
    final vm = context.read<RejectViewModel>();

    double? beratVal;
    final s = beratCtrl.text.trim().replaceAll(',', '.');
    if (s.isNotEmpty) beratVal = double.tryParse(s);

    try {
      if (isEdit) {
        // ===== UPDATE (PUT) =====
        DialogService.instance.showLoading(
          message: 'Menyimpan ${widget.header!.noReject}...',
        );

        await vm.updateFromForm(
          noReject: widget.header!.noReject,
          dateCreate: _selectedDate,
          idReject: _selectedType?.idReject,
          berat: beratVal,
          outputCode: null, // mapping tidak diubah di edit
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();
        await DialogService.instance.showSuccess(
          title: 'Tersimpan',
          message: 'Label ${widget.header!.noReject} berhasil diperbarui.',
        );
        if (mounted) Navigator.pop(context);
      } else {
        // ===== CREATE (POST) =====
        DialogService.instance.showLoading(message: 'Membuat label Reject...');

        // Tentukan kode berdasarkan mode
        String? injectCode;
        String? hotStampCode;
        String? pasangKunciCode;
        String? spannerCode;
        String? bjSortirCode;

        switch (_selectedMode!) {
          case RejectInputMode.inject:
            injectCode = injectCodeCtrl.text.trim().isEmpty
                ? null
                : injectCodeCtrl.text.trim();
            break;
          case RejectInputMode.hotStamping:
            hotStampCode = hotStampCodeCtrl.text.trim().isEmpty
                ? null
                : hotStampCodeCtrl.text.trim();
            break;
          case RejectInputMode.pasangKunci:
            pasangKunciCode = keyFittingCodeCtrl.text.trim().isEmpty
                ? null
                : keyFittingCodeCtrl.text.trim();
            break;
          case RejectInputMode.spanner:
            spannerCode = spannerCodeCtrl.text.trim().isEmpty
                ? null
                : spannerCodeCtrl.text.trim();
            break;
          case RejectInputMode.bjSortir:
            bjSortirCode = sortirCodeCtrl.text.trim().isEmpty
                ? null
                : sortirCodeCtrl.text.trim();
            break;
        }

        final res = await vm.createFromForm(
          idReject: _selectedType?.idReject,
          dateCreate: _selectedDate,
          berat: beratVal,
          isPartial: false,
          idWarehouse: null,
          blok: null,
          idLokasi: null,
          jam: null,
          mode: _selectedMode,
          injectCode: injectCode,
          hotStampCode: hotStampCode,
          pasangKunciCode: pasangKunciCode,
          spannerCode: spannerCode,
          bjSortirCode: bjSortirCode,
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();

        // Response shape: data: { headers: [...], output: { count, ... } }
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final List headers = data['headers'] as List? ?? [];
        final output = data['output'] as Map<String, dynamic>? ?? {};
        final int count = (output['count'] as int?) ?? headers.length;

        Widget extraWidget;
        if (headers.isEmpty) {
          extraWidget = const SizedBox.shrink();
        } else if (headers.length == 1) {
          final no = headers.first['NoReject']?.toString() ?? '-';
          extraWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              const Text('Nomor Reject:', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(.35)),
                ),
                child: Text(
                  no,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          );
        } else {
          extraWidget = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                'Nomor Reject (${count} label):',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: headers.map((h) {
                    final no = h['NoReject']?.toString() ?? '-';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $no',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }

        await DialogService.instance.showSuccess(
          title: 'Berhasil',
          message: count > 1
              ? 'Label Reject berhasil dibuat (${count} label).'
              : 'Label Reject berhasil dibuat.',
          extra: extraWidget,
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
          isEdit ? 'Edit Label Reject' : 'Tambah Label Reject',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    final bool isInjectEnabled = !isEdit && _selectedMode == RejectInputMode.inject;
    final bool isHotStampEnabled = !isEdit && _selectedMode == RejectInputMode.hotStamping;
    final bool isKeyFittingEnabled = !isEdit && _selectedMode == RejectInputMode.pasangKunci;
    final bool isSpannerEnabled = !isEdit && _selectedMode == RejectInputMode.spanner;
    final bool isSortirEnabled = !isEdit && _selectedMode == RejectInputMode.bjSortir;

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

            // No Reject (readonly text)
            RejectTextField(
              controller: noRejectCtrl,
              label: 'No. Reject',
              icon: Icons.label_important_outline,
              asText: true,
            ),

            const SizedBox(height: 16),

            // Date Created
            AppDateField(
              controller: dateCreatedCtrl,
              label: 'Date Created',
              format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
              initialDate: _selectedDate,
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

            // Jenis Reject (Required)
            RejectTypeDropdown(
              preselectId: widget.header?.idReject,
              hintText: 'Pilih jenis Reject',
              validator: (v) => v == null ? 'Wajib pilih jenis Reject' : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (rt) {
                _selectedType = rt;
              },
            ),

            const SizedBox(height: 16),

            // Berat (Optional)
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
                  if (raw.isEmpty) return null; // optional
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

            // ===== INJECT (S.*****) =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<RejectInputMode>(
                  value: RejectInputMode.inject,
                  groupValue: _selectedMode,
                  onChanged: isEdit ? null : (val) => _selectMode(val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isInjectEnabled,
                    child: Opacity(
                      opacity: isInjectEnabled ? 1 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InjectProductionDropdown(
                            preselectNoProduksi: widget.header?.outputCode?.startsWith('S.') == true
                                ? widget.header!.outputCode
                                : null,
                            date: _selectedDate,
                            enabled: isInjectEnabled,
                            onChanged: isInjectEnabled
                                ? (ip) {
                              if (_selectedMode != RejectInputMode.inject) {
                                _selectMode(RejectInputMode.inject);
                              }
                              setState(() {
                                injectCodeCtrl.text = ip?.noProduksi ?? '';
                                _injectError = null;
                              });
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

            // ===== HOT STAMPING (BH.*****) =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<RejectInputMode>(
                  value: RejectInputMode.hotStamping,
                  groupValue: _selectedMode,
                  onChanged: isEdit ? null : (val) => _selectMode(val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isHotStampEnabled,
                    child: Opacity(
                      opacity: isHotStampEnabled ? 1 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HotStampProductionDropdown(
                            preselectNoProduksi: widget.header?.outputCode?.startsWith('BH.') == true
                                ? widget.header!.outputCode
                                : null,
                            date: _selectedDate,
                            enabled: isHotStampEnabled,
                            onChanged: isHotStampEnabled
                                ? (hs) {
                              if (_selectedMode != RejectInputMode.hotStamping) {
                                _selectMode(RejectInputMode.hotStamping);
                              }
                              setState(() {
                                hotStampCodeCtrl.text = hs?.noProduksi ?? '';
                                _hotStampError = null;
                              });
                            }
                                : null,
                          ),
                          if (_hotStampError != null) ...[
                            const SizedBox(height: 6),
                            Text(_hotStampError!, style: errorStyle),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== PASANG KUNCI (BI.*****) =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<RejectInputMode>(
                  value: RejectInputMode.pasangKunci,
                  groupValue: _selectedMode,
                  onChanged: isEdit ? null : (val) => _selectMode(val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isKeyFittingEnabled,
                    child: Opacity(
                      opacity: isKeyFittingEnabled ? 1 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KeyFittingProductionDropdown(
                            preselectNoProduksi: widget.header?.outputCode?.startsWith('BI.') == true
                                ? widget.header!.outputCode
                                : null,
                            date: _selectedDate,
                            enabled: isKeyFittingEnabled,
                            onChanged: isKeyFittingEnabled
                                ? (kf) {
                              if (_selectedMode != RejectInputMode.pasangKunci) {
                                _selectMode(RejectInputMode.pasangKunci);
                              }
                              setState(() {
                                keyFittingCodeCtrl.text = kf?.noProduksi ?? '';
                                _keyFittingError = null;
                              });
                            }
                                : null,
                          ),
                          if (_keyFittingError != null) ...[
                            const SizedBox(height: 6),
                            Text(_keyFittingError!, style: errorStyle),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== SPANNER (BJ.*****) =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<RejectInputMode>(
                  value: RejectInputMode.spanner,
                  groupValue: _selectedMode,
                  onChanged: isEdit ? null : (val) => _selectMode(val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isSpannerEnabled,
                    child: Opacity(
                      opacity: isSpannerEnabled ? 1 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SpannerProductionDropdown(
                            preselectNoProduksi: widget.header?.outputCode?.startsWith('BJ.') == true
                                ? widget.header!.outputCode
                                : null,
                            date: _selectedDate,
                            enabled: isSpannerEnabled,
                            onChanged: isSpannerEnabled
                                ? (sp) {
                              if (_selectedMode != RejectInputMode.spanner) {
                                _selectMode(RejectInputMode.spanner);
                              }
                              setState(() {
                                spannerCodeCtrl.text = sp?.noProduksi ?? '';
                                _spannerError = null;
                              });
                            }
                                : null,
                          ),
                          if (_spannerError != null) ...[
                            const SizedBox(height: 6),
                            Text(_spannerError!, style: errorStyle),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== BJ SORTIR (J.*****) =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<RejectInputMode>(
                  value: RejectInputMode.bjSortir,
                  groupValue: _selectedMode,
                  onChanged: isEdit ? null : (val) => _selectMode(val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isSortirEnabled,
                    child: Opacity(
                      opacity: isSortirEnabled ? 1 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SortirRejectProductionDropdown(
                            preselectNoBJSortir: widget.header?.outputCode?.startsWith('J.') == true
                                ? widget.header!.outputCode
                                : null,
                            date: _selectedDate,
                            enabled: isSortirEnabled,
                            onChanged: isSortirEnabled
                                ? (sr) {
                              if (_selectedMode != RejectInputMode.bjSortir) {
                                _selectMode(RejectInputMode.bjSortir);
                              }
                              setState(() {
                                sortirCodeCtrl.text = sr?.noBJSortir ?? '';
                                _sortirError = null;
                              });
                            }
                                : null,
                          ),
                          if (_sortirError != null) ...[
                            const SizedBox(height: 6),
                            Text(_sortirError!, style: errorStyle),
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